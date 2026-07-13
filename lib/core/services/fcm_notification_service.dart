import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized FCM notification service.
/// Handles permission requests, token management, foreground message display,
/// and user-level notification preferences (enable/disable).
class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._();

  FirebaseMessaging? _messaging;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _fcmTokenKey = 'fcm_device_token';
  static const String _notifEnabledKey = 'notifications_enabled';

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Which app flavour is running: 'staff', 'client', or 'super_admin'.
  String? _appType;

  /// Cached reference to the API service so settings screen can
  /// register/unregister without needing a provider.
  dynamic _apiService;

  /// Local preference — user opted in to notifications.
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _initialized = false;

  bool get _supportsMessaging =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Global ScaffoldMessenger key — set from each app's MaterialApp
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // ─── Initialisation ───

  /// Initialize FCM: request permission, get token, and listen for refresh.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!_supportsMessaging) {
      return;
    }

    if (kIsWeb) {
      return;
    }

    _messaging ??= FirebaseMessaging.instance;

    // Load stored notification preference
    final storedPref = await _storage.read(key: _notifEnabledKey);
    _notificationsEnabled = storedPref != 'false'; // default true

    // Request permission (Android 13+ & iOS)
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    // Get current token
    _currentToken = await _messaging!.getToken();
    if (_currentToken != null) {
      await _storage.write(key: _fcmTokenKey, value: _currentToken);
    }
    debugPrint('FCM Token: $_currentToken');

    // Listen for token refresh
    _messaging!.onTokenRefresh.listen((newToken) async {
      _currentToken = newToken;
      await _storage.write(key: _fcmTokenKey, value: newToken);
      debugPrint('FCM Token refreshed: $newToken');
      // Re-register new token if notifications are enabled
      if (_notificationsEnabled && _apiService != null && _appType != null) {
        registerTokenWithBackend(apiService: _apiService!, appType: _appType!);
      }
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // ─── Backend registration ───

  /// Resolve the correct endpoint path depending on which API service is in
  /// use.  Staff [ApiService] has baseUrl without `/api`; client
  /// [ClientApiService] has baseUrl that already includes `/api`.
  String _resolvePath(String endpoint, {String? appTypeOverride}) {
    final type = appTypeOverride ?? _appType;
    // appType 'client' → ClientApiService whose baseUrl ends with /api
    if (type == 'client') {
      return endpoint; // e.g. '/notifications/register-device'
    }
    // Staff / super_admin → ApiService whose baseUrl is the bare host
    return '/api$endpoint'; // e.g. '/api/notifications/register-device'
  }

  /// Register the FCM token with the backend after login.
  /// [apiService] — the API service to use (staff or client).
  /// [appType] — 'staff', 'client', or 'super_admin'.
  Future<void> registerTokenWithBackend({
    required dynamic apiService,
    required String appType,
  }) async {
    if (kIsWeb || !_supportsMessaging) return;

    // Cache for later (settings toggle, token refresh)
    _apiService = apiService;
    _appType = appType;

    if (!_notificationsEnabled) {
      debugPrint('FCM: Notifications disabled by user — skipping registration');
      return;
    }

    final token = _currentToken ?? await _messaging!.getToken();
    if (token == null) {
      debugPrint('FCM: No token available to register');
      return;
    }

    debugPrint('FCM: Registering token with backend ($appType)...');
    debugPrint('FCM: Token prefix=${token.substring(0, 20)}...');

    try {
      final path = _resolvePath('/notifications/register-device');
      debugPrint('FCM: POST $path');
      final response = await apiService.post(
        path,
        data: {
          'fcm_token': token,
          'app_type': appType,
          'platform': 'android',
        },
      );

      debugPrint('FCM: Registration response: ${response.statusCode} ${response.data}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('FCM: ✅ Token registered with backend ($appType)');
      } else {
        debugPrint('FCM: ❌ Token registration failed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('FCM: ❌ Token registration error: $e');
      debugPrint('FCM: Stack trace: $stackTrace');
    }
  }

  /// Unregister the device token on logout (or when user disables notifications).
  Future<void> unregisterToken({required dynamic apiService}) async {
    if (kIsWeb || !_supportsMessaging) return;

    final token = _currentToken;
    if (token == null) return;

    try {
      final path = _resolvePath('/notifications/unregister-device');
      await apiService.post(
        path,
        data: {'fcm_token': token},
      );
      debugPrint('FCM: Token unregistered from backend');
    } catch (e) {
      debugPrint('FCM: Token unregister error: $e');
    }
  }

  // ─── User preference toggle (settings screen) ───

  /// Enable or disable push notifications from settings.
  /// When disabled: unregisters the token from the backend so no pushes are
  /// sent to this device.  When re-enabled: registers the token again.
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _storage.write(key: _notifEnabledKey, value: enabled.toString());

    if (kIsWeb || !_supportsMessaging) return;

    if (_apiService == null || _appType == null) return;

    if (enabled) {
      // Re-request permission in case user had previously denied
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await registerTokenWithBackend(apiService: _apiService!, appType: _appType!);
    } else {
      await unregisterToken(apiService: _apiService!);
    }
  }

  // ─── Private handlers ───

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');

    if (!_notificationsEnabled) return; // user opted-out

    if (message.notification != null) {
      _showInAppNotification(message);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM opened from notification: ${message.data}');
    // Navigation based on message data can be added here
  }

  /// Show an in-app snackbar / banner for foreground notifications.
  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null)
              Text(notification.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'اغلاق',
          textColor: Colors.white,
          onPressed: () {
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
