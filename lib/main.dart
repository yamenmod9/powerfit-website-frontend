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
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'core/providers/gym_branding_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/fcm_notification_service.dart';
import 'routes/app_router.dart';
import 'features/owner/providers/owner_dashboard_provider.dart';
import 'features/branch_manager/providers/branch_manager_provider.dart';
import 'features/reception/providers/reception_provider.dart';
import 'features/accountant/providers/accountant_provider.dart';
import 'features/finance/providers/finance_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: FirebaseOptionsFor.staff);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  await Firebase.initializeApp(options: FirebaseOptionsFor.staff);
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  await FcmNotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize core services
    final apiService = ApiService();
    final authService = AuthService(apiService);
    final biometricService = BiometricService();

    return MultiProvider(
      providers: [
        // Core providers - ApiService MUST be first!
        Provider<ApiService>.value(
          value: apiService,
        ),
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider(authService, biometricService);
            auth.setApiService(apiService);
            return auth;
          },
        ),

        // Feature providers
        ChangeNotifierProxyProvider<AuthProvider, OwnerDashboardProvider>(
          create: (_) => OwnerDashboardProvider(apiService),
          update: (_, auth, previous) => previous ?? OwnerDashboardProvider(apiService),
        ),

        ChangeNotifierProxyProvider<AuthProvider, BranchManagerProvider>(
          create: (_) => BranchManagerProvider(
            apiService,
            1, // Default branch ID, updated from auth on login
          ),
          update: (_, auth, previous) {
            final branchId = int.tryParse(auth.branchId ?? '1') ?? 1;
            if (previous != null) {
              previous.updateBranchId(branchId);
              return previous;
            }
            return BranchManagerProvider(apiService, branchId);
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, ReceptionProvider>(
          create: (_) => ReceptionProvider(
            apiService,
            1, // Default branch ID, updated from auth on login
          ),
          update: (_, auth, previous) {
            final branchId = int.tryParse(auth.branchId ?? '1') ?? 1;
            if (previous != null) {
              previous.updateBranchId(branchId);
              return previous;
            }
            return ReceptionProvider(apiService, branchId);
          },
        ),

        ChangeNotifierProvider(
          create: (_) => AccountantProvider(apiService),
        ),

        // Expense entry / review — shared by the owner and accountant money pages
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(apiService),
        ),

        // Gym Branding Provider — drives dynamic theming per gym
        ChangeNotifierProvider(
          create: (_) => GymBrandingProvider(),
        ),

        // App-wide language preference
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
        ),
      ],
      child: Consumer3<AuthProvider, GymBrandingProvider, LocaleProvider>(
        builder: (context, authProvider, branding, localeProvider, _) {
          final router = AppRouter(authProvider, branding);
          final shouldUseGymBranding = authProvider.isAuthenticated &&
              branding.isSetupComplete &&
              branding.gymId != null;

          // If the gym has branding configured, use it; otherwise fallback to role theme
          final theme = shouldUseGymBranding
              ? AppTheme.getThemeByGymBranding(
                  primaryColor: branding.primaryColor,
                  secondaryColor: branding.secondaryColor,
                )
              : AppTheme.getThemeByRole(authProvider.userRole);

          final title = shouldUseGymBranding
              ? branding.gymName
              : AppConstants.appName;

          return MaterialApp.router(
            key: ValueKey(localeProvider.isArabic),
            title: title,
            debugShowCheckedModeBanner: false,
            theme: theme,
            scaffoldMessengerKey: FcmNotificationService.scaffoldMessengerKey,
            locale: localeProvider.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
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
