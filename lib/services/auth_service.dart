import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/api_config.dart';

class AuthService {
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String? _token;

  static String? get token => _token;

  // Initialize token from secure storage
  static Future<void> initializeToken() async {
    if (kIsWeb) {
      // For web, use shared_preferences or skip secure storage
      // For now, we'll use a simple approach
      _token = null;
    } else {
      _token = await _storage.read(key: 'auth_token');
    }
  }

  // Save token to secure storage
  static Future<void> _saveToken(String token) async {
    _token = token;
    if (!kIsWeb) {
      await _storage.write(key: 'auth_token', value: token);
    }
    // For web, you might want to use shared_preferences or another storage method
  }

  // ✅ ADDED: Store token method (public version of _saveToken)
  static Future<void> storeToken(String token) async {
    await _saveToken(token);
  }

  // Clear token from secure storage
  static Future<void> clearToken() async {
    _token = null;
    if (!kIsWeb) {
      await _storage.delete(key: 'auth_token');
    }
    // For web, clear from whatever storage you're using
  }

  // Get headers with authorization token
  static Future<Map<String, String>> getAuthHeaders() async {
    // Ensure token is loaded from storage
    if (_token == null) {
      await initializeToken();
    }
    
    if (_token == null) {
      throw Exception('No authentication token found');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  // Check network connectivity - UPDATED for web compatibility
  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) {
        // For web, we'll assume connectivity is present
        // You could add a more sophisticated check here if needed
        return true;
      } else {
        final connectivityResult = await Connectivity().checkConnectivity();
        return connectivityResult != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }

  // Register with email/password - UPDATED: Now saves token from response
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        // ✅ Save token if it exists in the response
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'],
          'userId': data['userId'],
          'token': data['token'], // ✅ Include token in response
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Login with email/password - UPDATED: Always save token
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Always save token to secure storage
        await _saveToken(data['token']);
        
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Google OAuth login
  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': idToken,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Always save token to secure storage
        await _saveToken(data['token']);
        
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Google login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Send OTP for password reset
  static Future<Map<String, dynamic>> sendResetOTP({
    required String email,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Reset password with OTP
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Password reset failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    await initializeToken();
    return _token != null;
  }

  // Get stored token
  static Future<String?> getStoredToken() async {
    await initializeToken();
    return _token;
  }

  // ✅ ADDED: Get user ID from token (helper method)
  static Future<String?> getUserId() async {
    final token = await getStoredToken();
    if (token == null) return null;
    
    try {
      // Decode JWT token to get user info
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded);
      
      return payloadMap['id']?.toString();
    } catch (e) {
      return null;
    }
  }

  // ✅ ADDED: Logout method that also clears token
  static Future<void> logout() async {
    try {
      // Call backend logout endpoint if needed
      final token = await getStoredToken();
      if (token != null) {
        try {
          await http.post(
            Uri.parse('$baseUrl/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          // Silently fail if logout API call fails
        }
      }
    } finally {
      // Always clear the token locally
      await clearToken();
    }
  }

  // ✅ ADDED: Refresh token if needed (placeholder for future implementation)
  static Future<bool> refreshToken() async {
    // Implement token refresh logic here if needed
    return false;
  }

  // ✅ ADDED: Check token validity
  static Future<bool> isTokenValid() async {
    final token = await getStoredToken();
    if (token == null) return false;
    
    try {
      // Check if token is expired
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded);
      
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final currentTime = DateTime.now();
      
      return expiryTime.isAfter(currentTime);
    } catch (e) {
      return false;
    }
  }
}