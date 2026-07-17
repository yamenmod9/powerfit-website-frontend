import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/gym_branding_provider.dart';
import '../core/utils/role_utils.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/gym_setup_wizard.dart';
import '../features/auth/screens/staff_language_setup_screen.dart';
import '../features/owner/screens/owner_dashboard.dart';
import '../features/regional_manager/screens/regional_manager_dashboard.dart';
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
      final isStaffLanguageSetupRoute = state.matchedLocation == '/staff-language-setup';

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

      // Staff (any non-owner role) with no saved language preference → onboard
      if (authProvider.needsLanguageSetup) {
        if (isStaffLanguageSetupRoute) return null;
        return '/staff-language-setup';
      }

      // Authenticated, on login page, redirect to role dashboard
      if (isLoginRoute) {
        return RoleUtils.dashboardRoute(userRole) == '/login'
            ? '/login'
            : RoleUtils.dashboardRoute(userRole);
      }

      // Check if user has access to requested route
      if (state.matchedLocation.startsWith('/owner') && userRole != AppConstants.roleOwner) {
        return _getDefaultRoute(userRole);
      }
      if (state.matchedLocation.startsWith('/regional-manager') && userRole != AppConstants.roleRegionalManager) {
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
      // Any accountant tier (central, regional, branch) may use the console
      if (state.matchedLocation.startsWith('/accountant') &&
          !RoleUtils.isAccountant(userRole)) {
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
        path: '/staff-language-setup',
        builder: (context, state) => const StaffLanguageSetupScreen(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboard(),
      ),
      GoRoute(
        path: '/regional-manager',
        builder: (context, state) => const RegionalManagerDashboard(),
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

  // Single source of truth shared with web_main and the language-setup screen.
  String _getDefaultRoute(String? role) => RoleUtils.dashboardRoute(role);
}
