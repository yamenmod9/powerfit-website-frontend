import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'client/core/api/client_api_service.dart';
import 'client/core/auth/client_auth_provider.dart';
import 'client/core/theme/client_theme.dart';
import 'firebase_options.dart';
import 'client/routes/client_router.dart';
import 'core/providers/gym_branding_provider.dart';
import 'core/services/fcm_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: FirebaseOptionsFor.client);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  await Firebase.initializeApp(options: FirebaseOptionsFor.client);
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  await FcmNotificationService().initialize();
  runApp(const GymClientApp());
}

class GymClientApp extends StatefulWidget {
  const GymClientApp({super.key});

  @override
  State<GymClientApp> createState() => _GymClientAppState();
}

class _GymClientAppState extends State<GymClientApp> {
  late final ClientApiService _apiService;
  late final ClientAuthProvider _authProvider;
  late final GymBrandingProvider _brandingProvider;
  late final ClientRouter _router;

  @override
  void initState() {
    super.initState();
    _apiService = ClientApiService();
    _authProvider = ClientAuthProvider(_apiService);
    _brandingProvider = GymBrandingProvider();
    _authProvider.setBrandingProvider(_brandingProvider);
    _router = ClientRouter(_authProvider);
    
    // Initialize auth state
    _authProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ClientApiService>.value(
          value: _apiService,
        ),
        ChangeNotifierProvider<ClientAuthProvider>.value(
          value: _authProvider,
        ),
        ChangeNotifierProvider<GymBrandingProvider>.value(
          value: _brandingProvider,
        ),
      ],
      child: Consumer2<ClientAuthProvider, GymBrandingProvider>(
        builder: (context, auth, branding, _) {
          final shouldUseGymBranding = auth.isAuthenticated && branding.gymId != null;

            // Login/activation screens use app branding.
            // Once authenticated, switch to the assigned gym branding.
          final theme = shouldUseGymBranding
              ? ClientTheme.buildBrandedTheme(branding.primaryColor, branding.secondaryColor)
              : ClientTheme.darkTheme;
          final title = shouldUseGymBranding
              ? branding.gymName
              : 'عميل النادي';

          return MaterialApp.router(
            title: title,
            debugShowCheckedModeBanner: false,
            theme: theme,
            scaffoldMessengerKey: FcmNotificationService.scaffoldMessengerKey,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router.router,
          );
        },
      ),
    );
  }
}
