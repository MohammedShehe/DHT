import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/api_config.dart';
import '../models/gamification_models.dart';

class GoalService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Helper function to safely convert dynamic to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper function to safely convert dynamic to int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

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

  // ===== GOAL MANAGEMENT =====

  // Create a new goal
  static Future<Map<String, dynamic>> createGoal({
    required GoalType type,
    required double targetValue,
    required GoalPeriod period,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      String endpoint;
      Map<String, dynamic> body;
      
      // Map to correct endpoint and body format based on goal type
      switch (type) {
        case GoalType.steps:
          endpoint = '$baseUrl/steps/set';
          body = {'daily_target': targetValue.toInt()};
          break;
        case GoalType.water:
          endpoint = '$baseUrl/water/set';
          body = {'daily_target': targetValue.toInt()};
          break;
        case GoalType.sleep:
          endpoint = '$baseUrl/sleep/set';
          body = {'daily_target': targetValue.toInt()};
          break;
        case GoalType.meditation:
          endpoint = '$baseUrl/meditation/set';
          body = {'daily_target': targetValue.toInt()};
          break;
        case GoalType.workouts:
          endpoint = '$baseUrl/workouts/set';
          body = {'weekly_target': targetValue.toInt()};
          break;
        case GoalType.calories:
          endpoint = '$baseUrl/calories/set';
          body = {'monthly_target': targetValue.toInt()};
          break;
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse goal directly from response
        Goal? newGoal = _parseGoalFromResponse(type, data);
        
        // If we couldn't parse from response, create a basic goal
        if (newGoal == null) {
          newGoal = Goal(
            id: '${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}',
            type: type,
            targetValue: targetValue,
            period: period,
            currentValue: 0,
            createdAt: DateTime.now(),
            status: GoalStatus.active,
          );
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Goal created successfully',
          'goal': newGoal,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create goal',
        };
      }
    } catch (e) {
      debugPrint('Create goal error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get all goals
  static Future<Map<String, dynamic>> getGoals() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'goals': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      List<Goal> allGoals = [];

      // Fetch goals from each endpoint
      final endpoints = [
        {'type': GoalType.steps, 'url': '$baseUrl/steps'},
        {'type': GoalType.water, 'url': '$baseUrl/water'},
        {'type': GoalType.sleep, 'url': '$baseUrl/sleep'},
        {'type': GoalType.meditation, 'url': '$baseUrl/meditation'},
        {'type': GoalType.workouts, 'url': '$baseUrl/workouts'},
        {'type': GoalType.calories, 'url': '$baseUrl/calories'},
      ];

      for (var endpoint in endpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint['url'] as String),
            headers: headers,
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            // Parse based on goal type
            Goal? goal = _parseGoalFromResponse(
              endpoint['type'] as GoalType, 
              data
            );
            
            if (goal != null) {
              allGoals.add(goal);
            }
          }
          // Skip 404 errors (no goal set)
        } catch (e) {
          // Log error but continue with other endpoints
          debugPrint('Error fetching ${endpoint['type']} goal: $e');
        }
      }

      return {
        'success': true,
        'goals': allGoals,
      };
    } catch (e) {
      debugPrint('Get goals error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'goals': [],
      };
    }
  }

  // Get a specific goal by type
  static Future<Map<String, dynamic>> getGoalByType(GoalType type) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'goal': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      String endpoint;
      switch (type) {
        case GoalType.steps:
          endpoint = '$baseUrl/steps';
          break;
        case GoalType.water:
          endpoint = '$baseUrl/water';
          break;
        case GoalType.sleep:
          endpoint = '$baseUrl/sleep';
          break;
        case GoalType.meditation:
          endpoint = '$baseUrl/meditation';
          break;
        case GoalType.workouts:
          endpoint = '$baseUrl/workouts';
          break;
        case GoalType.calories:
          endpoint = '$baseUrl/calories';
          break;
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final goal = _parseGoalFromResponse(type, data);
        
        return {
          'success': true,
          'goal': goal,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No goal set',
          'goal': null,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch goal',
          'goal': null,
        };
      }
    } catch (e) {
      debugPrint('Get goal by type error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'goal': null,
      };
    }
  }

  // Update goal progress
  static Future<Map<String, dynamic>> updateGoalProgress({
    required GoalType type,
    required double currentValue,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      String endpoint;
      Map<String, dynamic> body;
      
      switch (type) {
        case GoalType.steps:
          endpoint = '$baseUrl/steps/log';
          body = {'steps': currentValue.toInt()};
          break;
        case GoalType.water:
          endpoint = '$baseUrl/water/log';
          body = {'glasses': currentValue.toInt()};
          break;
        case GoalType.sleep:
          endpoint = '$baseUrl/sleep/log';
          body = {'hours': currentValue};
          break;
        case GoalType.meditation:
          endpoint = '$baseUrl/meditation/log';
          body = {'minutes': currentValue.toInt()};
          break;
        case GoalType.workouts:
          endpoint = '$baseUrl/workouts/log';
          body = {'workouts': currentValue.toInt()};
          break;
        case GoalType.calories:
          endpoint = '$baseUrl/calories/log';
          body = {'calories': currentValue.toInt()};
          break;
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Progress updated successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update progress',
        };
      }
    } catch (e) {
      debugPrint('Update goal progress error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Delete a goal - FIXED ENDPOINTS
  static Future<Map<String, dynamic>> deleteGoal(GoalType type) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      String endpoint;
      switch (type) {
        case GoalType.steps:
          endpoint = '$baseUrl/steps';
          break;
        case GoalType.water:
          endpoint = '$baseUrl/water';
          break;
        case GoalType.sleep:
          endpoint = '$baseUrl/sleep';
          break;
        case GoalType.meditation:
          endpoint = '$baseUrl/meditation';
          break;
        case GoalType.workouts:
          endpoint = '$baseUrl/workouts';
          break;
        case GoalType.calories:
          endpoint = '$baseUrl/calories';
          break;
      }

      debugPrint('Deleting goal at endpoint: $endpoint'); // For debugging
      
      final response = await http.delete(
        Uri.parse(endpoint),
        headers: headers,
      );

      final data = json.decode(response.body);
      
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
      debugPrint('Delete goal error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Helper method to parse goal responses
  static Goal? _parseGoalFromResponse(GoalType type, Map<String, dynamic> data) {
    try {
      // Generate a consistent ID - use timestamp to ensure uniqueness
      final String id = '${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}';
      
      switch (type) {
        case GoalType.steps:
          // Check if this is a goal response or progress response
          if (data.containsKey('daily_target')) {
            return Goal(
              id: id,
              type: type,
              targetValue: _toDouble(data['daily_target']),
              period: GoalPeriod.daily,
              currentValue: _toDouble(data['walked_today']),
              createdAt: DateTime.now(),
              status: data['completed'] == true ? GoalStatus.completed : GoalStatus.active,
            );
          }
          break;
        
        case GoalType.water:
          if (data.containsKey('daily_target')) {
            return Goal(
              id: id,
              type: type,
              targetValue: _toDouble(data['daily_target']),
              period: GoalPeriod.daily,
              currentValue: _toDouble(data['glasses_taken_today']),
              createdAt: DateTime.now(),
              status: data['completed'] == true ? GoalStatus.completed : GoalStatus.active,
            );
          }
          break;
        
        case GoalType.sleep:
          if (data.containsKey('daily_target')) {
            return Goal(
              id: id,
              type: type,
              targetValue: _toDouble(data['daily_target']),
              period: GoalPeriod.daily,
              currentValue: _toDouble(data['sleep_logged_today']),
              createdAt: DateTime.now(),
              status: data['completed'] == true ? GoalStatus.completed : GoalStatus.active,
            );
          }
          break;
        
        case GoalType.meditation:
          if (data.containsKey('daily_target')) {
            return Goal(
              id: id,
              type: type,
              targetValue: _toDouble(data['daily_target']),
              period: GoalPeriod.daily,
              currentValue: _toDouble(data['meditation_minutes_today']),
              createdAt: DateTime.now(),
              status: data['completed'] == true ? GoalStatus.completed : GoalStatus.active,
            );
          }
          break;
        
        case GoalType.workouts:
          if (data.containsKey('weekly_target')) {
            return Goal(
              id: id,
              type: type,
              targetValue: _toDouble(data['weekly_target']),
              period: GoalPeriod.weekly,
              currentValue: _toDouble(data['workouts_completed_this_week']),
              createdAt: DateTime.now(),
              status: data['completed'] == true ? GoalStatus.completed : GoalStatus.active,
            );
          }
          break;
        
        case GoalType.calories:
          if (data.containsKey('monthly_target')) {
            return Goal(
              id: id,
              type: type,
              targetValue: _toDouble(data['monthly_target']),
              period: GoalPeriod.monthly,
              currentValue: _toDouble(data['calories_logged_this_month']),
              createdAt: DateTime.now(),
              status: data['completed'] == true ? GoalStatus.completed : GoalStatus.active,
            );
          }
          break;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error parsing $type goal: $e');
      return null;
    }
  }

  // ===== PROGRESS CHECKING =====

  // Get steps progress
  static Future<Map<String, dynamic>> getStepsProgress() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/steps'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch steps progress',
        };
      }
    } catch (e) {
      debugPrint('Get steps progress error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get steps logs
  static Future<Map<String, dynamic>> getStepsLogs({int page = 1, int limit = 10}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/steps/logs?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch steps logs',
        };
      }
    } catch (e) {
      debugPrint('Get steps logs error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get water logs
  static Future<Map<String, dynamic>> getWaterLogs({int page = 1, int limit = 10}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/water/logs?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch water logs',
        };
      }
    } catch (e) {
      debugPrint('Get water logs error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get sleep logs
  static Future<Map<String, dynamic>> getSleepLogs({int page = 1, int limit = 10}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/sleep/logs?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch sleep logs',
        };
      }
    } catch (e) {
      debugPrint('Get sleep logs error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get meditation logs
  static Future<Map<String, dynamic>> getMeditationLogs({int page = 1, int limit = 10}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/meditation/logs?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch meditation logs',
        };
      }
    } catch (e) {
      debugPrint('Get meditation logs error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get workout logs
  static Future<Map<String, dynamic>> getWorkoutLogs({int page = 1, int limit = 10}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/workouts/logs?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch workout logs',
        };
      }
    } catch (e) {
      debugPrint('Get workout logs error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get calorie logs
  static Future<Map<String, dynamic>> getCalorieLogs({int page = 1, int limit = 10}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/calories/logs?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch calorie logs',
        };
      }
    } catch (e) {
      debugPrint('Get calorie logs error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== LOGGING ACTIVITIES =====

  // Log steps
  static Future<Map<String, dynamic>> logSteps(int steps) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/steps/log'),
        headers: headers,
        body: json.encode({'steps': steps}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Steps logged successfully',
          'walked_today': _toInt(data['walked_today']),
          'remaining_steps': _toInt(data['remaining_steps']),
          'completed': data['completed'] ?? false,
          'percentage': _toInt(data['percentage']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log steps',
        };
      }
    } catch (e) {
      debugPrint('Log steps error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Log water
  static Future<Map<String, dynamic>> logWater(int glasses) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/water/log'),
        headers: headers,
        body: json.encode({'glasses': glasses}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Water logged successfully',
          'glasses_taken_today': _toInt(data['glasses_taken_today']),
          'remaining_glasses': _toInt(data['remaining_glasses']),
          'completed': data['completed'] ?? false,
          'percentage': _toInt(data['percentage']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log water',
        };
      }
    } catch (e) {
      debugPrint('Log water error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Log sleep
  static Future<Map<String, dynamic>> logSleep(double hours) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/sleep/log'),
        headers: headers,
        body: json.encode({'hours': hours}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Sleep logged successfully',
          'sleep_logged_today': _toDouble(data['sleep_logged_today']),
          'remaining_hours': _toDouble(data['remaining_hours']),
          'completed': data['completed'] ?? false,
          'percentage': _toInt(data['percentage']),
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

  // Log meditation
  static Future<Map<String, dynamic>> logMeditation(int minutes) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/meditation/log'),
        headers: headers,
        body: json.encode({'minutes': minutes}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Meditation logged successfully',
          'meditation_minutes_today': _toInt(data['meditation_minutes_today']),
          'remaining_minutes': _toInt(data['remaining_minutes']),
          'completed': data['completed'] ?? false,
          'percentage': _toInt(data['percentage']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log meditation',
        };
      }
    } catch (e) {
      debugPrint('Log meditation error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Log workouts
  static Future<Map<String, dynamic>> logWorkouts(int workouts) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/workouts/log'),
        headers: headers,
        body: json.encode({'workouts': workouts}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Workout logged successfully',
          'workouts_completed_this_week': _toInt(data['workouts_completed_this_week']),
          'remaining_workouts': _toInt(data['remaining_workouts']),
          'completed': data['completed'] ?? false,
          'percentage': _toInt(data['percentage']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log workout',
        };
      }
    } catch (e) {
      debugPrint('Log workouts error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Log calories
  static Future<Map<String, dynamic>> logCalories(int calories) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/calories/log'),
        headers: headers,
        body: json.encode({'calories': calories}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Calories logged successfully',
          'calories_logged_this_month': _toInt(data['calories_logged_this_month']),
          'remaining_calories': _toInt(data['remaining_calories']),
          'completed': data['completed'] ?? false,
          'percentage': _toInt(data['percentage']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log calories',
        };
      }
    } catch (e) {
      debugPrint('Log calories error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== UPDATE/DELETE LOGS =====

  // Update step log
  static Future<Map<String, dynamic>> updateStepLog(String logId, int steps) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/steps/log/$logId'),
        headers: headers,
        body: json.encode({'steps': steps}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Step log updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update step log',
        };
      }
    } catch (e) {
      debugPrint('Update step log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Update water log
  static Future<Map<String, dynamic>> updateWaterLog(String logId, int glasses) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/water/log/$logId'),
        headers: headers,
        body: json.encode({'glasses': glasses}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Water log updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update water log',
        };
      }
    } catch (e) {
      debugPrint('Update water log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Update sleep log
  static Future<Map<String, dynamic>> updateSleepLog(String logId, double hours) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/sleep/log/$logId'),
        headers: headers,
        body: json.encode({'hours': hours}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Sleep log updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update sleep log',
        };
      }
    } catch (e) {
      debugPrint('Update sleep log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Update meditation log
  static Future<Map<String, dynamic>> updateMeditationLog(String logId, int minutes) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/meditation/log/$logId'),
        headers: headers,
        body: json.encode({'minutes': minutes}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Meditation log updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update meditation log',
        };
      }
    } catch (e) {
      debugPrint('Update meditation log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Update workout log
  static Future<Map<String, dynamic>> updateWorkoutLog(String logId, int workouts) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/workouts/log/$logId'),
        headers: headers,
        body: json.encode({'workouts': workouts}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Workout log updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update workout log',
        };
      }
    } catch (e) {
      debugPrint('Update workout log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Update calorie log
  static Future<Map<String, dynamic>> updateCalorieLog(String logId, int calories) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/calories/log/$logId'),
        headers: headers,
        body: json.encode({'calories': calories}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Calorie log updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update calorie log',
        };
      }
    } catch (e) {
      debugPrint('Update calorie log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Delete step log
  static Future<Map<String, dynamic>> deleteStepLog(String logId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/steps/log/$logId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Step log deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete step log',
        };
      }
    } catch (e) {
      debugPrint('Delete step log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Delete water log
  static Future<Map<String, dynamic>> deleteWaterLog(String logId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/water/log/$logId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Water log deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete water log',
        };
      }
    } catch (e) {
      debugPrint('Delete water log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Delete sleep log
  static Future<Map<String, dynamic>> deleteSleepLog(String logId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/sleep/log/$logId'),
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

  // Delete meditation log
  static Future<Map<String, dynamic>> deleteMeditationLog(String logId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/meditation/log/$logId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Meditation log deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete meditation log',
        };
      }
    } catch (e) {
      debugPrint('Delete meditation log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Delete workout log
  static Future<Map<String, dynamic>> deleteWorkoutLog(String logId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/workouts/log/$logId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Workout log deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete workout log',
        };
      }
    } catch (e) {
      debugPrint('Delete workout log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Delete calorie log
  static Future<Map<String, dynamic>> deleteCalorieLog(String logId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/calories/log/$logId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Calorie log deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete calorie log',
        };
      }
    } catch (e) {
      debugPrint('Delete calorie log error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== RESET DATA =====

  // Reset daily steps
  static Future<Map<String, dynamic>> resetDailySteps() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/steps/reset/daily'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Daily steps reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset steps',
        };
      }
    } catch (e) {
      debugPrint('Reset daily steps error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Reset daily water
  static Future<Map<String, dynamic>> resetDailyWater() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/water/reset/daily'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Daily water reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset water',
        };
      }
    } catch (e) {
      debugPrint('Reset daily water error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Reset daily sleep
  static Future<Map<String, dynamic>> resetDailySleep() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/sleep/reset/daily'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Daily sleep reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset sleep',
        };
      }
    } catch (e) {
      debugPrint('Reset daily sleep error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Reset daily meditation
  static Future<Map<String, dynamic>> resetDailyMeditation() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/meditation/reset/daily'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Daily meditation reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset meditation',
        };
      }
    } catch (e) {
      debugPrint('Reset daily meditation error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Reset weekly workouts
  static Future<Map<String, dynamic>> resetWeeklyWorkouts() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/workouts/reset/weekly'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Weekly workouts reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset workouts',
        };
      }
    } catch (e) {
      debugPrint('Reset weekly workouts error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Reset monthly calories
  static Future<Map<String, dynamic>> resetMonthlyCalories() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/calories/reset/monthly'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Monthly calories reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset calories',
        };
      }
    } catch (e) {
      debugPrint('Reset monthly calories error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}