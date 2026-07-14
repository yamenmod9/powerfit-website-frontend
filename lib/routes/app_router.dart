import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/auth/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/gym_branding_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/gym_setup_wizard.dart';
import '../features/owner/screens/owner_dashboard.dart';
import '../features/branch_manager/screens/branch_manager_dashboard.dart';
import '../features/reception/screens/reception_main_screen.dart';
import '../features/accountant/screens/accountant_dashboard.dart';

class AppRouter {
  final AuthProvider authProvider;
  final GymBrandingProvider brandingProvider;

  AppRouter(this.authProvider, this.brandingProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: Listenable.merge([authProvider, brandingProvider]),
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading = authProvider.isLoading;
      final userRole = authProvider.userRole;

      final isLoginRoute = state.matchedLocation == '/login';
      final isSetupRoute = state.matchedLocation == '/gym-setup';

      // Still loading auth state
      if (isLoading) {
        return null;
      }

      // Not authenticated, redirect to login
      if (!isAuthenticated) {
        return isLoginRoute ? null : '/login';
      }

      // Owner with incomplete gym setup → force wizard
      if (userRole == AppConstants.roleOwner && !brandingProvider.isSetupComplete) {
        // Already on the setup page — stay there
        if (isSetupRoute) return null;
        // Redirect to wizard
        return '/gym-setup';
      }

      // Authenticated, on login page, redirect to role dashboard
      if (isLoginRoute) {
        switch (userRole) {
          case AppConstants.roleOwner:
            return '/owner';
          case AppConstants.roleBranchManager:
            return '/branch-manager';
          case AppConstants.roleFrontDesk:  // Backend returns 'front_desk'
            return '/reception';
          case AppConstants.roleCentralAccountant:  // Backend returns 'central_accountant'
          case AppConstants.roleBranchAccountant:   // Backend returns 'branch_accountant'
            return '/accountant';
          // Legacy support (in case old role names are used)
          case 'reception':
            return '/reception';
          case 'accountant':
            return '/accountant';
          default:
            // Unknown role - log out and stay on login
            return '/login';
        }
      }

      // Check if user has access to requested route
      if (state.matchedLocation.startsWith('/owner') && userRole != AppConstants.roleOwner) {
        return _getDefaultRoute(userRole);
      }
      if (state.matchedLocation.startsWith('/branch-manager') && userRole != AppConstants.roleBranchManager) {
        return _getDefaultRoute(userRole);
      }
      // Allow both front_desk and legacy 'reception' to access reception routes
      if (state.matchedLocation.startsWith('/reception') &&
          userRole != AppConstants.roleFrontDesk &&
          userRole != 'reception') {
        return _getDefaultRoute(userRole);
      }
      // Allow both central and branch accountants to access accountant routes
      if (state.matchedLocation.startsWith('/accountant') &&
          userRole != AppConstants.roleCentralAccountant &&
          userRole != AppConstants.roleBranchAccountant &&
          userRole != 'accountant') {
        return _getDefaultRoute(userRole);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/gym-setup',
        builder: (context, state) => const GymSetupWizard(),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(state.error.toString()),
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

  String _getDefaultRoute(String? role) {
    switch (role) {
      case AppConstants.roleOwner:
        return '/owner';
      case AppConstants.roleBranchManager:
        return '/branch-manager';
      case AppConstants.roleFrontDesk:  // Backend: 'front_desk'
      case 'reception':  // Legacy support
        return '/reception';
      case AppConstants.roleCentralAccountant:  // Backend: 'central_accountant'
      case AppConstants.roleBranchAccountant:   // Backend: 'branch_accountant'
      case 'accountant':  // Legacy support
        return '/accountant';
      default:
        return '/login';
    }
  }
}
