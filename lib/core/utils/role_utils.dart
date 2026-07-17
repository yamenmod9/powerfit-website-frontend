/// Helper utilities for role-based access control.
///
/// Staff hierarchy (highest to lowest):
///   super_admin > owner > regional_manager > branch_manager >
///   central_accountant > branch_accountant > front_desk
class RoleUtils {
  /// Rank of each role — higher outranks lower. Mirrors the backend's
  /// ROLE_RANK so create/edit rules stay consistent across the stack.
  static const Map<String, int> roleRank = {
    'super_admin': 100,
    'owner': 90,
    'regional_manager': 80,
    'branch_manager': 70,
    'central_accountant': 60,
    'regional_accountant': 55,
    'branch_accountant': 50,
    'accountant': 50, // Legacy
    'front_desk': 10,
    'reception': 10, // Legacy
  };

  static int rankOf(String? role) => roleRank[role] ?? 0;

  /// The dashboard route each role lands on after login/onboarding.
  ///
  /// This is the ONLY copy of the role→route switch. The app router, the web
  /// router and the language-setup screen all call it — a role missing here
  /// used to bounce staff back to /login from whichever copy forgot it.
  static String dashboardRoute(String? role) {
    switch (role) {
      case 'super_admin':
        return '/super-admin';
      case 'owner':
        return '/owner';
      case 'regional_manager':
        return '/regional-manager';
      case 'branch_manager':
        return '/branch-manager';
      case 'front_desk':
      case 'reception': // Legacy
        return '/reception';
      case 'central_accountant':
      case 'regional_accountant':
      case 'branch_accountant':
      case 'accountant': // Legacy
        return '/accountant';
      default:
        return '/login';
    }
  }

  /// True if [role] strictly outranks [otherRole].
  static bool outranks(String? role, String? otherRole) =>
      rankOf(role) > rankOf(otherRole);

  /// Check if the role is any type of accountant (central, regional or branch)
  static bool isAccountant(String? role) {
    return role == 'central_accountant' ||
           role == 'regional_accountant' ||
           role == 'branch_accountant' ||
           role == 'accountant';  // Legacy support
  }

  /// Check if the role is front desk/reception
  static bool isFrontDesk(String? role) {
    return role == 'front_desk' ||
           role == 'reception';  // Legacy support
  }

  /// Check if the role is a manager of one or more branches
  static bool isManager(String? role) {
    return role == 'branch_manager' || role == 'regional_manager';
  }

  /// Check if the role requires branch filtering (has a single branch_id)
  static bool hasBranchAccess(String? role) {
    return role == 'branch_manager' ||
           role == 'front_desk' ||
           role == 'branch_accountant' ||
           role == 'reception';  // Legacy support
  }

  /// Check if the role manages a group of branches (managed_branch_ids)
  static bool hasBranchGroupAccess(String? role) {
    return role == 'regional_manager' || role == 'regional_accountant';
  }

  /// Check if the role has system-wide access (no branch filtering)
  static bool hasSystemWideAccess(String? role) {
    return role == 'super_admin' ||
           role == 'owner' ||
           role == 'central_accountant';
  }

  /// Get display name for role
  static String getRoleDisplayName(String? role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'owner':
        return 'Owner';
      case 'regional_manager':
        return 'Regional Manager';
      case 'branch_manager':
        return 'Branch Manager';
      case 'front_desk':
      case 'reception':
        return 'Front Desk';
      case 'central_accountant':
        return 'Central Accountant';
      case 'regional_accountant':
        return 'Regional Accountant';
      case 'branch_accountant':
        return 'Branch Accountant';
      default:
        return role ?? 'Unknown';
    }
  }
}
