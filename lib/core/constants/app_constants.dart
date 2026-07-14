class AppConstants {
  // App Info
  static const String appName = 'Gym Management';
  static const String appVersion = '1.0.0';
  
  // User Roles - MUST MATCH BACKEND API EXACTLY
  static const String roleSuperAdmin = 'super_admin';
  static const String roleOwner = 'owner';
  static const String roleBranchManager = 'branch_manager';
  static const String roleFrontDesk = 'front_desk';  // Changed from 'reception'
  static const String roleCentralAccountant = 'central_accountant';  // Specific for central
  static const String roleBranchAccountant = 'branch_accountant';  // Specific for branch

  // Legacy/Alias for backward compatibility
  @Deprecated('Use roleFrontDesk instead')
  static const String roleReception = 'front_desk';
  @Deprecated('Use roleCentralAccountant or roleBranchAccountant instead')
  static const String roleAccountant = 'central_accountant';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Cache Duration (in minutes)
  static const int cacheDuration = 30;
  
  // Subscription Status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusFrozen = 'frozen';
  static const String statusStopped = 'stopped';
  static const String statusExpired = 'expired';
  
  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';
  static const String paymentTransfer = 'transfer';
  
  // BMI Categories
  static const double bmiUnderweight = 18.5;
  static const double bmiNormal = 24.9;
  static const double bmiOverweight = 29.9;
  static const double bmiObese = 30.0;
}
