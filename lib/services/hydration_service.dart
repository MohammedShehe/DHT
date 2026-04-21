import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../utils/api_config.dart';
import '../models/hydration_models.dart';

class HydrationService {
  static String get baseUrl => '${ApiConfig.baseUrl}/hydration-activity';

  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) return true;
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  static String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ===== PUBLIC ENDPOINTS =====

  static Future<Map<String, dynamic>> getDrinkTypes() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'drink_types': _getDefaultDrinkTypes(),
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/drink-types'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<DrinkType> drinkTypes = [];
        if (data is List) {
          drinkTypes = data.map((d) => DrinkType.fromJson(d)).toList();
        }
        return {
          'success': true,
          'drink_types': drinkTypes,
        };
      } else {
        return {
          'success': true,
          'drink_types': _getDefaultDrinkTypes(),
        };
      }
    } catch (e) {
      return {
        'success': true,
        'drink_types': _getDefaultDrinkTypes(),
      };
    }
  }

  static List<DrinkType> _getDefaultDrinkTypes() {
    return [
      DrinkType(value: 'water', label: '💧 Water', color: '#3B82F6', icon: 'local_drink'),
      DrinkType(value: 'sports_drink', label: '⚡ Sports Drink', color: '#10B981', icon: 'bolt'),
      DrinkType(value: 'juice', label: '🍊 Juice', color: '#F59E0B', icon: 'apple'),
      DrinkType(value: 'tea', label: '🍵 Tea', color: '#8B5CF6', icon: 'local_cafe'),
      DrinkType(value: 'coffee', label: '☕ Coffee', color: '#78350F', icon: 'coffee'),
      DrinkType(value: 'milk', label: '🥛 Milk', color: '#EC4899', icon: 'egg'),
      DrinkType(value: 'soda', label: '🥤 Soda', color: '#EF4444', icon: 'local_drink'),
      DrinkType(value: 'other', label: '🧃 Other', color: '#6B7280', icon: 'more_horiz'),
    ];
  }

  static Future<Map<String, dynamic>> getPresetAmounts() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'preset_amounts': _getDefaultPresetAmounts(),
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/preset-amounts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<PresetAmount> presetAmounts = [];
        if (data is List) {
          presetAmounts = data.map((p) => PresetAmount.fromJson(p)).toList();
        }
        return {
          'success': true,
          'preset_amounts': presetAmounts,
        };
      } else {
        return {
          'success': true,
          'preset_amounts': _getDefaultPresetAmounts(),
        };
      }
    } catch (e) {
      return {
        'success': true,
        'preset_amounts': _getDefaultPresetAmounts(),
      };
    }
  }

  static List<PresetAmount> _getDefaultPresetAmounts() {
    return [
      PresetAmount(value: 250, label: '250ml', icon: '🌊'),
      PresetAmount(value: 500, label: '500ml', icon: '💧'),
      PresetAmount(value: 750, label: '750ml', icon: '💧💧'),
      PresetAmount(value: 1000, label: '1000ml (1L)', icon: '💧💧💧'),
    ];
  }

  // ===== GOAL MANAGEMENT (CORRECTED: Using /goal endpoint) =====

  static Future<Map<String, dynamic>> setGoal(int dailyTargetMl) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔵 Setting goal: POST $baseUrl/goal');
      print('🔵 Body: {"daily_target_ml": $dailyTargetMl}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/goal'),
        headers: headers,
        body: json.encode({'daily_target_ml': dailyTargetMl}),
      );

      final data = json.decode(response.body);
      print('🔵 Response: ${response.statusCode} - $data');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Goal saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save goal',
        };
      }
    } catch (e) {
      print('🔴 Set goal error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getGoal() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'goal': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔵 Getting goal: GET $baseUrl/goal');
      
      final response = await http.get(
        Uri.parse('$baseUrl/goal'),
        headers: headers,
      );

      print('🔵 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'goal': HydrationGoal.fromJson(data),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'goal': null,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch goal',
          'goal': null,
        };
      }
    } catch (e) {
      print('🔴 Get goal error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'goal': null,
      };
    }
  }

  static Future<Map<String, dynamic>> deleteGoal() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔵 Deleting goal: DELETE $baseUrl/goal');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/goal'),
        headers: headers,
      );

      final data = json.decode(response.body);
      print('🔵 Response: ${response.statusCode} - $data');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Goal deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete goal',
        };
      }
    } catch (e) {
      print('🔴 Delete goal error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== HYDRATION LOGGING =====

  static Future<Map<String, dynamic>> logHydration({
    required int amountMl,
    required String drinkType,
    String? customDrinkName,
    required TimeOfDay consumptionTime,
    required DateTime logDate,
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
      final formattedDate = _formatDateForApi(logDate);
      final timeStr = '${consumptionTime.hour.toString().padLeft(2, '0')}:${consumptionTime.minute.toString().padLeft(2, '0')}:00';

      final body = json.encode({
        'amount_ml': amountMl,
        'drink_type': drinkType,
        'custom_drink_name': customDrinkName,
        'consumption_time': timeStr,
        'log_date': formattedDate,
        'notes': notes,
      });

      print('🔵 Logging hydration: POST $baseUrl/log');
      print('🔵 Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/log'),
        headers: headers,
        body: body,
      );

      final data = json.decode(response.body);
      print('🔵 Response: ${response.statusCode} - $data');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Hydration logged successfully',
          'log_id': data['log_id'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log hydration',
        };
      }
    } catch (e) {
      print('🔴 Log hydration error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getHydrationLogsByDate(DateTime date) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'logs': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = _formatDateForApi(date);
      print('🔵 Getting logs: GET $baseUrl/logs/$formattedDate');
      
      final response = await http.get(
        Uri.parse('$baseUrl/logs/$formattedDate'),
        headers: headers,
      );

      print('🔵 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<HydrationLog> logs = [];
        if (data is List) {
          logs = data.map((log) => HydrationLog.fromJson(log)).toList();
        }
        return {
          'success': true,
          'logs': logs,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch hydration logs',
          'logs': [],
        };
      }
    } catch (e) {
      print('🔴 Get logs error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'logs': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getHydrationLogById(int id) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'log': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔵 Getting log by ID: GET $baseUrl/log/$id');
      
      final response = await http.get(
        Uri.parse('$baseUrl/log/$id'),
        headers: headers,
      );

      print('🔵 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'log': HydrationLog.fromJson(data),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Log not found',
          'log': null,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch log',
          'log': null,
        };
      }
    } catch (e) {
      print('🔴 Get log by ID error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'log': null,
      };
    }
  }

  // ===== UPDATE/DELETE (CORRECTED) =====

  static Future<Map<String, dynamic>> updateHydrationLog({
    required int id,
    int? amountMl,
    String? drinkType,
    String? customDrinkName,
    TimeOfDay? consumptionTime,
    DateTime? logDate,
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
      final body = <String, dynamic>{};
      
      if (amountMl != null) body['amount_ml'] = amountMl;
      if (drinkType != null) body['drink_type'] = drinkType;
      if (customDrinkName != null) body['custom_drink_name'] = customDrinkName;
      if (consumptionTime != null) {
        body['consumption_time'] = '${consumptionTime.hour.toString().padLeft(2, '0')}:${consumptionTime.minute.toString().padLeft(2, '0')}:00';
      }
      if (logDate != null) body['log_date'] = _formatDateForApi(logDate);
      if (notes != null) body['notes'] = notes;

      print('🔵 Updating hydration log: PUT $baseUrl/log/$id');
      print('🔵 Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/log/$id'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      print('🔵 Response: ${response.statusCode} - $data');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Hydration log updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update hydration log',
        };
      }
    } catch (e) {
      print('🔴 Update error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteHydrationLog(int id) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔵 Deleting hydration log: DELETE $baseUrl/log/$id');

      final response = await http.delete(
        Uri.parse('$baseUrl/log/$id'),
        headers: headers,
      );

      final data = json.decode(response.body);
      print('🔵 Response: ${response.statusCode} - $data');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Hydration log deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete hydration log',
        };
      }
    } catch (e) {
      print('🔴 Delete error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== STATISTICS & ANALYTICS =====

  static Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'stats': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = _formatDateForApi(date);
      print('🔵 Getting daily stats: GET $baseUrl/stats/daily?date=$formattedDate');
      
      final response = await http.get(
        Uri.parse('$baseUrl/stats/daily?date=$formattedDate'),
        headers: headers,
      );

      print('🔵 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'stats': DailyHydrationStats.fromJson(data),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch daily stats',
          'stats': null,
        };
      }
    } catch (e) {
      print('🔴 Get daily stats error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'stats': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getWeeklyStats(DateTime startDate) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'stats': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = _formatDateForApi(startDate);
      print('🔵 Getting weekly stats: GET $baseUrl/stats/weekly?start_date=$formattedDate');
      
      final response = await http.get(
        Uri.parse('$baseUrl/stats/weekly?start_date=$formattedDate'),
        headers: headers,
      );

      print('🔵 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<WeeklyHydrationStats> stats = [];
        
        if (data['weekly_data'] != null && data['weekly_data'] is List) {
          stats = (data['weekly_data'] as List)
              .map((s) => WeeklyHydrationStats.fromJson(s))
              .toList();
        }
        
        return {
          'success': true,
          'stats': stats,
          'weekly_total_ml': data['weekly_total_ml'] as int? ?? 0,
          'weekly_average_ml': data['weekly_average_ml'] as int? ?? 0,
          'daily_target': data['daily_target'] as int? ?? 2500,
          'weekly_achievement': data['weekly_achievement'] as int? ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch weekly stats',
          'stats': [],
        };
      }
    } catch (e) {
      print('🔴 Get weekly stats error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'stats': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getDrinkTypeDistribution({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'distribution': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final url = '$baseUrl/stats/distribution?start_date=${_formatDateForApi(startDate)}&end_date=${_formatDateForApi(endDate)}';
      print('🔵 Getting distribution: GET $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🔵 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<DrinkTypeDistribution> distribution = [];
        if (data is List) {
          distribution = data.map((d) => DrinkTypeDistribution.fromJson(d)).toList();
        }
        return {
          'success': true,
          'distribution': distribution,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch distribution',
          'distribution': [],
        };
      }
    } catch (e) {
      print('🔴 Get distribution error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'distribution': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getTrends({int weeks = 12}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'trends': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔵 Getting trends: GET $baseUrl/stats/trends?weeks=$weeks');
      
      final response = await http.get(
        Uri.parse('$baseUrl/stats/trends?weeks=$weeks'),
        headers: headers,
      );

      print('🔵 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<HydrationTrend> trends = [];
        if (data['data'] != null && data['data'] is List) {
          trends = (data['data'] as List)
              .map((t) => HydrationTrend.fromJson(t))
              .toList();
        }
        return {
          'success': true,
          'trends': trends,
          'summary': data['summary'] as Map<String, dynamic>? ?? {},
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch trends',
          'trends': [],
        };
      }
    } catch (e) {
      print('🔴 Get trends error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'trends': [],
      };
    }
  }
}