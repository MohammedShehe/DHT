import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/api_config.dart';
import '../models/health_profile_model.dart';

class HealthService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Save health profile
  static Future<Map<String, dynamic>> saveHealthProfile(HealthProfileModel profile) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/health/save'),
        headers: headers,
        body: json.encode(profile.toJson()),
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
          'message': data['message'] ?? 'Failed to save health profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get health profile
  static Future<Map<String, dynamic>> getHealthProfile() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      );

      print('Health profile response status: ${response.statusCode}');
      print('Health profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if data is null or empty
        if (data == null) {
          print('Health profile data is null');
          return {
            'success': true,
            'profile': null,
          };
        }
        
        // Check if it's an empty object or has no meaningful data
        if (data is Map && data.isEmpty) {
          print('Health profile data is empty map');
          return {
            'success': true,
            'profile': null,
          };
        }
        
        // Check if the response contains user_id (or any field that indicates a valid profile)
        // The backend returns the profile object directly, so if we have any data, it's a valid profile
        print('Health profile data received: $data');
        
        // If we have any fields that indicate a valid profile (like age, gender, etc.)
        if (data.containsKey('age') || data.containsKey('gender') || data.containsKey('user_id')) {
          return {
            'success': true,
            'profile': data,
          };
        } else {
          print('No valid profile fields found in response');
          return {
            'success': true,
            'profile': null,
          };
        }
      } else if (response.statusCode == 404) {
        print('Health profile not found (404)');
        return {
          'success': true,
          'profile': null,
        };
      } else {
        final data = json.decode(response.body);
        print('Error response: $data');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch health profile',
        };
      }
    } catch (e) {
      print('Exception in getHealthProfile: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}