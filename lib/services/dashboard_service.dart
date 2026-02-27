import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../utils/api_config.dart';
import '../models/dashboard_models.dart';
import '../models/activity_models.dart';

class DashboardService {
  static String get baseUrl => ApiConfig.baseUrl;

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

  // Helper function to safely convert dynamic to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
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

  // Get complete dashboard summary with REAL data
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'data': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/steps'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/water'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/sleep'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/meditation'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/workouts'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/calories'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/health'), headers: headers).catchError((e) => null),
      ]);

      int stepsToday = 0;
      int stepsGoal = 10000;
      double waterGlasses = 0.0;
      double waterGoal = 8.0;
      double sleepHours = 0.0;
      double sleepGoal = 8.0;
      int meditationMinutes = 0;
      int meditationGoal = 10;
      int workoutsThisWeek = 0;
      int workoutsGoal = 5;
      int caloriesThisMonth = 0;
      int caloriesGoal = 60000;
      int caloriesBurned = 0;
      int currentStreak = 0;
      int totalPoints = 0;
      int level = 1;
      double levelProgress = 0.0;

      // Parse steps
      if (results[0] != null && results[0].statusCode == 200) {
        try {
          final data = json.decode(results[0].body);
          stepsToday = _toInt(data['walked_today']);
          stepsGoal = _toInt(data['daily_target']);
        } catch (e) {
          debugPrint('Error parsing steps: $e');
        }
      }

      // Parse water
      if (results[1] != null && results[1].statusCode == 200) {
        try {
          final data = json.decode(results[1].body);
          waterGlasses = _toDouble(data['glasses_taken_today']);
          waterGoal = _toDouble(data['daily_target']);
        } catch (e) {
          debugPrint('Error parsing water: $e');
        }
      }

      // Parse sleep
      if (results[2] != null && results[2].statusCode == 200) {
        try {
          final data = json.decode(results[2].body);
          sleepHours = _toDouble(data['sleep_logged_today']);
          sleepGoal = _toDouble(data['daily_target']);
        } catch (e) {
          debugPrint('Error parsing sleep: $e');
        }
      }

      // Parse meditation
      if (results[3] != null && results[3].statusCode == 200) {
        try {
          final data = json.decode(results[3].body);
          meditationMinutes = _toInt(data['meditation_minutes_today']);
          meditationGoal = _toInt(data['daily_target']);
        } catch (e) {
          debugPrint('Error parsing meditation: $e');
        }
      }

      // Parse workouts
      if (results[4] != null && results[4].statusCode == 200) {
        try {
          final data = json.decode(results[4].body);
          workoutsThisWeek = _toInt(data['workouts_completed_this_week']);
          workoutsGoal = _toInt(data['weekly_target']);
          caloriesBurned = workoutsThisWeek * 300;
        } catch (e) {
          debugPrint('Error parsing workouts: $e');
        }
      }

      // Parse calories
      if (results[5] != null && results[5].statusCode == 200) {
        try {
          final data = json.decode(results[5].body);
          caloriesThisMonth = _toInt(data['calories_logged_this_month']);
          caloriesGoal = _toInt(data['monthly_target']);
        } catch (e) {
          debugPrint('Error parsing calories: $e');
        }
      }

      final summary = DashboardSummary(
        currentStreak: currentStreak,
        totalPoints: totalPoints,
        level: level,
        levelProgress: levelProgress,
        stepsToday: stepsToday,
        caloriesBurned: caloriesBurned,
        sleepHours: sleepHours,
        waterGlasses: waterGlasses,
        meditationMinutes: meditationMinutes,
        goalsProgress: {
          'steps': {'current': stepsToday, 'goal': stepsGoal},
          'water': {'current': waterGlasses, 'goal': waterGoal},
          'sleep': {'current': sleepHours, 'goal': sleepGoal},
          'meditation': {'current': meditationMinutes, 'goal': meditationGoal},
          'workouts': {'current': workoutsThisWeek, 'goal': workoutsGoal},
          'calories': {'current': caloriesThisMonth, 'goal': caloriesGoal},
        },
      );

      return {
        'success': true,
        'data': summary,
      };

    } catch (e) {
      debugPrint('Dashboard summary error: $e');
      return {
        'success': false,
        'message': 'Failed to load dashboard data',
        'data': null,
      };
    }
  }

  // Get recent activities from logs with proper timestamps
  static Future<Map<String, dynamic>> getRecentActivities({int limit = 10}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'data': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      List<ActivitySummary> activities = [];

      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/steps/logs?page=1&limit=5'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/water/logs?page=1&limit=5'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/sleep/logs?page=1&limit=5'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/meditation/logs?page=1&limit=5'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/workouts/logs?page=1&limit=5'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/calories/logs?page=1&limit=5'), headers: headers).catchError((e) => null),
      ]);

      // Parse steps logs
      if (results[0] != null && results[0].statusCode == 200) {
        try {
          final data = json.decode(results[0].body);
          if (data is List) {
            for (var log in data) {
              DateTime timestamp = _parseTimestamp(log);
              activities.add(ActivitySummary(
                id: log['id'].toString(),
                type: 'steps',
                title: 'Steps Logged',
                subtitle: 'You walked ${_toInt(log['steps'])} steps',
                value: _toInt(log['steps']),
                unit: 'steps',
                timestamp: timestamp,
                icon: Icons.directions_walk,
                color: Colors.blue,
              ));
            }
          }
        } catch (e) {
          debugPrint('Error parsing steps logs: $e');
        }
      }

      // Parse water logs
      if (results[1] != null && results[1].statusCode == 200) {
        try {
          final data = json.decode(results[1].body);
          if (data is List) {
            for (var log in data) {
              DateTime timestamp = _parseTimestamp(log);
              final glasses = _toDouble(log['glasses']);
              activities.add(ActivitySummary(
                id: log['id'].toString(),
                type: 'water',
                title: 'Water Intake',
                subtitle: 'You drank ${glasses.toStringAsFixed(1)} glasses',
                value: glasses.toInt(),
                unit: 'glasses',
                timestamp: timestamp,
                icon: Icons.local_drink,
                color: Colors.cyan,
              ));
            }
          }
        } catch (e) {
          debugPrint('Error parsing water logs: $e');
        }
      }

      // Parse sleep logs
      if (results[2] != null && results[2].statusCode == 200) {
        try {
          final data = json.decode(results[2].body);
          if (data is List) {
            for (var log in data) {
              DateTime timestamp = _parseTimestamp(log);
              final hours = _toDouble(log['hours']);
              activities.add(ActivitySummary(
                id: log['id'].toString(),
                type: 'sleep',
                title: 'Sleep Logged',
                subtitle: 'You slept ${hours.toStringAsFixed(1)} hours',
                value: hours.toInt(),
                unit: 'hours',
                timestamp: timestamp,
                icon: Icons.bedtime,
                color: Colors.purple,
              ));
            }
          }
        } catch (e) {
          debugPrint('Error parsing sleep logs: $e');
        }
      }

      // Parse meditation logs
      if (results[3] != null && results[3].statusCode == 200) {
        try {
          final data = json.decode(results[3].body);
          if (data is List) {
            for (var log in data) {
              DateTime timestamp = _parseTimestamp(log);
              activities.add(ActivitySummary(
                id: log['id'].toString(),
                type: 'meditation',
                title: 'Meditation Session',
                subtitle: 'You meditated for ${_toInt(log['minutes'])} minutes',
                value: _toInt(log['minutes']),
                unit: 'min',
                timestamp: timestamp,
                icon: Icons.self_improvement,
                color: Colors.indigo,
              ));
            }
          }
        } catch (e) {
          debugPrint('Error parsing meditation logs: $e');
        }
      }

      // Parse workout logs
      if (results[4] != null && results[4].statusCode == 200) {
        try {
          final data = json.decode(results[4].body);
          if (data is List) {
            for (var log in data) {
              DateTime timestamp = _parseTimestamp(log);
              activities.add(ActivitySummary(
                id: log['id'].toString(),
                type: 'workout',
                title: 'Workout Completed',
                subtitle: '${_toInt(log['workouts'])} workout(s)',
                value: _toInt(log['workouts']),
                unit: 'workouts',
                timestamp: timestamp,
                icon: Icons.fitness_center,
                color: Colors.green,
              ));
            }
          }
        } catch (e) {
          debugPrint('Error parsing workout logs: $e');
        }
      }

      // Parse calorie logs
      if (results[5] != null && results[5].statusCode == 200) {
        try {
          final data = json.decode(results[5].body);
          if (data is List) {
            for (var log in data) {
              DateTime timestamp = _parseTimestamp(log);
              activities.add(ActivitySummary(
                id: log['id'].toString(),
                type: 'meal',
                title: 'Meal Logged',
                subtitle: '${_toInt(log['calories'])} calories consumed',
                value: _toInt(log['calories']),
                unit: 'kcal',
                timestamp: timestamp,
                icon: Icons.restaurant,
                color: Colors.orange,
              ));
            }
          }
        } catch (e) {
          debugPrint('Error parsing calorie logs: $e');
        }
      }

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (activities.length > limit) {
        activities = activities.sublist(0, limit);
      }

      return {
        'success': true,
        'data': activities,
      };

    } catch (e) {
      debugPrint('Recent activities error: $e');
      return {
        'success': false,
        'message': 'Failed to load recent activities',
        'data': [],
      };
    }
  }

  // Helper method to parse timestamp from log entry
  static DateTime _parseTimestamp(Map<String, dynamic> log) {
    try {
      // First try to use created_at which has full timestamp
      if (log['created_at'] != null) {
        return DateTime.parse(log['created_at']);
      }
      
      // Fallback to log_date
      if (log['log_date'] != null) {
        final dateStr = log['log_date'].toString();
        
        // Handle ISO datetime string
        if (dateStr.contains('T')) {
          return DateTime.parse(dateStr);
        }
        
        // Handle simple date string (YYYY-MM-DD)
        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          // Set to noon to avoid timezone shifting to previous day
          return DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            12, 0, 0
          );
        }
      }
      
      return DateTime.now();
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
      return DateTime.now();
    }
  }

  // Get health tips
  static Future<Map<String, dynamic>> getHealthTips() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'data': _getDefaultHealthTips(),
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/health/tips'),
        headers: headers,
      ).catchError((e) => null);

      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['tips'] != null) {
          final tips = (data['tips'] as List)
              .map((tip) => HealthTip.fromJson(tip))
              .toList();
          return {
            'success': true,
            'data': tips,
          };
        }
      }

      return {
        'success': true,
        'data': _getDefaultHealthTips(),
      };

    } catch (e) {
      debugPrint('Health tips error: $e');
      return {
        'success': true,
        'data': _getDefaultHealthTips(),
      };
    }
  }

  static List<HealthTip> _getDefaultHealthTips() {
    return [
      HealthTip(
        id: '1',
        title: 'Stay Hydrated',
        description: 'Drink at least 8 glasses of water daily for optimal health',
        icon: Icons.local_drink,
        color: Colors.blue,
        action: 'open_hydration',
      ),
      HealthTip(
        id: '2',
        title: 'Move More',
        description: 'Take short breaks to walk every hour to improve circulation',
        icon: Icons.directions_walk,
        color: Colors.green,
        action: 'open_activity',
      ),
      HealthTip(
        id: '3',
        title: 'Quality Sleep',
        description: 'Aim for 7-9 hours of sleep each night for recovery',
        icon: Icons.bedtime,
        color: Colors.purple,
        action: 'open_sleep',
      ),
      HealthTip(
        id: '4',
        title: 'Mindfulness',
        description: 'Take 5 minutes to meditate and reduce stress',
        icon: Icons.self_improvement,
        color: Colors.indigo,
        action: 'open_meditation',
      ),
      HealthTip(
        id: '5',
        title: 'Track Your Meals',
        description: 'Logging meals helps you understand your nutrition',
        icon: Icons.restaurant,
        color: Colors.orange,
        action: 'open_meal',
      ),
    ];
  }

  // Get quick actions
  static List<Map<String, dynamic>> getQuickActions() {
    return [
      {'icon': Icons.add, 'label': 'Log Activity', 'color': Colors.blue, 'route': '/activity'},
      {'icon': Icons.restaurant, 'label': 'Log Meal', 'color': Colors.green, 'route': '/activity?tab=0'},
      {'icon': Icons.local_drink, 'label': 'Log Water', 'color': Colors.cyan, 'route': '/activity?tab=3'},
      {'icon': Icons.medication, 'label': 'Medication', 'color': Colors.purple, 'route': '/activity?tab=4'},
      {'icon': Icons.bedtime, 'label': 'Sleep', 'color': Colors.indigo, 'route': '/activity?tab=2'},
      {'icon': Icons.emoji_events, 'label': 'Goals', 'color': Colors.amber, 'route': '/gamification'},
    ];
  }

  // Get weekly summary for charts
  static Future<Map<String, dynamic>> getWeeklySummary() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'data': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
      
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/steps/logs?page=1&limit=100'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/water/logs?page=1&limit=100'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/sleep/logs?page=1&limit=100'), headers: headers).catchError((e) => null),
        http.get(Uri.parse('$baseUrl/meditation/logs?page=1&limit=100'), headers: headers).catchError((e) => null),
      ]);

      List<double> stepsData = List.filled(7, 0.0);
      List<double> waterData = List.filled(7, 0.0);
      List<double> sleepData = List.filled(7, 0.0);
      List<double> meditationData = List.filled(7, 0.0);
      
      DateTime startDate = sevenDaysAgo;
      
      debugPrint('Weekly Summary - Date range: ${sevenDaysAgo.toIso8601String()} to ${todayStart.toIso8601String()}');
      
      // Parse steps
      if (results[0] != null && results[0].statusCode == 200) {
        try {
          final data = json.decode(results[0].body);
          debugPrint('Steps logs received: ${data.length} entries');
          
          if (data is List) {
            for (var log in data) {
              if (log['log_date'] != null) {
                final logDateStr = log['log_date'];
                
                DateTime logDate;
                try {
                  logDate = DateTime.parse(logDateStr);
                } catch (e) {
                  final dateParts = logDateStr.split('T')[0].split('-');
                  if (dateParts.length == 3) {
                    logDate = DateTime(
                      int.parse(dateParts[0]), 
                      int.parse(dateParts[1]), 
                      int.parse(dateParts[2])
                    );
                  } else {
                    continue;
                  }
                }
                
                final daysDiff = logDate.difference(startDate).inDays;
                
                debugPrint('Steps log date: $logDateStr, parsed: ${logDate.toIso8601String()}, Days diff: $daysDiff');
                
                if (daysDiff >= 0 && daysDiff < 7) {
                  stepsData[daysDiff] += _toInt(log['steps']).toDouble();
                  debugPrint('Added steps to index $daysDiff: ${_toInt(log['steps'])} steps, total now: ${stepsData[daysDiff]}');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing steps for weekly: $e');
        }
      }

      // Parse water
      if (results[1] != null && results[1].statusCode == 200) {
        try {
          final data = json.decode(results[1].body);
          if (data is List) {
            for (var log in data) {
              if (log['log_date'] != null) {
                final logDateStr = log['log_date'];
                
                DateTime logDate;
                try {
                  logDate = DateTime.parse(logDateStr);
                } catch (e) {
                  final dateParts = logDateStr.split('T')[0].split('-');
                  if (dateParts.length == 3) {
                    logDate = DateTime(
                      int.parse(dateParts[0]), 
                      int.parse(dateParts[1]), 
                      int.parse(dateParts[2])
                    );
                  } else {
                    continue;
                  }
                }
                
                final daysDiff = logDate.difference(startDate).inDays;
                
                if (daysDiff >= 0 && daysDiff < 7) {
                  waterData[daysDiff] += _toDouble(log['glasses']);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing water for weekly: $e');
        }
      }

      // Parse sleep
      if (results[2] != null && results[2].statusCode == 200) {
        try {
          final data = json.decode(results[2].body);
          if (data is List) {
            for (var log in data) {
              if (log['log_date'] != null) {
                final logDateStr = log['log_date'];
                
                DateTime logDate;
                try {
                  logDate = DateTime.parse(logDateStr);
                } catch (e) {
                  final dateParts = logDateStr.split('T')[0].split('-');
                  if (dateParts.length == 3) {
                    logDate = DateTime(
                      int.parse(dateParts[0]), 
                      int.parse(dateParts[1]), 
                      int.parse(dateParts[2])
                    );
                  } else {
                    continue;
                  }
                }
                
                final daysDiff = logDate.difference(startDate).inDays;
                
                if (daysDiff >= 0 && daysDiff < 7) {
                  sleepData[daysDiff] += _toDouble(log['hours']);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing sleep for weekly: $e');
        }
      }

      // Parse meditation
      if (results[3] != null && results[3].statusCode == 200) {
        try {
          final data = json.decode(results[3].body);
          if (data is List) {
            for (var log in data) {
              if (log['log_date'] != null) {
                final logDateStr = log['log_date'];
                
                DateTime logDate;
                try {
                  logDate = DateTime.parse(logDateStr);
                } catch (e) {
                  final dateParts = logDateStr.split('T')[0].split('-');
                  if (dateParts.length == 3) {
                    logDate = DateTime(
                      int.parse(dateParts[0]), 
                      int.parse(dateParts[1]), 
                      int.parse(dateParts[2])
                    );
                  } else {
                    continue;
                  }
                }
                
                final daysDiff = logDate.difference(startDate).inDays;
                
                if (daysDiff >= 0 && daysDiff < 7) {
                  meditationData[daysDiff] += _toInt(log['minutes']).toDouble();
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing meditation for weekly: $e');
        }
      }

      List<String> dayLabels = [];
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final weekday = date.weekday;
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dayLabels.add(days[weekday - 1]);
      }

      bool hasStepsData = stepsData.any((value) => value > 0);
      debugPrint('Final steps data: $stepsData, hasData: $hasStepsData');

      return {
        'success': true,
        'data': {
          'steps': stepsData,
          'water': waterData,
          'sleep': sleepData,
          'meditation': meditationData,
          'labels': dayLabels,
          'hasData': hasStepsData,
        },
      };

    } catch (e) {
      debugPrint('Weekly summary error: $e');
      return {
        'success': false,
        'message': 'Failed to load weekly summary',
        'data': null,
      };
    }
  }
}