import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/models/owner_model.dart';

class SuperAdminProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  String? _error;
  List<OwnerModel> _owners = [];
  Map<String, dynamic>? _stats;

  SuperAdminProvider(this._apiService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OwnerModel> get owners => _owners;
  Map<String, dynamic>? get stats => _stats;

  int get totalOwners => _owners.length;
  int get activeOwners => _owners.where((o) => o.isActive).length;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all owner-role users from the backend
      final response = await _apiService.get('/api/users?role=owner&per_page=100');
      final data = response.data;

      if (data['success'] == true) {
        final items = (data['data']['items'] as List?) ?? [];
        _owners = items.map((o) => OwnerModel.fromJson(o as Map<String, dynamic>)).toList();
      }

      _stats = {
        'total_owners': _owners.length,
        'active_owners': _owners.where((o) => o.isActive).length,
      };

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new gym owner account.
  /// The owner will log in and complete the gym setup wizard themselves.
  Future<Map<String, dynamic>> createOwner({
    required String fullName,
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _apiService.post('/api/users', data: {
        'username': username,
        'full_name': fullName,
        'password': password,
        'email': email ?? '$username@owner.com',
        'role': 'owner',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      final data = response.data;

      if (data['success'] == true) {
        final newOwner = OwnerModel.fromJson(data['data'] as Map<String, dynamic>);
        _owners.insert(0, newOwner);
        notifyListeners();

        return {
          'success': true,
          'message': 'Owner "$fullName" created successfully. They can now log in and set up their gym.',
          'owner': newOwner.toJson(),
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to create owner',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create owner: $e',
      };
    }
  }

  Future<Map<String, dynamic>> toggleOwnerStatus(int ownerId) async {
    try {
      final index = _owners.indexWhere((o) => o.id == ownerId);
      if (index == -1) return {'success': false, 'message': 'Owner not found'};

      final owner = _owners[index];
      final newStatus = !owner.isActive;

      await _apiService.put('/api/users/$ownerId', data: {'is_active': newStatus});

      _owners[index] = OwnerModel(
        id: owner.id,
        username: owner.username,
        fullName: owner.fullName,
        email: owner.email,
        phone: owner.phone,
        isActive: newStatus,
        createdAt: owner.createdAt,
        lastLogin: owner.lastLogin,
      );
      notifyListeners();

      return {
        'success': true,
        'message': newStatus ? 'Owner activated' : 'Owner deactivated',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }
}
