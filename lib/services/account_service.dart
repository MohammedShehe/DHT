import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_service.dart';
import '../utils/api_config.dart';

class AccountService {
  static String get baseUrl => '${ApiConfig.baseUrl}/account';
  
  // Check network connectivity - UPDATED for web compatibility
  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) {
        // For web, we'll assume connectivity is present
        return true;
      } else {
        final connectivityResult = await Connectivity().checkConnectivity();
        return connectivityResult != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }

  // Logout user
  static Future<Map<String, dynamic>> logout() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Clear token on successful logout
        await AuthService.clearToken();
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Logout failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Request account deletion (send OTP to email)
  static Future<Map<String, dynamic>> requestDeleteAccount(String password) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/delete/request'),
        headers: headers,
        body: json.encode({
          'password': password,
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
          'message': data['message'] ?? 'Failed to request deletion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Confirm account deletion with OTP
  static Future<Map<String, dynamic>> confirmDeleteAccount(String otp) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/delete/confirm'),
        headers: headers,
        body: json.encode({
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Clear token on successful deletion
        await AuthService.clearToken();
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete account',
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