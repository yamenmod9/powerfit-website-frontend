import '../config/app_config.dart';

class ApiEndpoints {
  // Base URL
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // Auth Endpoints
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String profile = '/api/auth/profile';
  
  // Customer Endpoints
  static const String customers = '/api/customers';
  static String customerById(int id) => '/api/customers/$id';
  static const String registerCustomer = '/api/customers/register'; // POST to create new customer
  static String regenerateQRCode(int customerId) => '/api/customers/$customerId/regenerate-qr';

  // Subscription Endpoints
  static const String subscriptions = '/api/subscriptions';
  static String subscriptionById(int id) => '/api/subscriptions/$id';
  static const String activateSubscription = '/api/subscriptions/activate';
  static const String renewSubscription = '/api/subscriptions/renew';
  static const String stopSubscription = '/api/subscriptions/stop';
  static const String freezeSubscription = '/api/subscriptions/freeze';
  static String deductSession(int subscriptionId) => '/api/subscriptions/$subscriptionId/deduct-session';
  static String useCoins(int subscriptionId) => '/api/subscriptions/$subscriptionId/use-coins';
  
  // Payment Endpoints
  static const String payments = '/api/payments';
  static const String recordPayment = '/api/payments/record';
  static const String dailyClosing = '/api/payments/daily-closing';
  
  // Branch Endpoints
  static const String branches = '/api/branches';
  static String branchById(int id) => '/api/branches/$id';
  static String branchPerformance(int id) => '/api/branches/$id/performance';
  
  // Service Endpoints
  static const String services = '/api/services';
  static String serviceById(int id) => '/api/services/$id';
  
  // Complaint Endpoints
  static const String complaints = '/api/complaints';
  static const String submitComplaint = '/api/complaints/submit';
  
  // Reports Endpoints
  static const String reportsRevenue = '/api/reports/revenue';
  static const String reportsDaily = '/api/reports/daily';
  static const String reportsWeekly = '/api/reports/weekly';
  static const String reportsMonthly = '/api/reports/monthly';
  static const String reportsBranchComparison = '/api/reports/branch-comparison';
  static const String reportsEmployeePerformance = '/api/reports/employee-performance';
  
  // Finance Endpoints
  static const String financeExpenses = '/api/finance/expenses';
  static const String financeCashDifferences = '/api/finance/cash-differences';
  static const String financeDailySales = '/api/finance/daily-sales';
  
  // Attendance Endpoints
  static const String attendance = '/api/attendance';
  static const String attendanceByBranch = '/api/attendance/by-branch';
  
  // Alert Endpoints
  static const String alerts = '/api/alerts';
  static const String smartAlerts = '/api/alerts/smart';

  // Dashboard Endpoints
  static const String dashboardOverview = '/api/dashboards/overview';
  static const String dashboardOwner = '/api/dashboards/owner';
  static const String dashboardAccountant = '/api/dashboards/accountant';
  static const String dashboardBranchManager = '/api/dashboards/branch-manager';
  static String dashboardBranch(int branchId) => '/api/dashboards/branch/$branchId';

  // User / Staff Endpoints
  static const String users = '/api/users';
  static String userById(int id) => '/api/users/$id';

  // Notification Endpoints
  static const String registerDevice = '/api/notifications/register-device';
  static const String unregisterDevice = '/api/notifications/unregister-device';
}
