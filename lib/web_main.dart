import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';

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
import 'features/owner/providers/owner_dashboard_provider.dart';
import 'features/branch_manager/providers/branch_manager_provider.dart';
import 'features/reception/providers/reception_provider.dart';
import 'features/accountant/providers/accountant_provider.dart';
import 'features/finance/providers/finance_provider.dart';
import 'features/super_admin/providers/super_admin_provider.dart';

import 'features/auth/screens/landing_screen.dart';
import 'features/auth/screens/unified_login_screen.dart';
import 'features/auth/screens/gym_setup_wizard.dart';
import 'features/auth/screens/staff_language_setup_screen.dart';
import 'features/owner/screens/owner_dashboard.dart';
import 'features/branch_manager/screens/branch_manager_dashboard.dart';
import 'features/reception/screens/reception_main_screen.dart';
import 'features/accountant/screens/accountant_dashboard.dart';
import 'features/super_admin/screens/super_admin_dashboard.dart';

import 'client/core/api/client_api_service.dart';
import 'client/core/auth/client_auth_provider.dart';
import 'client/core/theme/client_theme.dart';
import 'client/screens/activation_screen.dart';
import 'client/screens/client_main_screen.dart';
import 'client/screens/qr_screen.dart';
import 'client/screens/subscription_screen.dart';
import 'client/screens/payments_screen.dart';
import 'client/screens/entry_history_screen.dart';
import 'client/screens/change_password_screen.dart';
import 'client/screens/settings_screen.dart';

/// Unified web-only entry point. Serves all 3 roles (client, staff, admin)
/// from a single deployment. Native mobile builds keep using main.dart,
/// client_main.dart and super_admin_main.dart unchanged.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  await Firebase.initializeApp(options: FirebaseOptionsFor.staff);
  await FcmNotificationService().initialize();
  runApp(const WebApp());
}

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  // Shared across staff and client sides — one app-wide language.
  late final LocaleProvider _localeProvider;

  // Staff / Admin stack
  late final ApiService _apiService;
  late final AuthService _authService;
  late final BiometricService _biometricService;
  late final AuthProvider _authProvider;
  late final GymBrandingProvider _brandingProvider;

  // Client stack (kept separate so it never shares a GymBrandingProvider
  // instance with the staff/admin side — a client's assigned gym branding
  // and an owner's own gym branding are different things).
  late final ClientApiService _clientApiService;
  late final ClientAuthProvider _clientAuthProvider;
  late final GymBrandingProvider _clientBranding;

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _localeProvider = LocaleProvider();

    _apiService = ApiService();
    _authService = AuthService(_apiService);
    _biometricService = BiometricService();
    _authProvider = AuthProvider(_authService, _biometricService);
    _authProvider.setApiService(_apiService);
    _brandingProvider = GymBrandingProvider();

    _clientApiService = ClientApiService();
    _clientAuthProvider = ClientAuthProvider(_clientApiService);
    _clientBranding = GymBrandingProvider();
    _clientAuthProvider.setBrandingProvider(_clientBranding);
    _clientAuthProvider.initialize();

    _router = _buildRouter();
  }

  String _staffDefaultRoute(String? role) {
    switch (role) {
      case AppConstants.roleOwner:
        return '/owner';
      case AppConstants.roleBranchManager:
        return '/branch-manager';
      case AppConstants.roleFrontDesk:
      case 'reception':
        return '/reception';
      case AppConstants.roleCentralAccountant:
      case AppConstants.roleBranchAccountant:
      case 'accountant':
        return '/accountant';
      case AppConstants.roleSuperAdmin:
        return '/super-admin';
      default:
        return '/login';
    }
  }

  GoRouter _buildRouter() {
    return GoRouter(
      refreshListenable: Listenable.merge([
        _authProvider,
        _brandingProvider,
        _clientAuthProvider,
      ]),
      initialLocation: '/',
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isRootRoute = loc == '/';
        final isLoginRoute = loc == '/login';

        // Legacy bookmark for the old member-only login page.
        if (loc == '/client/welcome') return '/login';

        // Already logged in as a client and landing on the chooser or the
        // unified login page? Skip straight in.
        if ((isRootRoute || isLoginRoute) &&
            _clientAuthProvider.isAuthenticated &&
            !_authProvider.isAuthenticated) {
          return '/client/home';
        }

        // ───────────── Client section ─────────────
        if (loc.startsWith('/client')) {
          final isAuth = _clientAuthProvider.isAuthenticated;
          final isActivation = loc.startsWith('/client/activation');

          if (!isAuth && !isActivation) {
            return '/login';
          }
          if (isAuth && isActivation) {
            return '/client/home';
          }
          return null;
        }

        // ───────────── Staff / Admin section ─────────────
        final isAuthenticated = _authProvider.isAuthenticated;
        final isLoading = _authProvider.isLoading;
        final userRole = _authProvider.userRole;
        final isSetupRoute = loc == '/gym-setup';
        final isStaffLanguageSetupRoute = loc == '/staff-language-setup';

        if (isLoading) return null;

        if (!isAuthenticated) {
          if (isRootRoute || isLoginRoute) return null;
          return '/login';
        }

        // Owner with incomplete gym setup → force wizard
        if (userRole == AppConstants.roleOwner && !_brandingProvider.isSetupComplete) {
          if (isSetupRoute) return null;
          return '/gym-setup';
        }

        // Staff (any non-owner role) with no saved language preference → onboard
        if (_authProvider.needsLanguageSetup) {
          if (isStaffLanguageSetupRoute) return null;
          return '/staff-language-setup';
        }

        if (isRootRoute || isLoginRoute) {
          return _staffDefaultRoute(userRole);
        }

        if (loc.startsWith('/owner') && userRole != AppConstants.roleOwner) {
          return _staffDefaultRoute(userRole);
        }
        if (loc.startsWith('/branch-manager') && userRole != AppConstants.roleBranchManager) {
          return _staffDefaultRoute(userRole);
        }
        if (loc.startsWith('/reception') &&
            userRole != AppConstants.roleFrontDesk &&
            userRole != 'reception') {
          return _staffDefaultRoute(userRole);
        }
        if (loc.startsWith('/accountant') &&
            userRole != AppConstants.roleCentralAccountant &&
            userRole != AppConstants.roleBranchAccountant &&
            userRole != 'accountant') {
          return _staffDefaultRoute(userRole);
        }
        if (loc.startsWith('/super-admin') && userRole != AppConstants.roleSuperAdmin) {
          return _staffDefaultRoute(userRole);
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          // Named 'welcome' too so `context.goNamed('welcome')` (used by the
          // shared client settings screen on logout) still resolves — it's
          // now the same unified login page rather than a member-only one.
          name: 'welcome',
          builder: (context, state) => UnifiedLoginScreen(
            staffBranding: _brandingProvider,
            clientBranding: _clientBranding,
          ),
        ),
        GoRoute(
          path: '/gym-setup',
          builder: (context, state) => const GymSetupWizard(),
        ),
        GoRoute(
          path: '/staff-language-setup',
          builder: (context, state) => const StaffLanguageSetupScreen(),
        ),
        GoRoute(
          path: '/owner',
          builder: (context, state) => const OwnerDashboard(),
        ),
        GoRoute(
          path: '/branch-manager',
          builder: (context, state) => const BranchManagerDashboard(),
        ),
        GoRoute(
          path: '/reception',
          builder: (context, state) => const ReceptionMainScreen(),
        ),
        GoRoute(
          path: '/accountant',
          builder: (context, state) => const AccountantDashboard(),
        ),
        GoRoute(
          path: '/super-admin',
          builder: (context, state) => const SuperAdminDashboard(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            // ClientApiService and ClientAuthProvider are already provided
            // above (build() method) so the unified /login route can reach
            // them too — only the branding instance needs overriding here,
            // scoped to the client subtree.
            return MultiProvider(
              providers: [
                ChangeNotifierProvider<GymBrandingProvider>.value(value: _clientBranding),
              ],
              child: Consumer2<ClientAuthProvider, GymBrandingProvider>(
                builder: (context, auth, branding, _) {
                  final shouldUseGymBranding = auth.isAuthenticated && branding.gymId != null;
                  final theme = shouldUseGymBranding
                      ? ClientTheme.buildBrandedTheme(branding.primaryColor, branding.secondaryColor)
                      : ClientTheme.darkTheme;
                  return Theme(data: theme, child: child);
                },
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/client/activation',
              name: 'activation',
              builder: (context, state) {
                final identifier = state.uri.queryParameters['identifier'] ?? '';
                return ActivationScreen(identifier: identifier);
              },
            ),
            GoRoute(
              path: '/client/home',
              name: 'home',
              builder: (context, state) => const ClientMainScreen(),
            ),
            GoRoute(
              path: '/client/qr',
              name: 'qr',
              builder: (context, state) => const QrScreen(),
            ),
            GoRoute(
              path: '/client/subscription',
              name: 'subscription',
              builder: (context, state) => const SubscriptionScreen(),
            ),
            GoRoute(
              path: '/client/payments',
              name: 'payments',
              builder: (context, state) => const PaymentsScreen(),
            ),
            GoRoute(
              path: '/client/history',
              name: 'history',
              builder: (context, state) => const EntryHistoryScreen(),
            ),
            GoRoute(
              path: '/client/change-password',
              name: 'change-password',
              builder: (context, state) {
                final isFirstLogin = state.extra as bool? ?? false;
                return ChangePasswordScreen(isFirstLogin: isFirstLogin);
              },
            ),
            GoRoute(
              path: '/client/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        // Client stack — also needed at this level (not just inside the
        // /client ShellRoute) so the unified /login route can reach them.
        Provider<ClientApiService>.value(value: _clientApiService),
        ChangeNotifierProvider<ClientAuthProvider>.value(value: _clientAuthProvider),
        ChangeNotifierProxyProvider<AuthProvider, OwnerDashboardProvider>(
          create: (_) => OwnerDashboardProvider(_apiService),
          update: (_, auth, previous) => previous ?? OwnerDashboardProvider(_apiService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BranchManagerProvider>(
          create: (_) => BranchManagerProvider(_apiService, 1),
          update: (_, auth, previous) {
            final branchId = int.tryParse(auth.branchId ?? '1') ?? 1;
            if (previous != null) {
              previous.updateBranchId(branchId);
              return previous;
            }
            return BranchManagerProvider(_apiService, branchId);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReceptionProvider>(
          create: (_) => ReceptionProvider(_apiService, 1),
          update: (_, auth, previous) {
            final branchId = int.tryParse(auth.branchId ?? '1') ?? 1;
            if (previous != null) {
              previous.updateBranchId(branchId);
              return previous;
            }
            return ReceptionProvider(_apiService, branchId);
          },
        ),
        ChangeNotifierProvider(create: (_) => AccountantProvider(_apiService)),
        ChangeNotifierProvider(create: (_) => FinanceProvider(_apiService)),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider(_apiService)),
        ChangeNotifierProvider<GymBrandingProvider>.value(value: _brandingProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: _localeProvider),
      ],
      child: Consumer3<AuthProvider, GymBrandingProvider, LocaleProvider>(
        builder: (context, authProvider, branding, localeProvider, _) {
          final shouldUseGymBranding = authProvider.isAuthenticated &&
              branding.isSetupComplete &&
              branding.gymId != null;

          final theme = shouldUseGymBranding
              ? AppTheme.getThemeByGymBranding(
                  primaryColor: branding.primaryColor,
                  secondaryColor: branding.secondaryColor,
                )
              : AppTheme.getThemeByRole(authProvider.userRole);

          final title = shouldUseGymBranding ? branding.gymName : AppConstants.appName;

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
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
