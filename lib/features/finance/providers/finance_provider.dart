import 'package:flutter/material.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_service.dart';

/// Expense categories offered when recording money going out. `value` is what
/// the backend stores; the label is resolved at the call site so it can be
/// localized.
class ExpenseCategories {
  static const maintenance = 'maintenance';
  static const utilities = 'utilities';
  static const salaries = 'salaries';
  static const equipment = 'equipment';
  static const supplies = 'supplies';
  static const rent = 'rent';
  static const marketing = 'marketing';
  static const other = 'other';

  static const all = [
    maintenance,
    utilities,
    salaries,
    equipment,
    supplies,
    rent,
    marketing,
    other,
  ];
}

/// Writes for the money-management page: recording what the gym spends and
/// (for owners/central accountants) clearing what others recorded.
///
/// Reads stay with the role dashboards' own providers — this only owns the
/// mutations, so both the owner and accountant pages share one code path.
class FinanceProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isSubmitting = false;
  String? _error;

  FinanceProvider(this._apiService);

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  /// Records an expense. The backend files every new expense as `pending`
  /// until someone with review rights approves it.
  Future<Map<String, dynamic>> createExpense({
    required String title,
    required double amount,
    required int branchId,
    required DateTime expenseDate,
    String? category,
    String? description,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiEndpoints.expenses,
        data: {
          'title': title,
          'amount': amount,
          'branch_id': branchId,
          'expense_date': expenseDate.toIso8601String().split('T')[0],
          if (category != null) 'category': category,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data is Map ? response.data['data'] : null,
        };
      }
      return {'success': false, 'message': _messageFrom(response.data)};
    } catch (e) {
      final message = _describe(e);
      _error = message;
      return {'success': false, 'message': message};
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Approves or rejects a pending expense. [notes] is required by the backend
  /// when rejecting.
  Future<Map<String, dynamic>> reviewExpense({
    required int expenseId,
    required bool approve,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiEndpoints.reviewExpense(expenseId),
        data: {
          'action': approve ? 'approve' : 'reject',
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': _messageFrom(response.data)};
    } catch (e) {
      final message = _describe(e);
      _error = message;
      return {'success': false, 'message': message};
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _messageFrom(dynamic data) {
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return 'Request failed';
  }

  String _describe(Object error) {
    debugPrint('❌ FinanceProvider: $error');
    return error.toString();
  }
}
