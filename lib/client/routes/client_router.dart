import 'package:go_router/go_router.dart';
import '../core/auth/client_auth_provider.dart';
import '../screens/welcome_screen.dart';
import '../screens/activation_screen.dart';
import '../screens/client_main_screen.dart';
import '../screens/qr_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/entry_history_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/language_setup_screen.dart';

class ClientRouter {
  final ClientAuthProvider authProvider;

  ClientRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final currentPath = state.matchedLocation;

      print('🔀 Router Redirect: isAuth=$isAuth, currentPath=$currentPath');

      // If not authenticated, redirect to welcome
      if (!isAuth && currentPath != '/welcome' && !currentPath.startsWith('/activation')) {
        print('➡️ Redirecting to /welcome (not authenticated)');
        return '/welcome';
      }

      // First login with no saved language preference — ask before anything else.
      if (isAuth && authProvider.needsLanguageSetup && currentPath != '/language-setup') {
        print('➡️ Redirecting to /language-setup (no preferred_language set)');
        return '/language-setup';
      }

      // If authenticated and trying to access auth pages, go to home
      if (isAuth &&
          !authProvider.needsLanguageSetup &&
          (currentPath == '/welcome' || currentPath == '/activation')) {
        print('➡️ Redirecting to /home (already authenticated)');
        return '/home';
      }

      print('✅ No redirect needed - staying on $currentPath');
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/activation',
        name: 'activation',
        builder: (context, state) {
          final identifier = state.uri.queryParameters['identifier'] ?? '';
          return ActivationScreen(identifier: identifier);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const ClientMainScreen(),
      ),
      // Keep individual routes for deep linking if needed, though mostly handled by tab nav now
      GoRoute(
        path: '/qr',
        name: 'qr',
        builder: (context, state) => const QrScreen(),
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const EntryHistoryScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) {
          final isFirstLogin = state.extra as bool? ?? false;
          return ChangePasswordScreen(isFirstLogin: isFirstLogin);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/language-setup',
        name: 'language-setup',
        builder: (context, state) => const LanguageSetupScreen(),
      ),
    ],
    initialLocation: '/welcome',
  );
}
