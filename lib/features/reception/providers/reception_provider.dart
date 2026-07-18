import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/customer_model.dart';
import '../../../shared/models/service_model.dart';
import '../../../core/utils/helpers.dart';

class ReceptionProvider extends ChangeNotifier {
  final ApiService _apiService;
  int branchId;

  bool _isLoading = false;
  String? _error;

  List<ServiceModel> _services = [];
  List<CustomerModel> _recentCustomers = [];
  int _activeSubscriptionsCount = 0;
  int _complaintsCount = 0;

  ReceptionProvider(this._apiService, this.branchId);

  // Update branch ID when auth state changes (e.g. after login)
  void updateBranchId(int newBranchId) {
    if (branchId != newBranchId) {
      branchId = newBranchId;
      notifyListeners();
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ServiceModel> get services => _services;
  List<CustomerModel> get recentCustomers => _recentCustomers;
  int get activeSubscriptionsCount => _activeSubscriptionsCount;
  int get complaintsCount => _complaintsCount;

  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadServices(),
        _loadRecentCustomers(),
        _loadActiveSubscriptions(),
        _loadComplaintsCount(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadServices() async {
    try {
      final response = await _apiService.get(ApiEndpoints.services);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['services'] ?? response.data['data'] ?? [];
        _services = (data as List).map((json) => ServiceModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _loadRecentCustomers() async {
    try {
      debugPrint('📋 Loading recent customers for branch $branchId...');
      final response = await _apiService.get(
        ApiEndpoints.customers,
        queryParameters: {
          'branch_id': branchId,
          'limit': 10,
        },
      );
      debugPrint('📋 Customers API Response Status: ${response.statusCode}');
      debugPrint('📋 Customers API Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Backend returns: {data: {items: [...]}} or {customers: [...]} or {data: [...]}
        List<dynamic> data = [];

        if (response.data['customers'] != null && response.data['customers'] is List) {
          data = response.data['customers'] as List<dynamic>;
          debugPrint('📋 Using customers field (found ${data.length} items)');
        } else if (response.data['data'] != null) {
          // Check if it's paginated format {data: {items: [...]}}
          final dataField = response.data['data'];

          if (dataField is Map<String, dynamic>) {
            // It's a map, check for items or customers fields
            if (dataField['items'] != null && dataField['items'] is List) {
              data = dataField['items'] as List<dynamic>;
              debugPrint('📋 Using data.items field (found ${data.length} items)');
            } else if (dataField['customers'] != null && dataField['customers'] is List) {
              data = dataField['customers'] as List<dynamic>;
              debugPrint('📋 Using data.customers field (found ${data.length} items)');
            } else {
              // Maybe the map itself has customer data fields
              debugPrint('⚠️ data is a Map but has no items/customers field');
              debugPrint('⚠️ data keys: ${dataField.keys.toList()}');
            }
          } else if (dataField is List) {
            // data field is directly a list
            data = dataField;
            debugPrint('📋 Using data field as list (found ${data.length} items)');
          } else {
            debugPrint('⚠️ data field is neither Map nor List, type: ${dataField.runtimeType}');
          }
        }

        if (data.isNotEmpty) {
          debugPrint('📋 Processing ${data.length} customers');
          _recentCustomers = data.map((json) => CustomerModel.fromJson(json as Map<String, dynamic>)).toList();
          debugPrint('✅ Recent customers loaded successfully. Count: ${_recentCustomers.length}');
        } else {
          debugPrint('⚠️ No customers found in response');
          _recentCustomers = [];
        }
      } else {
        debugPrint('⚠️ Unexpected response format or status code');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading recent customers: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _recentCustomers = []; // Set to empty list on error
    }
  }

  Future<void> _loadActiveSubscriptions() async {
    try {
      debugPrint('📊 Loading active subscriptions count for branch $branchId...');
      final response = await _apiService.get(
        ApiEndpoints.subscriptions,
        queryParameters: {
          'branch_id': branchId,
          'status': 'active',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Handle different response formats
        int count = 0;

        if (response.data['data'] != null) {
          final data = response.data['data'];

          if (data is Map && data['items'] != null && data['items'] is List) {
            count = (data['items'] as List).length;
          } else if (data is List) {
            count = data.length;
          } else if (data is Map && data['total'] != null) {
            count = data['total'] as int;
          }
        } else if (response.data['subscriptions'] != null && response.data['subscriptions'] is List) {
          count = (response.data['subscriptions'] as List).length;
        } else if (response.data['total'] != null) {
          count = response.data['total'] as int;
        }

        _activeSubscriptionsCount = count;
        debugPrint('✅ Active subscriptions count loaded: $count');
      }
    } catch (e) {
      debugPrint('❌ Error loading active subscriptions: $e');
      _activeSubscriptionsCount = 0;
    }
  }

  Future<void> _loadComplaintsCount() async {
    try {
      debugPrint('📝 Loading complaints count for branch $branchId...');
      final response = await _apiService.get(
        ApiEndpoints.complaints,
        queryParameters: {
          'branch_id': branchId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        int count = 0;
        if (response.data['data'] != null) {
          final data = response.data['data'];
          if (data is Map && data['items'] != null && data['items'] is List) {
            count = (data['items'] as List).length;
          } else if (data is List) {
            count = data.length;
          } else if (data is Map && data['total'] != null) {
            count = data['total'] as int;
          }
        } else if (response.data['complaints'] != null && response.data['complaints'] is List) {
          count = (response.data['complaints'] as List).length;
        }
        _complaintsCount = count;
        debugPrint('✅ Complaints count loaded: $count');
      }
    } catch (e) {
      debugPrint('❌ Error loading complaints count: $e');
      _complaintsCount = 0;
    }
  }

  /// Reads a query as a customer ID, or null if it can't be one.
  ///
  /// Phone numbers parse as integers too, so they'd otherwise fire an ID
  /// lookup that always 404s. IDs are row keys: never zero-led, never long.
  static int? _asCustomerId(String query) {
    if (query.startsWith('0') || query.length > 7) return null;
    final id = int.tryParse(query);
    return (id == null || id <= 0) ? null : id;
  }

  /// Look customers up by anything the front desk is likely to have on hand:
  /// name, phone, email, national ID or QR code (all matched server-side), plus
  /// the customer ID — which `/search` does not cover, so a numeric query also
  /// hits the by-ID endpoint and that exact match is surfaced first.
  Future<List<CustomerModel>> searchCustomers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final byId = <CustomerModel>[];
    final matches = <CustomerModel>[];

    final futures = <Future<void>>[
      () async {
        try {
          final response = await _apiService.get(
            ApiEndpoints.customerSearch,
            queryParameters: {'q': q, 'branch_id': branchId, 'limit': 10},
          );
          if (response.statusCode == 200 && response.data != null) {
            final data = response.data['data'] ?? response.data;
            final items = data is Map
                ? (data['items'] ?? data['customers'] ?? [])
                : (data is List ? data : []);
            for (final item in items as List) {
              matches.add(CustomerModel.fromJson(Map<String, dynamic>.from(item as Map)));
            }
          }
        } catch (e) {
          debugPrint('⚠️ Customer search failed for "$q": $e');
        }
      }(),
      () async {
        final id = _asCustomerId(q);
        if (id == null) return;
        try {
          final response = await _apiService.get(ApiEndpoints.customerById(id));
          if (response.statusCode == 200 && response.data != null) {
            final data = response.data['data'] ?? response.data;
            if (data is Map) {
              byId.add(CustomerModel.fromJson(Map<String, dynamic>.from(data)));
            }
          }
        } catch (e) {
          // A miss here is normal — the query just isn't a customer ID.
          debugPrint('ℹ️ No customer with id $q');
        }
      }(),
    ];

    await Future.wait(futures);

    final seen = <int>{};
    final results = <CustomerModel>[];
    for (final customer in [...byId, ...matches]) {
      if (customer.id == null || seen.add(customer.id!)) results.add(customer);
    }
    return results;
  }

  /// Subscriptions belonging to one customer, newest first.
  ///
  /// The renew/freeze/stop flows need the member's actual subscription rather
  /// than a subscription ID typed from memory, so the dialogs pick a customer
  /// and then choose from this list.
  Future<List<Map<String, dynamic>>> fetchCustomerSubscriptions(int customerId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.subscriptions,
        queryParameters: {'customer_id': customerId, 'per_page': 100},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        List<dynamic> raw = [];
        if (data is Map) {
          raw = List<dynamic>.from(data['items'] ?? data['subscriptions'] ?? []);
        } else if (data is List) {
          raw = data;
        }
        final subs = raw
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList();
        subs.sort((a, b) =>
            (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
        return subs;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch subscriptions for customer $customerId: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> registerCustomer(CustomerModel customer) async {
    try {
      // Prepare data with branch_id
      final customerData = customer.toJson();
      customerData['branch_id'] = branchId;

      // Remove null values and qr_code (backend will generate it)
      customerData.removeWhere((key, value) => value == null || key == 'qr_code' || key == 'id');

      debugPrint('=== API REQUEST ===');
      debugPrint('Endpoint: ${ApiEndpoints.registerCustomer}');
      debugPrint('Data: $customerData');

      final response = await _apiService.post(
        ApiEndpoints.registerCustomer,
        data: customerData,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('==================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload recent customers to show the new one
        debugPrint('📝 Reloading recent customers after registration...');
        await _loadRecentCustomers();
        debugPrint('✅ Recent customers reloaded. Count: ${_recentCustomers.length}');
        notifyListeners(); // Notify UI to update

        // Extract customer data from response
        final responseData = response.data;
        final customerInfo = responseData is Map ?
          (responseData['customer'] ?? responseData['data'] ?? responseData) :
          responseData;

        return {
          'success': true,
          'message': responseData?['message'] ?? 'Customer registered successfully',
          'data': customerInfo,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? response.data?['error'] ?? 'Failed to register customer',
        'error': response.data?.toString(),
      };
    } on DioException catch (e) {
      debugPrint('=== DIO EXCEPTION ===');
      debugPrint('Type: ${e.type}');
      debugPrint('Message: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('====================');

      String errorMessage = 'Failed to register customer';
      String? errorDetails;

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map) {
          errorMessage = responseData['message']?.toString() ??
                        responseData['error']?.toString() ??
                        responseData['detail']?.toString() ??
                        'Server error: ${e.response?.statusCode}';
        } else {
          errorMessage = 'Server error: ${e.response?.statusCode}';
        }
        errorDetails = responseData?.toString();
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server. Please check your network.';
      } else {
        errorMessage = 'Network error. Please check your connection.';
        errorDetails = e.message;
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': errorDetails,
      };
    } catch (e, stackTrace) {
      debugPrint('=== UNEXPECTED ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('=======================');

      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> activateSubscription({
    required int customerId,
    required int serviceId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? subscriptionDetails,
  }) async {
    try {
      // ⭐ FIRST: Fetch customer details to get their branch_id
      debugPrint('=== FETCHING CUSTOMER DETAILS ===');
      debugPrint('Customer ID: $customerId');

      final customerResponse = await _apiService.get(
        '${ApiEndpoints.customers}/$customerId',
      );

      if (customerResponse.statusCode != 200) {
        debugPrint('Failed to fetch customer details');
        return {
          'success': false,
          'message': 'Customer not found',
        };
      }

      final customerData = customerResponse.data['data'] ?? customerResponse.data;
      final customerBranchId = customerData['branch_id'];

      debugPrint('Customer branch_id: $customerBranchId');
      debugPrint('Staff branch_id: $branchId');

      // ⭐ Use customer's branch_id instead of staff's branch_id
      Map<String, dynamic> requestData = {
        'customer_id': customerId,
        'service_id': serviceId,
        'branch_id': customerBranchId, // ⭐ FIXED: Use customer's branch
        'amount': amount,
        'payment_method': paymentMethod,
      };

      // Add subscription details if provided
      if (subscriptionDetails != null) {
        requestData.addAll(subscriptionDetails.cast<String, Object>());
      }

      debugPrint('=== ACTIVATING SUBSCRIPTION ===');
      debugPrint('Endpoint: ${ApiEndpoints.activateSubscription}');
      debugPrint('Request Data: ${requestData.toString()}');

      final response = await _apiService.post(
        ApiEndpoints.activateSubscription,
        data: requestData,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Subscription activated successfully',
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to activate subscription',
      };
    } on DioException catch (e) {
      debugPrint('=== DIO EXCEPTION ===');
      debugPrint('Type: ${e.type}');
      debugPrint('Message: ${e.message}');
      debugPrint('Response Status: ${e.response?.statusCode}');
      debugPrint('Response Data: ${e.response?.data}');
      debugPrint('=======================');

      String errorMessage;
      Map<String, dynamic>? errorDetails;

      if (e.type == DioExceptionType.connectionError) {
        errorMessage = '⚠️ CORS/Connection Error\n\n'
            'Running on web browser? This is a CORS issue!\n\n'
            '✅ SOLUTION: Run on Android:\n'
            '1. Double-click DEBUG_SUBSCRIPTION_ACTIVATION.bat\n'
            '2. Select option 1 (Your Android Device)\n'
            'OR select option 2 (Emulator)\n\n'
            '❌ Web browsers block cross-origin requests\n'
            '✅ Android apps have no CORS restrictions';
        errorDetails = {
          'type': 'CORS',
          'platform': 'Web Browser',
          'solution': 'Use Android device or emulator',
          'backend_url': ApiEndpoints.baseUrl,
        };
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout (30s).\n\n'
            'Backend server is not responding.\n'
            'Check if backend is running at:\n${ApiEndpoints.baseUrl}';
        errorDetails = {'type': 'timeout', 'duration': '30s'};
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Send timeout. Failed to send data to server.';
        errorDetails = {'type': 'send_timeout'};
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Receive timeout. Server response took too long.';
        errorDetails = {'type': 'receive_timeout'};
      } else if (e.response != null) {
        // Server responded with error
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 400) {
          errorMessage = 'Invalid request data:\n${responseData?['message'] ?? 'Bad request'}';
          errorDetails = {'type': 'validation', 'data': responseData};
        } else if (statusCode == 401) {
          errorMessage = 'Authentication required. Please login again.';
          errorDetails = {'type': 'auth', 'action': 'relogin'};
        } else if (statusCode == 403) {
          errorMessage = 'Permission denied. You do not have access to this feature.';
          errorDetails = {'type': 'permission'};
        } else if (statusCode == 404) {
          errorMessage = 'Endpoint not found. Backend may not be properly configured.\n'
              'Check: ${ApiEndpoints.activateSubscription}';
          errorDetails = {'type': 'not_found', 'endpoint': ApiEndpoints.activateSubscription};
        } else if (statusCode == 422) {
          errorMessage = 'Validation error:\n${responseData?['message'] ?? 'Invalid data provided'}';
          errorDetails = {'type': 'validation', 'data': responseData};
        } else if (statusCode == 500) {
          errorMessage = 'Backend server error (500).\n'
              'Check backend logs for details.\n'
              'Error: ${responseData?['message'] ?? 'Internal server error'}';
          errorDetails = {'type': 'server_error', 'data': responseData};
        } else {
          errorMessage = responseData?['message']?.toString() ??
              'Server error: HTTP $statusCode';
          errorDetails = {'type': 'http_error', 'status': statusCode, 'data': responseData};
        }
      } else {
        errorMessage = e.message ?? 'Network error occurred';
        errorDetails = {'type': 'unknown', 'message': e.message};
      }

      return {
        'success': false,
        'message': errorMessage,
        'error_details': errorDetails,
      };
    } catch (e, stackTrace) {
      debugPrint('=== UNEXPECTED ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('=======================');

      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> renewSubscription({
    required int subscriptionId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.renewSubscription,
        data: {
          'subscription_id': subscriptionId,
          'amount': amount,
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Subscription renewed successfully',
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to renew subscription',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> freezeSubscription({
    required int subscriptionId,
    required int freezeDays,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.freezeSubscription,
        data: {
          'subscription_id': subscriptionId,
          'freeze_days': freezeDays,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Subscription frozen successfully',
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to freeze subscription',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> stopSubscription(int subscriptionId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.stopSubscription,
        data: {'subscription_id': subscriptionId},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Subscription stopped successfully',
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to stop subscription',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> recordPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    int? subscriptionId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.recordPayment,
        data: {
          'customer_id': customerId,
          'amount': amount,
          'payment_method': paymentMethod,
          'branch_id': branchId,
          if (subscriptionId != null) 'subscription_id': subscriptionId,
          if (notes != null) 'notes': notes,
          'payment_date': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Payment recorded successfully',
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to record payment',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> dailyClosing() async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.dailyClosing,
        data: {
          'branch_id': branchId,
          'closing_date': DateTime.now().toIso8601String().split('T')[0],
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Daily closing completed successfully',
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to complete daily closing',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> submitComplaint({
    required String title,
    required String description,
    int? customerId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.submitComplaint,
        data: {
          'title': title,
          'description': description,
          'branch_id': branchId,
          if (customerId != null) 'customer_id': customerId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Complaint submitted successfully',
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to submit complaint',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  CustomerModel calculateHealthMetrics({
    required String fullName,
    required double weight,
    required double height,
    required int age,
    required String gender,
    String? phone,
    String? email,
    String? qrCode,
  }) {
    final bmi = HealthHelper.calculateBMI(weight, height);
    final bmiCategory = HealthHelper.getBMICategory(bmi);
    final bmr = HealthHelper.calculateBMR(weight, height, age, gender);
    final dailyCalories = HealthHelper.calculateDailyCalories(bmr, 'moderate');

    return CustomerModel(
      fullName: fullName,
      phone: phone,
      email: email,
      gender: gender,
      age: age,
      weight: weight,
      height: height,
      bmi: bmi,
      bmiCategory: bmiCategory,
      bmr: bmr,
      dailyCalories: dailyCalories,
      qrCode: qrCode,
      branchId: branchId,
    );
  }

  Future<void> refresh() async {
    await loadInitialData();
  }

  // Fetch all customers for a branch with credentials.
  //
  // Defaults to the signed-in user's branch, but takes an explicit [forBranchId]
  // so the owner and regional manager can view any branch's members through the
  // same rich list the front desk uses.
  Future<List<Map<String, dynamic>>> getAllCustomersWithCredentials({int? forBranchId}) async {
    final targetBranchId = forBranchId ?? branchId;
    try {
      debugPrint('📋 Fetching ALL customers for branch $targetBranchId...');

      // 1. Fetch customers
      final response = await _apiService.get(
        ApiEndpoints.customers,
        queryParameters: {
          'branch_id': targetBranchId,
          'per_page': 1000,
          'limit': 1000, // Keep backward compatibility with older backends
        },
      );

      debugPrint('📋 All Customers API Response Status: ${response.statusCode}');
      debugPrint('📋 All Customers API Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Backend returns: {data: {items: [...]}} or {customers: [...]} or {data: [...]}
        List<dynamic> data = [];

        if (response.data['customers'] != null && response.data['customers'] is List) {
          data = response.data['customers'] as List<dynamic>;
          debugPrint('📋 Using customers field (found ${data.length} items)');
        } else if (response.data['data'] != null) {
          // Check if it's paginated format {data: {items: [...]}}
          final dataField = response.data['data'];

          if (dataField is Map<String, dynamic>) {
            // It's a map, check for items or customers fields
            if (dataField['items'] != null && dataField['items'] is List) {
              data = dataField['items'] as List<dynamic>;
              debugPrint('📋 Using data.items field (found ${data.length} items)');
            } else if (dataField['customers'] != null && dataField['customers'] is List) {
              data = dataField['customers'] as List<dynamic>;
              debugPrint('📋 Using data.customers field (found ${data.length} items)');
            } else {
              debugPrint('⚠️ data is a Map but has no items/customers field');
              debugPrint('⚠️ data keys: ${dataField.keys.toList()}');
            }
          } else if (dataField is List) {
            // data field is directly a list
            data = dataField;
            debugPrint('📋 Using data field as list (found ${data.length} items)');
          } else {
            debugPrint('⚠️ data field is neither Map nor List, type: ${dataField.runtimeType}');
          }
        }


        // 2. Fetch active subscriptions to map status locally (Frontend Fix)
        Set<int> subscribedCustomerIds = {};
        try {
          final subResponse = await _apiService.get(
            ApiEndpoints.subscriptions,
            queryParameters: {
              'branch_id': targetBranchId,
              'status': 'ACTIVE',
              'per_page': 1000,
              'limit': 1000, // Keep backward compatibility with older backends
            },
          );

          if (subResponse.statusCode == 200 && subResponse.data != null) {
            List<dynamic> subs = [];
            final subData = subResponse.data;

            if (subData['data'] is Map<String, dynamic> && subData['data']['items'] is List) {
              subs = subData['data']['items'] as List<dynamic>;
            } else if (subData['data'] is List) {
              subs = subData['data'] as List<dynamic>;
            } else if (subData['items'] is List) {
              subs = subData['items'] as List<dynamic>;
            } else if (subData['subscriptions'] is List) {
              subs = subData['subscriptions'] as List<dynamic>;
            }

            for (var sub in subs) {
              if (sub is! Map) continue;
              final subMap = Map<String, dynamic>.from(sub);
              final customerIdRaw = subMap['customer_id'] ??
                  subMap['customerId'] ??
                  subMap['customer']?['id'];
              final status = (subMap['status'] ?? '').toString().toLowerCase();
              final isActiveStatus =
                  status.isEmpty || status == 'active' || status == 'valid' || status == 'running';

              final customerId = customerIdRaw is int
                  ? customerIdRaw
                  : int.tryParse(customerIdRaw?.toString() ?? '');

              if (isActiveStatus && customerId != null) {
                subscribedCustomerIds.add(customerId);
              }
            }
            debugPrint('✅ Found ${subscribedCustomerIds.length} active subscriptions to map');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to fetch subscriptions for mapping: $e');
        }

        // 3. Merge subscription status
        final List<Map<String, dynamic>> processedList = [];
        for (var item in data) {
          final Map<String, dynamic> customerMap = Map<String, dynamic>.from(item as Map);

          bool hasActiveSubscription = false;

          final rawActiveFlag = customerMap['has_active_subscription'];
          if (rawActiveFlag is bool) {
            hasActiveSubscription = rawActiveFlag;
          } else if (rawActiveFlag is num) {
            hasActiveSubscription = rawActiveFlag > 0;
          } else if (rawActiveFlag != null) {
            final normalized = rawActiveFlag.toString().toLowerCase();
            hasActiveSubscription = normalized == 'true' || normalized == '1' || normalized == 'yes';
          }

          final subscriptionStatus = (customerMap['subscription_status'] ?? '').toString().toLowerCase();
          if (!hasActiveSubscription && (subscriptionStatus == 'active' || subscriptionStatus == 'subscribed')) {
            hasActiveSubscription = true;
          }

          final activeSubscriptionsCountRaw = customerMap['active_subscriptions_count'] ??
              customerMap['activeSubscriptionsCount'] ??
              customerMap['subscriptions_count'];
          if (!hasActiveSubscription && activeSubscriptionsCountRaw != null) {
            final activeSubscriptionsCount = activeSubscriptionsCountRaw is num
                ? activeSubscriptionsCountRaw.toInt()
                : int.tryParse(activeSubscriptionsCountRaw.toString()) ?? 0;
            if (activeSubscriptionsCount > 0) {
              hasActiveSubscription = true;
            }
          }

          if (!hasActiveSubscription && customerMap['active_subscription'] is Map) {
            hasActiveSubscription = true;
          }

          final customerIdRaw = customerMap['id'] ??
              customerMap['customer_id'] ??
              customerMap['customerId'];
          final customerId = customerIdRaw is int
              ? customerIdRaw
              : int.tryParse(customerIdRaw?.toString() ?? '');
          if (!hasActiveSubscription && customerId != null) {
            hasActiveSubscription = subscribedCustomerIds.contains(customerId);
          }

          customerMap['has_active_subscription'] = hasActiveSubscription;
          processedList.add(customerMap);
        }

        debugPrint('📋 Found ${data.length} total customers');
        return processedList;
      }
      debugPrint('⚠️ Unexpected response format - returning empty list');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching all customers: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Regenerate QR code for a customer
  Future<Map<String, dynamic>> regenerateQRCode(int customerId) async {
    try {
      debugPrint('🔄 Regenerating QR code for customer $customerId...');

      // Try backend endpoint first
      try {
        final response = await _apiService.post(
          ApiEndpoints.regenerateQRCode(customerId),
          data: {},
        );

        debugPrint('🔄 QR Regenerate Response Status: ${response.statusCode}');
        debugPrint('🔄 QR Regenerate Response Data: ${response.data}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final qrCode = response.data['qr_code'] ??
                        response.data['data']?['qr_code'] ??
                        'customer_id:$customerId';

          debugPrint('✅ QR code regenerated from backend: $qrCode');

          return {
            'success': true,
            'message': 'QR code regenerated successfully',
            'qr_code': qrCode,
          };
        }
      } catch (e) {
        debugPrint('⚠️ Backend endpoint not available: $e');
        // Continue to fallback method
      }

      // Fallback: Generate QR code locally if backend endpoint doesn't exist
      debugPrint('📱 Generating QR code locally (backend endpoint not available)');
      final qrCode = 'customer_id:$customerId';

      debugPrint('✅ QR code generated locally: $qrCode');

      return {
        'success': true,
        'message': 'QR code generated successfully',
        'qr_code': qrCode,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Error regenerating QR code: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
