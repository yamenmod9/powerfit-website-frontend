import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../api/api_service.dart';
import '../api/api_endpoints.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'jwt_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _branchIdKey = 'branch_id';
  
  AuthService(this._apiService);
  
  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        // Backend returns: {data: {access_token: ..., user: {...}}, message: ..., success: true}
        final data = responseData['data'] ?? responseData;
        final user = data['user'];

        // Extract token - try multiple field names
        final token = data['access_token'] ??
                     data['token'] ??
                     responseData['access_token'] ??
                     responseData['token'];

        if (token != null) {
          // Save token
          await _apiService.saveToken(token);
          await _storage.write(key: _tokenKey, value: token);
          
          // Extract user info from 'user' object or decode from token
          String? role;
          String? userId;
          String? userUsername;
          int? branchId;

          if (user != null) {
            // Get from user object (preferred)
            role = user['role']?.toString();
            userId = user['id']?.toString();
            userUsername = user['username'] ?? user['full_name'] ?? username;
            branchId = user['branch_id'];
          } else {
            // Fallback to token decode
            try {
              final decodedToken = JwtDecoder.decode(token);

              role = decodedToken['role'];
              userId = decodedToken['sub'] ?? decodedToken['user_id'];
              userUsername = decodedToken['username'] ?? username;
              branchId = decodedToken['branch_id'];
            } catch (e) {
              // Token decode failed, continue with available data
            }
          }

          // Save user info
          if (role != null) {
            await _storage.write(key: _userRoleKey, value: role);
          }
          if (userId != null) {
            await _storage.write(key: _userIdKey, value: userId);
          }
          if (userUsername != null) {
            await _storage.write(key: _usernameKey, value: userUsername);
          }
          if (branchId != null) {
            await _storage.write(key: _branchIdKey, value: branchId.toString());
          }
          
          // Extract gym data (returned for owner users)
          final gymData = data['gym'] as Map<String, dynamic>?;

          return {
            'success': true,
            'token': token,
            'role': role,
            'user_id': userId,
            'username': userUsername,
            'branch_id': branchId,
            if (gymData != null) 'gym': gymData,
          };
        }
      }

      // If we reach here, login failed even with 200 response
      final errorMessage = response.data?['message'] ??
                          response.data?['error'];

      // Provide specific error message
      if (errorMessage != null) {
        final lowerMessage = errorMessage.toLowerCase();
        if (lowerMessage.contains('password')) {
          return {
            'success': false,
            'message': 'Incorrect password. Please try again.',
          };
        } else if (lowerMessage.contains('username') || lowerMessage.contains('user')) {
          return {
            'success': false,
            'message': 'Username not found. Please check your username.',
          };
        } else if (lowerMessage.contains('credential')) {
          return {
            'success': false,
            'message': 'Incorrect username or password. Please try again.',
          };
        }
      }

      return {
        'success': false,
        'message': errorMessage ?? 'Login failed. Please check your credentials and try again.',
      };
    } catch (e) {
      String errorMessage = 'Login failed';

      if (e is DioException) {
        if (e.response != null) {
          final statusCode = e.response?.statusCode;
          final responseMessage = e.response?.data?['message'] ??
                                 e.response?.data?['error'];

          // Specific error messages based on status code
          if (statusCode == 401) {
            errorMessage = responseMessage ?? 'Incorrect username or password. Please try again.';
          } else if (statusCode == 404) {
            errorMessage = 'Account not found. Please check your username.';
          } else if (statusCode == 403) {
            errorMessage = 'Account is disabled or suspended. Please contact support.';
          } else if (statusCode == 400) {
            errorMessage = responseMessage ?? 'Invalid login credentials. Please check your input.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = responseMessage ?? 'Login failed. Please try again. (Error: $statusCode)';
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Server took too long to respond. Please try again.';
        } else if (e.type == DioExceptionType.unknown) {
          errorMessage = 'Cannot connect to server. Please check your internet connection.';
        } else {
          errorMessage = 'Network error. Please try again.';
        }
      } else {
        errorMessage = 'Unexpected error occurred. Please try again.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post(ApiEndpoints.logout);
    } catch (e) {
      // Ignore error, clear local data anyway
    }
    
    await _apiService.deleteToken();
    // Only delete auth-session keys; preserve biometric credentials
    // so the user can still use biometric login after logout.
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userRoleKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _branchIdKey);
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return false;
    
    try {
      // Check if token is expired
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }
  
  // Get current user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }
  
  // Get current user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }
  
  // Get current username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }
  
  // Get current branch ID
  Future<String?> getBranchId() async {
    return await _storage.read(key: _branchIdKey);
  }
  
  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
