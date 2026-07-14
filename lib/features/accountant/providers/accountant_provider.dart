import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class AccountantProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  String? _error;

  // Filters
  int? _selectedBranchId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Data
  Map<String, dynamic> _dailySales = {};
  List<dynamic> _transactions = [];
  List<dynamic> _expenses = [];
  Map<String, dynamic>? _cashDifferences;
  Map<String, dynamic>? _weeklyReport;
  Map<String, dynamic>? _monthlyReport;
  Map<String, dynamic>? _revenueReport;
  List<dynamic> _branchComparison = [];
  List<dynamic> _alerts = [];
  double _pendingExpenseTotal = 0;
  double _approvedExpenseTotal = 0;
  String? _branchName;

  AccountantProvider(this._apiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedBranchId => _selectedBranchId;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  Map<String, dynamic> get dailySales => _dailySales;
  List<dynamic> get transactions => _transactions;
  List<dynamic> get expenses => _expenses;
  Map<String, dynamic>? get cashDifferences => _cashDifferences;
  Map<String, dynamic>? get weeklyReport => _weeklyReport;
  Map<String, dynamic>? get monthlyReport => _monthlyReport;
  Map<String, dynamic>? get revenueReport => _revenueReport;
  List<dynamic> get branchComparison => _branchComparison;
  List<dynamic> get alerts => _alerts;
  double get pendingExpenseTotal => _pendingExpenseTotal;
  double get approvedExpenseTotal => _approvedExpenseTotal;
  String? get branchName => _branchName;

  /// Initialize with the accountant's branch from AuthProvider
  void initWithBranch(int? branchId) {
    if (branchId != null && _selectedBranchId == null) {
      _selectedBranchId = branchId;
    }
  }

  void setFilters({
    int? branchId,
    DateTime? start,
    DateTime? end,
  }) {
    _selectedBranchId = branchId;
    if (start != null) _startDate = start;
    if (end != null) _endDate = end;
    notifyListeners();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadAccountantDashboard(),
        _loadTransactions(),
        _loadExpenses(),
        _loadCashDifferences(),
        _loadWeeklyReport(),
        _loadMonthlyReport(),
        _loadRevenueReport(),
        _loadBranchComparison(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Primary: /api/dashboards/accountant
  Future<void> _loadAccountantDashboard() async {
    try {
      debugPrint('💰 Loading accountant dashboard...');
      final params = <String, dynamic>{};
      if (_selectedBranchId != null) params['branch_id'] = _selectedBranchId;

      final response = await _apiService.get(
        ApiEndpoints.dashboardAccountant,
        queryParameters: params.isNotEmpty ? params : null,
      );
      debugPrint('💰 Accountant dashboard status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final d = response.data['data'] ?? response.data;

        final today = d['today'] ?? {};
        final currentMonth = d['current_month'] ?? {};
        final lastMonth = d['last_month'] ?? {};
        final comparison = d['comparison'] ?? {};

        _dailySales = {
          'total_sales': (today['total'] ?? 0).toDouble(),
          'cash_sales': (today['cash'] ?? 0).toDouble(),
          'network_sales': (today['network'] ?? today['card'] ?? 0).toDouble(),
          'transfer_sales': (today['transfer'] ?? today['online'] ?? 0).toDouble(),
          'transaction_count': today['count'] ?? 0,
          'monthly_revenue': (currentMonth['revenue'] ?? 0).toDouble(),
          'monthly_expenses': (currentMonth['expenses'] ?? 0).toDouble(),
          'monthly_net': (currentMonth['net'] ?? 0).toDouble(),
          'pending_expenses': currentMonth['pending_expenses'] ?? 0,
          'last_month_revenue': (lastMonth['revenue'] ?? 0).toDouble(),
          'change_amount': (comparison['change'] ?? 0).toDouble(),
          'change_percentage': (comparison['percentage'] ?? 0).toDouble(),
        };

        // Build alerts from dashboard data
        _alerts = [];
        final pendingExp = currentMonth['pending_expenses'] ?? 0;
        if (pendingExp > 0) {
          _alerts.add({
            'title': 'Pending Expenses',
            'description': '$pendingExp expense(s) awaiting approval',
            'risk_level': pendingExp > 5 ? 'high' : 'medium',
            'icon': 'pending_actions',
          });
        }
        final changePercent = (comparison['percentage'] ?? 0).toDouble();
        if (changePercent < -10) {
          _alerts.add({
            'title': 'Revenue Decline',
            'description': 'Revenue down ${changePercent.toStringAsFixed(1)}% vs last month',
            'risk_level': 'high',
            'icon': 'trending_down',
          });
        }

        debugPrint('✅ Accountant dashboard loaded – today: ${_dailySales['total_sales']}, month: ${_dailySales['monthly_revenue']}');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Accountant dashboard failed: $e');
    }

    // Fallback: /api/finance/daily-sales
    await _loadDailySalesFallback();
  }

  Future<void> _loadDailySalesFallback() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.financeDailySales,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final d = response.data['data'] ?? response.data;
        _dailySales = {
          'total_sales': (d['total_sales'] ?? 0).toDouble(),
          'cash_sales': (d['cash_sales'] ?? 0).toDouble(),
          'network_sales': (d['network_sales'] ?? d['card_sales'] ?? 0).toDouble(),
          'transfer_sales': (d['transfer_sales'] ?? d['online_sales'] ?? 0).toDouble(),
          'transaction_count': d['transaction_count'] ?? 0,
          'monthly_revenue': 0.0,
          'monthly_expenses': 0.0,
          'monthly_net': 0.0,
          'pending_expenses': 0,
          'last_month_revenue': 0.0,
          'change_amount': 0.0,
          'change_percentage': 0.0,
        };
      }
    } catch (e) {
      debugPrint('❌ Daily sales fallback failed: $e');
      _dailySales = {
        'total_sales': 0.0,
        'cash_sales': 0.0,
        'network_sales': 0.0,
        'transfer_sales': 0.0,
        'transaction_count': 0,
        'monthly_revenue': 0.0,
        'monthly_expenses': 0.0,
        'monthly_net': 0.0,
        'pending_expenses': 0,
        'last_month_revenue': 0.0,
        'change_amount': 0.0,
        'change_percentage': 0.0,
      };
    }
  }

  /// Load individual transactions via /api/reports/daily
  Future<void> _loadTransactions() async {
    try {
      debugPrint('📋 Loading transactions...');
      final response = await _apiService.get(
        ApiEndpoints.reportsDaily,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final d = response.data['data'] ?? response.data;
        _transactions = List<dynamic>.from(d['transactions'] ?? []);
        debugPrint('✅ Transactions loaded: ${_transactions.length}');
      }
    } catch (e) {
      debugPrint('❌ Transactions load failed: $e');
      _transactions = [];
    }
  }

  Future<void> _loadExpenses() async {
    try {
      debugPrint('💸 Loading expenses...');
      final response = await _apiService.get(
        ApiEndpoints.financeExpenses,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
          'date_from': _startDate.toIso8601String().split('T')[0],
          'date_to': _endDate.toIso8601String().split('T')[0],
        },
      );
      debugPrint('💸 Expenses status: ${response.statusCode}');
      debugPrint('💸 Expenses raw data keys: ${response.data?.keys?.toList()}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _expenses = response.data;
        } else if (response.data['data'] != null) {
          final d = response.data['data'];
          if (d is Map) {
            _expenses = List<dynamic>.from(d['items'] ?? d['expenses'] ?? []);
            _pendingExpenseTotal = (d['total_pending'] ?? 0).toDouble();
            _approvedExpenseTotal = (d['total_approved'] ?? 0).toDouble();
          } else if (d is List) {
            _expenses = List<dynamic>.from(d);
          }
        } else if (response.data['expenses'] != null) {
          _expenses = List<dynamic>.from(response.data['expenses']);
        } else if (response.data['items'] != null) {
          _expenses = List<dynamic>.from(response.data['items']);
        } else {
          _expenses = [];
        }
        debugPrint('✅ Expenses loaded: ${_expenses.length}');

        // If date-filtered returned empty, try without date filter
        if (_expenses.isEmpty) {
          debugPrint('💸 Retrying expenses without date filter...');
          await _loadExpensesNoDateFilter();
        }
      } else {
        _expenses = [];
      }
    } catch (e) {
      debugPrint('❌ Error loading expenses: $e');
      _expenses = [];
    }
  }

  Future<void> _loadExpensesNoDateFilter() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.financeExpenses,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
          'limit': 50,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final d = response.data['data'] ?? response.data;
        if (d is Map) {
          _expenses = List<dynamic>.from(d['items'] ?? d['expenses'] ?? []);
          _pendingExpenseTotal = (d['total_pending'] ?? 0).toDouble();
          _approvedExpenseTotal = (d['total_approved'] ?? 0).toDouble();
        } else if (d is List) {
          _expenses = List<dynamic>.from(d);
        }
        debugPrint('✅ Expenses (no date filter): ${_expenses.length}');
      }
    } catch (e) {
      debugPrint('❌ Expenses no-date fallback: $e');
    }
  }

  Future<void> _loadCashDifferences() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.financeCashDifferences,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
          'date_from': _startDate.toIso8601String().split('T')[0],
          'date_to': _endDate.toIso8601String().split('T')[0],
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _cashDifferences = response.data['data'] ?? response.data;
      }
    } catch (e) {
      debugPrint('⚠️ Cash differences: $e');
    }
  }

  Future<void> _loadWeeklyReport() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.reportsWeekly,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _weeklyReport = response.data['data'] ?? response.data;
        debugPrint('✅ Weekly report loaded');
      }
    } catch (e) {
      debugPrint('⚠️ Weekly report: $e');
    }
  }

  Future<void> _loadMonthlyReport() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.reportsMonthly,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _monthlyReport = response.data['data'] ?? response.data;
        debugPrint('✅ Monthly report loaded');
      }
    } catch (e) {
      debugPrint('⚠️ Monthly report: $e');
    }
  }

  Future<void> _loadRevenueReport() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.reportsRevenue,
        queryParameters: {
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
          'date_from': _startDate.toIso8601String().split('T')[0],
          'date_to': _endDate.toIso8601String().split('T')[0],
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _revenueReport = response.data['data'] ?? response.data;
        debugPrint('✅ Revenue report loaded');
      }
    } catch (e) {
      debugPrint('⚠️ Revenue report: $e');
    }
  }

  Future<void> _loadBranchComparison() async {
    try {
      debugPrint('🏢 Loading branch comparison for accountant...');
      final params = <String, dynamic>{
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
      };

      try {
        final response = await _apiService.get(
          ApiEndpoints.reportsBranchComparison,
          queryParameters: params,
        );
        if (response.statusCode == 200 && response.data != null) {
          if (response.data is List) {
            _branchComparison = response.data;
          } else if (response.data['data'] != null) {
            final d = response.data['data'];
            _branchComparison = d is List ? d : [];
          }
          if (_branchComparison.isNotEmpty) {
            debugPrint('✅ Branch comparison loaded: ${_branchComparison.length}');
            return;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Branch comparison failed: $e');
      }

      // Fallback: /api/branches
      final branchesResponse = await _apiService.get(ApiEndpoints.branches);
      if (branchesResponse.statusCode == 200 && branchesResponse.data != null) {
        if (branchesResponse.data is List) {
          _branchComparison = branchesResponse.data;
        } else if (branchesResponse.data['data'] != null) {
          final d = branchesResponse.data['data'];
          _branchComparison = d is Map ? List<dynamic>.from(d['items'] ?? []) : List<dynamic>.from(d);
        }
        debugPrint('✅ Branches loaded from /api/branches: ${_branchComparison.length}');
      }
    } catch (e) {
      debugPrint('❌ Error loading branches: $e');
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }
}
