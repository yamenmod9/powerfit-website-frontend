import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'biometric_service.dart';
import '../services/fcm_notification_service.dart';
import '../api/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final BiometricService _biometricService;
  ApiService? _apiService;
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _userRole;
  String? _userId;
  String? _username;
  String? _branchId;

  // Biometric state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _canBiometricLogin = false;
  
  AuthProvider(this._authService, this._biometricService) {
    _checkAuthStatus();
  }

  /// Set the API service so we can register FCM tokens.
  /// Also wires the session-expired callback so that a stale JWT
  /// automatically triggers logout → GoRouter redirect to /login.
  void setApiService(ApiService api) {
    _apiService = api;
    api.onSessionExpired = () {
      debugPrint('🔒 AuthProvider: forced logout triggered by expired session');
      _forceLogout();
    };
  }
  
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userRole => _userRole;
  String? get userId => _userId;
  String? get username => _username;
  String? get branchId => _branchId;

  // Biometric getters
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get canBiometricLogin => _canBiometricLogin;
  BiometricService get biometricService => _biometricService;
  
  // Check authentication status
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    _isAuthenticated = await _authService.isAuthenticated();
    
    if (_isAuthenticated) {
      _userRole = await _authService.getUserRole();
      _userId = await _authService.getUserId();
      _username = await _authService.getUsername();
      _branchId = await _authService.getBranchId();
    }

    // Check biometric state
    await _refreshBiometricState();
    
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh cached biometric flags.
  Future<void> _refreshBiometricState() async {
    _isBiometricAvailable = await _biometricService.isBiometricAvailable();
    _isBiometricEnabled = await _biometricService.isBiometricEnabled();
    _canBiometricLogin = await _biometricService.canBiometricLogin();
  }
  
  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await _authService.login(username, password);
    
    if (result['success'] == true) {
      _isAuthenticated = true;
      _userRole = result['role']?.toString();
      _userId = result['user_id']?.toString();
      _username = result['username']?.toString();
      _branchId = result['branch_id']?.toString();

      // Register FCM token with backend
      if (_apiService != null) {
        final appType = _userRole == 'super_admin' ? 'super_admin' : 'staff';
        try {
          await FcmNotificationService().registerTokenWithBackend(
            apiService: _apiService!,
            appType: appType,
          );
        } catch (e) {
          debugPrint('⚠️ FCM token registration failed: $e');
        }
      }

      // If biometric is enabled, update stored credentials
      // so the latest password is always stored.
      if (_isBiometricEnabled) {
        await _biometricService.enableBiometric(
          username: username,
          password: password,
        );
      }

      notifyListeners();
    }
    
    return result;
  }

  // ────────────────── Biometric login flow ──────────────────

  /// Perform biometric authentication and then log in automatically
  /// using stored credentials.
  Future<Map<String, dynamic>> biometricLogin() async {
    // 1. Prompt the user for biometric
    final authenticated = await _biometricService.authenticate(
      reason: 'Authenticate to log in to Gym Management',
    );
    if (!authenticated) {
      return {'success': false, 'message': 'Biometric authentication failed or was cancelled.'};
    }

    // 2. Retrieve stored credentials
    final creds = await _biometricService.getStoredCredentials();
    if (creds == null) {
      return {'success': false, 'message': 'No stored credentials found. Please log in with your password.'};
    }

    // 3. Perform a normal login
    return login(creds['username']!, creds['password']!);
  }

  // ────────────────── Biometric settings ──────────────────

  /// Enable biometric login.  Must pass the current (plaintext) credentials
  /// so they can be securely stored.
  Future<void> enableBiometric({
    required String username,
    required String password,
  }) async {
    await _biometricService.enableBiometric(username: username, password: password);
    await _refreshBiometricState();
    notifyListeners();
  }

  /// Disable biometric login and wipe stored credentials.
  Future<void> disableBiometric() async {
    await _biometricService.disableBiometric();
    await _refreshBiometricState();
    notifyListeners();
  }
  
  // Logout
  Future<void> logout() async {
    // Unregister FCM token
    if (_apiService != null) {
      await FcmNotificationService().unregisterToken(apiService: _apiService!);
    }
    await _authService.logout();
    _isAuthenticated = false;
    _userRole = null;
    _userId = null;
    _username = null;
    _branchId = null;
    // NOTE: We intentionally do NOT clear biometric credentials on logout.
    // That way the user can still use biometric to log back in.
    notifyListeners();
  }

  /// Forced logout called from ApiService when a 401 / stale-JWT 404 is
  /// detected.  Skips FCM unregister (the token is already invalid) and
  /// just clears local state so GoRouter's refreshListenable redirects to
  /// /login.
  Future<void> _forceLogout() async {
    if (!_isAuthenticated) return; // already logged out
    await _authService.logout();
    _isAuthenticated = false;
    _userRole = null;
    _userId = null;
    _username = null;
    _branchId = null;
    notifyListeners();
  }
  
  // Refresh auth status
  Future<void> refresh() async {
    await _checkAuthStatus();
  }
}
