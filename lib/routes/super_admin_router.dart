import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/super_admin/screens/super_admin_dashboard.dart';

class SuperAdminRouter {
  final AuthProvider authProvider;

  SuperAdminRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading = authProvider.isLoading;
      final userRole = authProvider.userRole;
      final isLoginRoute = state.matchedLocation == '/login';

      if (isLoading) return null;

      if (!isAuthenticated) {
        return isLoginRoute ? null : '/login';
      }

      // Only allow super_admin role
      if (isLoginRoute) {
        if (userRole == AppConstants.roleSuperAdmin) {
          return '/super-admin';
        }
        // Wrong role — stay on login with implicit error
        return '/login';
      }

      // Route guard: only super_admin can access
      if (state.matchedLocation.startsWith('/super-admin') &&
          userRole != AppConstants.roleSuperAdmin) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboard(),
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
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
}
