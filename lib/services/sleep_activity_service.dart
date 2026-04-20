import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_service.dart';
import '../utils/api_config.dart';
import '../models/sleep_activity_models.dart';

class SleepActivityService {
  static String get baseUrl => '${ApiConfig.baseUrl}/sleep-activity';

  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) return true;
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Helper to format date for API (YYYY-MM-DD)
  static String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Log sleep (create or update)
  static Future<Map<String, dynamic>> logSleep({
    required DateTime sleepDate,
    required String bedtime,
    required String wakeTime,
    required int interruptions,
    required String sleepQuality,
    String? notes,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = _formatDateForApi(sleepDate);

      final body = json.encode({
        'sleep_date': formattedDate,
        'bedtime': bedtime,
        'wake_time': wakeTime,
        'interruptions': interruptions,
        'sleep_quality': sleepQuality,
        'notes': notes,
      });

      debugPrint('Logging sleep: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/log'),
        headers: headers,
        body: body,
      );

      final data = json.decode(response.body);
      debugPrint('Sleep log response: $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Sleep logged successfully',
          'sleep_log': data['sleep_log'] != null
              ? SleepLog.fromJson(data['sleep_log'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log sleep',
        };
      }
    } catch (e) {
      debugPrint('Log sleep error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get sleep log for a specific date
  static Future<Map<String, dynamic>> getSleepLog(DateTime date) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'sleep_log': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = _formatDateForApi(date);

      final response = await http.get(
        Uri.parse('$baseUrl/$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'sleep_log': data != null ? SleepLog.fromJson(data) : null,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'sleep_log': null,
          'message': 'No sleep log found',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch sleep log',
          'sleep_log': null,
        };
      }
    } catch (e) {
      debugPrint('Get sleep log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'sleep_log': null,
      };
    }
  }

  // Delete sleep log for a specific date
  static Future<Map<String, dynamic>> deleteSleepLog(DateTime date) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = _formatDateForApi(date);

      final response = await http.delete(
        Uri.parse('$baseUrl/$formattedDate'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Sleep log deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete sleep log',
        };
      }
    } catch (e) {
      debugPrint('Delete sleep log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get sleep logs for date range
  static Future<Map<String, dynamic>> getSleepLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    int? offset,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'logs': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      String url = '$baseUrl/range?start_date=${_formatDateForApi(startDate)}&end_date=${_formatDateForApi(endDate)}';
      if (limit != null) url += '&limit=$limit';
      if (offset != null) url += '&offset=$offset';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<SleepLog> logs = [];
        if (data['logs'] != null && data['logs'] is List) {
          logs = (data['logs'] as List)
              .map((log) => SleepLog.fromJson(log))
              .toList();
        }
        return {
          'success': true,
          'logs': logs,
          'total': data['total'] ?? logs.length,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch sleep logs',
          'logs': [],
        };
      }
    } catch (e) {
      debugPrint('Get sleep logs by range error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'logs': [],
      };
    }
  }

  // Get weekly stats by day of week (for graph)
  static Future<Map<String, dynamic>> getWeeklyStatsByDay({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'stats': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/weekly?start_date=${_formatDateForApi(startDate)}&end_date=${_formatDateForApi(endDate)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<WeeklySleepStat> stats = [];
        if (data is List) {
          stats = data.map((stat) => WeeklySleepStat.fromJson(stat)).toList();
        }
        return {
          'success': true,
          'stats': stats,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch weekly stats',
          'stats': [],
        };
      }
    } catch (e) {
      debugPrint('Get weekly stats error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'stats': [],
      };
    }
  }

  // Get daily chart data (last N days)
  static Future<Map<String, dynamic>> getDailyChartData({int days = 30}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'chart_data': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/chart?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'chart_data': data,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch chart data',
          'chart_data': [],
        };
      }
    } catch (e) {
      debugPrint('Get daily chart data error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'chart_data': [],
      };
    }
  }

  // Get summary statistics
  static Future<Map<String, dynamic>> getSummaryStats({
    required String period, // 'week', 'month', 'quarter'
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'summary': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/summary?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'summary': data,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch summary',
          'summary': null,
        };
      }
    } catch (e) {
      debugPrint('Get summary stats error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'summary': null,
      };
    }
  }

  // Get weekly comparison
  static Future<Map<String, dynamic>> getWeeklyComparison() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'comparison': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/comparison'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'comparison': data,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch comparison',
          'comparison': null,
        };
      }
    } catch (e) {
      debugPrint('Get weekly comparison error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'comparison': null,
      };
    }
  }

  // Get trend data
  static Future<Map<String, dynamic>> getTrendData({int weeks = 12}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'trends': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/trends?weeks=$weeks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'trends': data['weeks'] ?? [],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch trends',
          'trends': [],
        };
      }
    } catch (e) {
      debugPrint('Get trend data error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'trends': [],
      };
    }
  }

  // Get bedtime consistency score
  static Future<Map<String, dynamic>> getConsistency({int days = 30}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'consistency': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/consistency?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'consistency': data,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch consistency',
          'consistency': null,
        };
      }
    } catch (e) {
      debugPrint('Get consistency error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'consistency': null,
      };
    }
  }

  // Get sleep quality types (for dropdown)
  static Future<Map<String, dynamic>> getQualityTypes() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'quality_types': _getDefaultQualityTypes(),
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/quality-types'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'quality_types': data,
        };
      } else {
        return {
          'success': true,
          'quality_types': _getDefaultQualityTypes(),
        };
      }
    } catch (e) {
      debugPrint('Get quality types error: $e');
      return {
        'success': true,
        'quality_types': _getDefaultQualityTypes(),
      };
    }
  }

  static List<Map<String, dynamic>> _getDefaultQualityTypes() {
    return [
      {'value': 'Poor', 'label': 'Poor', 'color': '#EF4444', 'description': 'Woke up tired, had trouble sleeping'},
      {'value': 'Fair', 'label': 'Fair', 'color': '#F59E0B', 'description': 'OK sleep, could be better'},
      {'value': 'Good', 'label': 'Good', 'color': '#10B981', 'description': 'Slept well, felt rested'},
      {'value': 'Excellent', 'label': 'Excellent', 'color': '#3B82F6', 'description': 'Perfect sleep, woke up refreshed'},
    ];
  }
}