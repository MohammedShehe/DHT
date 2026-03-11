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
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _sharedPreferences;
  
  static String? _token;

  static String? get token => _token;

  static Future<void> initializeToken() async {
    if (kIsWeb) {
      if (_sharedPreferences == null) {
        _sharedPreferences = await SharedPreferences.getInstance();
      }
      _token = _sharedPreferences!.getString('auth_token');
    } else {
      _token = await _secureStorage.read(key: 'auth_token');
    }
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    
    if (kIsWeb) {
      if (_sharedPreferences == null) {
        _sharedPreferences = await SharedPreferences.getInstance();
      }
      await _sharedPreferences!.setString('auth_token', token);
    } else {
      await _secureStorage.write(key: 'auth_token', value: token);
    }
  }

  static Future<void> storeToken(String token) async {
    await _saveToken(token);
  }

  static Future<void> clearToken() async {
    _token = null;
    
    if (kIsWeb) {
      if (_sharedPreferences == null) {
        _sharedPreferences = await SharedPreferences.getInstance();
      }
      await _sharedPreferences!.remove('auth_token');
    } else {
      await _secureStorage.delete(key: 'auth_token');
    }
  }

  static Future<Map<String, String>> getAuthHeaders() async {
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

  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) return true;
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

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
        if (data['requiresOtpVerification'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'OTP sent to your email',
            'requiresOtpVerification': true,
            'userId': data['userId']?.toString() ?? '',
            'email': data['email']?.toString() ?? email,
          };
        }
        
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'],
          'userId': data['userId'],
          'token': data['token'],
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
        'message': 'Connection error',
      };
    }
  }

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
        if (data['requiresOtpVerification'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'OTP sent to your email',
            'requiresOtpVerification': true,
            'userId': data['userId']?.toString() ?? '',
            'email': data['email']?.toString() ?? email,
          };
        }
        
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
        'message': 'Connection error',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyLoginOTP({
    required String userId,
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
        Uri.parse('$baseUrl/verify-login-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
          'user': data['user'],
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
        'message': 'Connection error',
      };
    }
  }

  static Future<Map<String, dynamic>> resendLoginOTP({
    required String userId,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-login-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
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
          'message': data['message'] ?? 'Failed to resend OTP',
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
        'message': 'Connection error',
      };
    }
  }

  static Future<Map<String, dynamic>> googleLogin({
    String? idToken,
    String? accessToken,
    bool checkExistenceOnly = false,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      Map<String, dynamic> requestBody = {};
      
      if (idToken != null) requestBody['token'] = idToken;
      if (accessToken != null) requestBody['accessToken'] = accessToken;
      
      if (requestBody.isEmpty) {
        return {
          'success': false,
          'message': 'No authentication token provided',
        };
      }

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
        if (!checkExistenceOnly) {
          await _saveToken(data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Google login successful',
          'token': checkExistenceOnly ? null : data['token'],
          'userExists': data['userExists'] ?? true,
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
        'message': 'Connection error',
      };
    }
  }

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
        body: json.encode({'email': email}),
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
        'message': 'Connection error',
      };
    }
  }

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
        body: json.encode({'email': email, 'otp': otp}),
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
        'message': 'Connection error',
      };
    }
  }

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
        'message': 'Connection error',
      };
    }
  }

  static Future<bool> isLoggedIn() async {
    await initializeToken();
    return _token != null && _token!.isNotEmpty;
  }

  static Future<String?> getStoredToken() async {
    await initializeToken();
    return _token;
  }

  static Future<String?> getUserId() async {
    final token = await getStoredToken();
    if (token == null) return null;
    
    try {
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

  static Future<void> logout() async {
    try {
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
        } catch (e) {}
      }
    } finally {
      await clearToken();
    }
  }

  static Future<bool> isTokenValid() async {
    final token = await getStoredToken();
    if (token == null || token.isEmpty) return false;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearAllAuthData() async {
    await clearToken();
    if (kIsWeb && _sharedPreferences != null) {
      await _sharedPreferences!.remove('user_email');
      await _sharedPreferences!.remove('user_name');
    }
  }

  static Future<void> initialize() async {
    await initializeToken();
  }

  static Future<Map<String, dynamic>> getAuthStatus() async {
    final hasToken = await isLoggedIn();
    final tokenValid = await isTokenValid();
    
    return {
      'loggedIn': hasToken,
      'tokenValid': tokenValid,
      'needsRefresh': hasToken && !tokenValid,
    };
  }

  static Future<Map<String, String>> getMultipartHeaders() async {
    final token = await getStoredToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return {'Authorization': 'Bearer $token'};
  }

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
        'message': 'Connection error',
      };
    }
  }
}