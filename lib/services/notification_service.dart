import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../utils/api_config.dart';
import '../models/notification_models.dart';

class NotificationService {
  static String get baseUrl => '${ApiConfig.baseUrl}/notifications';

  // Check network connectivity
  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) {
        return true;
      } else {
        final connectivityResult = await Connectivity().checkConnectivity();
        return connectivityResult != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }

  // ===== NOTIFICATION PREFERENCES =====

  // Get all notification preferences
  static Future<Map<String, dynamic>> getPreferences() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'preferences': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/preferences'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        List<NotificationPreference> preferences = [];
        if (data is List) {
          preferences = data.map((p) => NotificationPreference.fromJson(p)).toList();
        }
        return {
          'success': true,
          'preferences': preferences,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch preferences',
          'preferences': [],
        };
      }
    } catch (e) {
      debugPrint('Get preferences error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'preferences': [],
      };
    }
  }

  // Create or update notification preference
  static Future<Map<String, dynamic>> savePreference(NotificationPreference preference) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/preferences'),
        headers: headers,
        body: json.encode(preference.toJson()),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Notification saved successfully',
          'preference': data['preference'] != null 
              ? NotificationPreference.fromJson(data['preference'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save notification',
        };
      }
    } catch (e) {
      debugPrint('Save preference error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Toggle notification enabled/disabled
  static Future<Map<String, dynamic>> togglePreference(int id, bool isEnabled) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/preferences/$id/toggle'),
        headers: headers,
        body: json.encode({'is_enabled': isEnabled}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Notification toggled successfully',
          'is_enabled': data['is_enabled'] ?? isEnabled,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to toggle notification',
        };
      }
    } catch (e) {
      debugPrint('Toggle preference error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Delete notification preference
  static Future<Map<String, dynamic>> deletePreference(int id) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/preferences/$id'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Notification deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete notification',
        };
      }
    } catch (e) {
      debugPrint('Delete preference error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Reset to default notifications
  static Future<Map<String, dynamic>> resetToDefaults() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/preferences/reset'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Notifications reset to defaults',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset notifications',
        };
      }
    } catch (e) {
      debugPrint('Reset preferences error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== FCM TOKEN MANAGEMENT =====

  // Register FCM token
  static Future<Map<String, dynamic>> registerToken({
    required String fcmToken,
    String? deviceType,
    String? deviceName,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: headers,
        body: json.encode({
          'fcm_token': fcmToken,
          'device_type': deviceType,
          'device_name': deviceName,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Token registered successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to register token',
        };
      }
    } catch (e) {
      debugPrint('Register token error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Remove FCM token
  static Future<Map<String, dynamic>> removeToken(String fcmToken) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/token'),
        headers: headers,
        body: json.encode({'fcm_token': fcmToken}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Token removed successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to remove token',
        };
      }
    } catch (e) {
      debugPrint('Remove token error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get user's FCM tokens
  static Future<Map<String, dynamic>> getTokens() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'tokens': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tokens'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        List<FCMToken> tokens = [];
        if (data is List) {
          tokens = data.map((t) => FCMToken.fromJson(t)).toList();
        }
        return {
          'success': true,
          'tokens': tokens,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch tokens',
          'tokens': [],
        };
      }
    } catch (e) {
      debugPrint('Get tokens error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'tokens': [],
      };
    }
  }

  // ===== NOTIFICATION HISTORY =====

  // Get notification history
  static Future<Map<String, dynamic>> getHistory({int page = 1, int limit = 20}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'history': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/history?page=$page&limit=$limit'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        List<NotificationHistory> history = [];
        if (data is List) {
          history = data.map((h) => NotificationHistory.fromJson(h)).toList();
        }
        return {
          'success': true,
          'history': history,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch history',
          'history': [],
        };
      }
    } catch (e) {
      debugPrint('Get history error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'history': [],
      };
    }
  }

  // ===== TEST NOTIFICATION (Debug only) =====

  // Send test notification (for debugging)
  static Future<Map<String, dynamic>> sendTestNotification({
    required String fcmToken,
    required String title,
    required String message,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/test'),
        headers: headers,
        body: json.encode({
          'fcm_token': fcmToken,
          'title': title,
          'message': message,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Test notification sent',
          'response': data['response'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send test notification',
        };
      }
    } catch (e) {
      debugPrint('Test notification error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}

// Helper function to convert day indices to repeat_days string
String daysToRepeatDays(List<int> days) {
  if (days.length == 7) return 'all';
  
  const dayMap = {0: 'sun', 1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat'};
  
  // Check if it matches weekdays - use manual check instead of extension
  if (days.length == 5) {
    final weekdays = [1, 2, 3, 4, 5];
    bool matchesWeekdays = true;
    for (var day in weekdays) {
      if (!days.contains(day)) {
        matchesWeekdays = false;
        break;
      }
    }
    if (matchesWeekdays) return 'weekdays';
  }
  
  // Check if it matches weekends - use manual check instead of extension
  if (days.length == 2) {
    final weekends = [0, 6];
    bool matchesWeekends = true;
    for (var day in weekends) {
      if (!days.contains(day)) {
        matchesWeekends = false;
        break;
      }
    }
    if (matchesWeekends) return 'weekends';
  }
  
  // Custom days
  return days.map((d) => dayMap[d]!).join(',');
}

