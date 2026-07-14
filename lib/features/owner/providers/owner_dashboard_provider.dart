import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class OwnerDashboardProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  bool _isLoading = false;
  String? _error;

  // Filter state
  int? _selectedBranchId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Data
  List<dynamic> _alerts = [];
  Map<String, dynamic>? _revenueData;
  List<dynamic> _branchComparison = [];
  List<dynamic> _employeePerformance = [];
  List<dynamic> _complaints = [];

  OwnerDashboardProvider(this._apiService);

  // Getters
  ApiService get apiService => _apiService;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedBranchId => _selectedBranchId;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  List<dynamic> get alerts => _alerts;
  Map<String, dynamic>? get revenueData => _revenueData;
  List<dynamic> get branchComparison => _branchComparison;
  List<dynamic> get employeePerformance => _employeePerformance;
  List<dynamic> get complaints => _complaints;

  void setSelectedBranch(int? branchId) {
    _selectedBranchId = branchId;
    notifyListeners();
    loadDashboardData();
  }

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadOwnerDashboard(),
        _loadBranchComparison(),
        _loadEmployeePerformance(),
        _loadComplaints(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Primary method: uses /api/dashboards/overview for key metrics and
  /// /api/dashboards/owner for smart alerts.
  Future<void> _loadOwnerDashboard() async {
    try {
      debugPrint('📊 Loading owner dashboard overview...');

      // --- Overview metrics ---
      final overviewResponse = await _apiService.get(ApiEndpoints.dashboardOverview);
      debugPrint('📊 Overview status: ${overviewResponse.statusCode}');

      if (overviewResponse.statusCode == 200 && overviewResponse.data != null) {
        final data = overviewResponse.data['data'] ?? overviewResponse.data;
        _revenueData = {
          'total_revenue': data['total_revenue'] ?? 0.0,
          'active_subscriptions': data['active_subscriptions'] ?? 0,
          'total_customers': data['total_customers'] ?? 0,
          'total_branches': data['total_branches'] ?? 0,
          'total_expenses': data['total_expenses'] ?? 0.0,
          'net_profit': data['net_profit'] ?? 0.0,
        };
        // revenue_by_branch can be used to populate branch comparison if needed
        if (data['revenue_by_branch'] != null && _branchComparison.isEmpty) {
          _branchComparison = List<dynamic>.from(data['revenue_by_branch']);
        }
        debugPrint('✅ Overview loaded – revenue: ${_revenueData!['total_revenue']}, customers: ${_revenueData!['total_customers']}');
      } else {
        await _loadOwnerDashboardFallback();
      }

      // --- Smart alerts from /api/dashboards/owner ---
      try {
        final ownerResp = await _apiService.get(ApiEndpoints.dashboardOwner);
        debugPrint('📢 Owner dashboard status: ${ownerResp.statusCode}');
        if (ownerResp.statusCode == 200 && ownerResp.data != null) {
          final d = ownerResp.data['data'] ?? ownerResp.data;
          final alerts = d['alerts'];
          if (alerts is Map) {
            // Convert map of alert types to a flat list for the UI
            _alerts = alerts.entries.map<Map<String, dynamic>>((e) {
              return <String, dynamic>{
                'title': _alertTitle(e.key),
                'description': '${e.value} item(s)',
                'risk_level': (e.value is int && e.value > 5) ? 'high' : 'medium',
                'count': e.value,
              };
            }).where((a) => (a['count'] as int? ?? 0) > 0).toList();
          }
          // Also enrich revenue data from owner dashboard if not already set
          if (_revenueData == null && d['revenue'] != null) {
            final rev = d['revenue'];
            _revenueData = {
              'total_revenue': rev['total_30_days'] ?? 0.0,
              'active_subscriptions': rev['active_subscriptions'] ?? 0,
              'total_customers': rev['total_customers'] ?? 0,
            };
          }
          debugPrint('✅ Alerts loaded: ${_alerts.length}');
        }
      } catch (e) {
        debugPrint('⚠️ Owner dashboard alerts failed: $e');
        await _loadSmartAlertsFallback();
      }
    } catch (e) {
      debugPrint('❌ Error loading owner dashboard: $e');
      await _loadOwnerDashboardFallback();
    }
  }

  String _alertTitle(String key) {
    switch (key) {
      case 'expiring_subscriptions': return 'Expiring Subscriptions';
      case 'expiring_soon': return 'Expiring Soon (3 days)';
      case 'open_complaints': return 'Open Complaints';
      case 'pending_expenses': return 'Pending Expenses';
      default: return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Fallback: use /api/dashboards/owner directly for combined data
  Future<void> _loadOwnerDashboardFallback() async {
    try {
      debugPrint('📊 Fallback: loading from /api/dashboards/owner...');
      final resp = await _apiService.get(ApiEndpoints.dashboardOwner);
      if (resp.statusCode == 200 && resp.data != null) {
        final d = resp.data['data'] ?? resp.data;
        if (d['revenue'] != null) {
          final rev = d['revenue'];
          _revenueData = {
            'total_revenue': rev['total_30_days'] ?? 0.0,
            'active_subscriptions': rev['active_subscriptions'] ?? 0,
            'total_customers': rev['total_customers'] ?? 0,
            'total_expenses': 0.0,
            'net_profit': 0.0,
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Fallback also failed: $e');
      _revenueData ??= {
        'total_revenue': 0.0,
        'active_subscriptions': 0,
        'total_customers': 0,
        'total_expenses': 0.0,
        'net_profit': 0.0,
      };
    }
  }

  Future<void> _loadSmartAlertsFallback() async {
    try {
      final response = await _apiService.get(ApiEndpoints.smartAlerts);
      if (response.statusCode == 200 && response.data != null) {
        final d = response.data['data'] ?? response.data;
        // smartAlerts returns flat counts: expiring_today, expiring_week, low_coins, etc.
        _alerts = [];
        final fields = {
          'expiring_today': 'Expiring Today',
          'expiring_week': 'Expiring This Week',
          'low_coins': 'Low Coins Members',
          'open_complaints': 'Open Complaints',
          'pending_expenses': 'Pending Expenses',
        };
        fields.forEach((key, title) {
          final count = d[key] ?? 0;
          if (count > 0) {
            _alerts.add({
              'title': title,
              'description': '$count item(s) need attention',
              'risk_level': count > 5 ? 'high' : 'medium',
              'count': count,
            });
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Smart alerts fallback failed: $e');
    }
  }

  Future<void> _loadBranchComparison() async {
    try {
      debugPrint('🏢 Loading branch comparison...');

      final params = <String, dynamic>{
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
      };

      // Primary: /api/reports/branch-comparison
      try {
        final response = await _apiService.get(
          ApiEndpoints.reportsBranchComparison,
          queryParameters: params,
        );
        debugPrint('🏢 Branch Comparison status: ${response.statusCode}');
        if (response.statusCode == 200 && response.data != null) {
          if (response.data is List) {
            _branchComparison = response.data;
          } else if (response.data['data'] != null) {
            _branchComparison = response.data['data'];
          }
          if (_branchComparison.isNotEmpty) {
            debugPrint('✅ Branches loaded from comparison: ${_branchComparison.length}');
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
          _branchComparison = d is Map ? (d['items'] ?? []) : d;
        }
        debugPrint('✅ Branches loaded from /api/branches: ${_branchComparison.length}');
      }
    } catch (e) {
      debugPrint('❌ Error loading branches: $e');
    }
  }

  Future<void> _loadEmployeePerformance() async {
    try {
      debugPrint('👥 Loading employee performance...');
      final monthStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}';
      final params = <String, dynamic>{
        'month': monthStr,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
      };
      if (_selectedBranchId != null) params['branch_id'] = _selectedBranchId;

      final response = await _apiService.get(
        ApiEndpoints.reportsEmployeePerformance,
        queryParameters: params,
      );
      debugPrint('👥 Employee Performance status: ${response.statusCode}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _employeePerformance = List<dynamic>.from(response.data);
        } else if (response.data['data'] != null) {
          final d = response.data['data'];
          if (d is List) {
            _employeePerformance = d;
          } else if (d is Map) {
            _employeePerformance = List<dynamic>.from(d['items'] ?? d['employees'] ?? []);
          } else {
            _employeePerformance = [];
          }
        } else if (response.data['employees'] != null) {
          _employeePerformance = List<dynamic>.from(response.data['employees']);
        }
        debugPrint('✅ Employees loaded: ${_employeePerformance.length}');
        return;
      }

      // Fallback: /api/users/employees (returns flat list with branch_name)
      final usersResp = await _apiService.get('/api/users/employees', queryParameters: params);
      if (usersResp.statusCode == 200 && usersResp.data != null) {
        List<dynamic> users = [];
        if (usersResp.data is List) {
          users = usersResp.data;
        } else if (usersResp.data is Map) {
          final d = usersResp.data['data'];
          if (d is List) {
            users = d;
          } else if (d is Map) {
            users = List<dynamic>.from(d['items'] ?? []);
          } else {
            final raw = usersResp.data['users'] ?? usersResp.data['items'];
            if (raw is List) users = raw;
          }
        }
        _employeePerformance = users.where((u) {
          final role = u['role']?.toString().toLowerCase() ?? '';
          return ['manager', 'reception', 'accountant', 'receptionist', 'branch_manager', 'front_desk', 'central_accountant', 'branch_accountant'].contains(role);
        }).toList();
        debugPrint('✅ Staff loaded from /api/users: ${_employeePerformance.length}');
      }
    } catch (e) {
      debugPrint('❌ Error loading employees: $e');
    }
  }

  Future<void> _loadComplaints() async {
    try {
      debugPrint('📝 Loading complaints...');
      final params = <String, dynamic>{
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
      };
      if (_selectedBranchId != null) params['branch_id'] = _selectedBranchId;

      final response = await _apiService.get(ApiEndpoints.complaints, queryParameters: params);
      debugPrint('📝 Complaints status: ${response.statusCode}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _complaints = response.data;
        } else if (response.data['data'] != null) {
          final d = response.data['data'];
          _complaints = d is Map ? (d['items'] ?? []) : d;
        } else if (response.data['complaints'] != null) {
          _complaints = response.data['complaints'];
        }
        debugPrint('✅ Complaints loaded: ${_complaints.length}');
      }
    } catch (e) {
      debugPrint('❌ Error loading complaints: $e');
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }
}
