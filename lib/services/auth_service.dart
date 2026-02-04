import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class AuthService {
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';
  
  // Storage instances for different platforms
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _sharedPreferences;
  
  static String? _token;

  static String? get token => _token;

  // Initialize token from appropriate storage
  static Future<void> initializeToken() async {
    if (kIsWeb) {
      // For web, use shared_preferences
      if (_sharedPreferences == null) {
        _sharedPreferences = await SharedPreferences.getInstance();
      }
      _token = _sharedPreferences!.getString('auth_token');
    } else {
      // For mobile, use secure storage
      _token = await _secureStorage.read(key: 'auth_token');
    }
  }

  // Save token to appropriate storage
  static Future<void> _saveToken(String token) async {
    _token = token;
    
    if (kIsWeb) {
      // For web, use shared_preferences
      if (_sharedPreferences == null) {
        _sharedPreferences = await SharedPreferences.getInstance();
      }
      await _sharedPreferences!.setString('auth_token', token);
    } else {
      // For mobile, use secure storage
      await _secureStorage.write(key: 'auth_token', value: token);
    }
  }

  // ✅ ADDED: Store token method (public version of _saveToken)
  static Future<void> storeToken(String token) async {
    await _saveToken(token);
  }

  // Clear token from storage
  static Future<void> clearToken() async {
    _token = null;
    
    if (kIsWeb) {
      // For web, use shared_preferences
      if (_sharedPreferences == null) {
        _sharedPreferences = await SharedPreferences.getInstance();
      }
      await _sharedPreferences!.remove('auth_token');
    } else {
      // For mobile, use secure storage
      await _secureStorage.delete(key: 'auth_token');
    }
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

  // Check network connectivity
  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) {
        // For web, use navigator.onLine if available
        // Fallback to true for web as connectivity_plus may not work perfectly on web
        return true;
      } else {
        final connectivityResult = await Connectivity().checkConnectivity();
        return connectivityResult != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }

  // Register with email/password
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
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Login with email/password
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
        // Always save token to storage
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
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ✅ UPDATED: Google OAuth login with user existence check
  static Future<Map<String, dynamic>> googleLogin({
    String? idToken,
    String? accessToken,
    bool checkExistenceOnly = false, // NEW: For checking if user exists
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      // Prepare request body
      Map<String, dynamic> requestBody = {};
      
      if (idToken != null) {
        requestBody['token'] = idToken;
      }
      
      if (accessToken != null) {
        requestBody['accessToken'] = accessToken;
      }
      
      if (requestBody.isEmpty) {
        return {
          'success': false,
          'message': 'No authentication token provided',
        };
      }

      // Add flag to check existence only (for registration flow)
      if (checkExistenceOnly) {
        requestBody['check_existence'] = true;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // For existence check, don't save token
        if (!checkExistenceOnly) {
          await _saveToken(data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'],
          'token': checkExistenceOnly ? null : data['token'],
          'userExists': data['userExists'] ?? true, // Default to true if not specified
          'requiresPasswordSetup': data['requiresPasswordSetup'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Google login failed',
        };
      }
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
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
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
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
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
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
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
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

  // ✅ Get user ID from token (helper method)
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
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      return payloadMap['id']?.toString();
    } catch (e) {
      return null;
    }
  }

  // ✅ Get user email from token
  static Future<String?> getUserEmail() async {
    final token = await getStoredToken();
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      return payloadMap['email']?.toString();
    } catch (e) {
      return null;
    }
  }

  // ✅ Logout method that also clears token
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

  // ✅ Check token validity
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
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final currentTime = DateTime.now();
      
      // Check if token expires within 5 minutes (for refresh consideration)
      final bufferTime = expiryTime.subtract(const Duration(minutes: 5));
      return currentTime.isBefore(bufferTime);
    } catch (e) {
      return false;
    }
  }

  // ✅ Clear all authentication data
  static Future<void> clearAllAuthData() async {
    await clearToken();
    
    if (kIsWeb && _sharedPreferences != null) {
      // Clear any other auth-related data from shared preferences
      await _sharedPreferences!.remove('user_email');
      await _sharedPreferences!.remove('user_name');
    }
  }

  // ✅ Initialize the service (call this early in your app)
  static Future<void> initialize() async {
    await initializeToken();
  }

  // ✅ Get authentication status with validity check
  static Future<Map<String, dynamic>> getAuthStatus() async {
    final hasToken = await isLoggedIn();
    final tokenValid = await isTokenValid();
    
    return {
      'loggedIn': hasToken,
      'tokenValid': tokenValid,
      'needsRefresh': hasToken && !tokenValid,
    };
  }

  // ✅ Create headers for multipart requests (for file uploads)
  static Future<Map<String, String>> getMultipartHeaders() async {
    final token = await getStoredToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ Check if user exists via Google (for registration flow)
  static Future<Map<String, dynamic>> checkGoogleUserExists({
    String? idToken,
    String? accessToken,
  }) async {
    return await googleLogin(
      idToken: idToken,
      accessToken: accessToken,
      checkExistenceOnly: true,
    );
  }

  // ✅ Check if current user has password (using the password setup service)
  static Future<Map<String, dynamic>> hasPassword() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/has-password'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'hasPassword': data['hasPassword'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to check password status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}