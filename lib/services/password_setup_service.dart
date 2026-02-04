import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/api_config.dart';

class PasswordSetupService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Setup password for Google users
  static Future<Map<String, dynamic>> setupPassword({
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/setup-password'),
        headers: headers,
        body: json.encode({
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
          'message': data['message'] ?? 'Failed to setup password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Check if user has password
  static Future<Map<String, dynamic>> hasPassword() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile/has-password'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'hasPassword': data['hasPassword'],
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