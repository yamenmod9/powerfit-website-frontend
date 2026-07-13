import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'core/api/api_service.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/biometric_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'core/providers/gym_branding_provider.dart';
import 'core/services/fcm_notification_service.dart';
import 'routes/super_admin_router.dart';
import 'features/super_admin/providers/super_admin_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: FirebaseOptionsFor.superAdmin);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  await Firebase.initializeApp(options: FirebaseOptionsFor.superAdmin);
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  await FcmNotificationService().initialize();
  runApp(const SuperAdminApp());
}

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final authService = AuthService(apiService);
    final biometricService = BiometricService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider(authService, biometricService);
            auth.setApiService(apiService);
            return auth;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => SuperAdminProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => GymBrandingProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = SuperAdminRouter(authProvider);
          return MaterialApp.router(
            title: 'مدير منصة النادي',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.superAdminTheme,
            scaffoldMessengerKey: FcmNotificationService.scaffoldMessengerKey,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router.router,
          );
        },
      ),
    );
  }
}
