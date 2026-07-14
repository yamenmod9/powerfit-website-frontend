import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'jwt_token';

  /// Callback invoked when session has expired (401 or stale-JWT 404).
  /// AuthProvider sets this to trigger a forced logout + GoRouter redirect.
  VoidCallback? onSessionExpired;

  /// Guard to prevent multiple simultaneous forced-logouts.
  bool _isLoggingOut = false;
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Allow auth service to handle 401 responses
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add JWT token to headers
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Detect auth failures that come through as normal responses
          // (because validateStatus allows < 500)
          final statusCode = response.statusCode;

          bool sessionExpired = false;

          if (statusCode == 401) {
            // Backend explicitly says session expired / token invalid
            sessionExpired = true;
          } else if (statusCode == 404) {
            // Legacy PythonAnywhere backend may still return 404 + "User not found"
            // when the JWT references a deleted/re-seeded user.
            final data = response.data;
            if (data is Map) {
              final error = (data['error'] ?? data['msg'] ?? '').toString().toLowerCase();
              if (error.contains('user not found') ||
                  error.contains('session expired')) {
                sessionExpired = true;
              }
            }
          }

          if (sessionExpired) {
            debugPrint('🔒 Session expired detected (${response.statusCode}) — forcing logout');
            await _storage.delete(key: _tokenKey);
            _triggerForcedLogout();
          }

          return handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Unauthorized - clear token
            await _storage.delete(key: _tokenKey);
            _triggerForcedLogout();
          } else if (error.response?.statusCode == 403) {
            // Forbidden - permission error
            error = DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: 'You do not have permission to perform this action',
            );
          } else if (error.response?.statusCode == 500) {
            // Server error
            error = DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: 'Server error. Please try again later.',
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Fire the forced-logout callback exactly once until reset.
  void _triggerForcedLogout() {
    if (!_isLoggingOut && onSessionExpired != null) {
      _isLoggingOut = true;
      onSessionExpired!();
      // Reset the guard after a short delay so future 401s can trigger again
      // (e.g. if the user logs back in and gets another stale token).
      Future.delayed(const Duration(seconds: 2), () => _isLoggingOut = false);
    }
  }
  
  // Generic GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }
  
  // Generic POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Generic PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Generic DELETE request
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }
  
  // Save JWT token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
  
  // Get JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  // Delete JWT token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
