import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../utils/api_config.dart';
import '../models/workout_detail_models.dart';

// Helper functions for safe type conversion
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class WorkoutDetailService {
  static String get baseUrl => '${ApiConfig.baseUrl}/workout-details';

  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) return true;
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Helper to format date for API (YYYY-MM-DD in local timezone)
  static String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<Map<String, dynamic>> getWorkoutTypes() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'types': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/types'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<WorkoutType> types = [];
        final Set<int> addedIds = {};
        
        if (data is List) {
          for (var item in data) {
            try {
              final id = _toInt(item['id']);
              if (!addedIds.contains(id)) {
                addedIds.add(id);
                types.add(WorkoutType(
                  id: id,
                  name: item['name']?.toString() ?? '',
                  isCustom: item['is_custom'] == 1 || item['is_custom'] == true || item['is_custom'] == '1',
                  createdBy: _toIntNullable(item['created_by']),
                ));
              }
            } catch (e) {
              debugPrint('Error parsing workout type: $e');
            }
          }
        }
        return {
          'success': true,
          'types': types,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch workout types',
          'types': [],
        };
      }
    } catch (e) {
      debugPrint('Get workout types error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'types': [],
      };
    }
  }

  static Future<Map<String, dynamic>> createWorkoutType(String name) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/types'),
        headers: headers,
        body: json.encode({'name': name}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        WorkoutType? workoutType;
        if (data['workout_type'] != null) {
          final wt = data['workout_type'];
          workoutType = WorkoutType(
            id: _toInt(wt['id']),
            name: wt['name']?.toString() ?? '',
            isCustom: wt['is_custom'] == 1 || wt['is_custom'] == true || wt['is_custom'] == '1',
            createdBy: _toIntNullable(wt['created_by']),
          );
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Workout type created',
          'workout_type': workoutType,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create workout type',
        };
      }
    } catch (e) {
      debugPrint('Create workout type error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteWorkoutType(int typeId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/types/$typeId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Workout type deleted',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete workout type',
        };
      }
    } catch (e) {
      debugPrint('Delete workout type error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> logWorkout(CreateWorkoutRequest request) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        WorkoutDetail? workout;
        if (data['workout'] != null) {
          final w = data['workout'];
          workout = WorkoutDetail.fromJson(w);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Workout logged successfully',
          'workout': workout,
          'calories_burned': _toIntNullable(data['calories_burned']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log workout',
        };
      }
    } catch (e) {
      debugPrint('Log workout error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getWorkouts({
    DateTime? startDate,
    DateTime? endDate,
    String? intensity,
    int? workoutTypeId,
    int? limit,
    int? offset,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'workouts': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      String url = baseUrl;
      final params = <String, String>{};
      
      // Format dates for API (YYYY-MM-DD)
      if (startDate != null) params['start_date'] = _formatDateForApi(startDate);
      if (endDate != null) params['end_date'] = _formatDateForApi(endDate);
      if (intensity != null) params['intensity'] = intensity;
      if (workoutTypeId != null) params['workout_type_id'] = workoutTypeId.toString();
      if (limit != null) params['limit'] = limit.toString();
      if (offset != null) params['offset'] = offset.toString();
      
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<WorkoutDetail> workouts = [];
        final Set<int> addedIds = {};
        
        if (data is List) {
          for (var w in data) {
            try {
              final id = _toInt(w['id']);
              if (!addedIds.contains(id)) {
                addedIds.add(id);
                workouts.add(WorkoutDetail.fromJson(w));
              }
            } catch (e) {
              debugPrint('Error parsing workout: $e');
            }
          }
        }
        // Sort by workout time descending (most recent first)
        workouts.sort((a, b) => b.workoutTime.compareTo(a.workoutTime));
        return {
          'success': true,
          'workouts': workouts,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch workouts',
          'workouts': [],
        };
      }
    } catch (e) {
      debugPrint('Get workouts error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'workouts': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getWorkoutById(int id) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'workout': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final workout = WorkoutDetail.fromJson(json.decode(response.body));
        return {
          'success': true,
          'workout': workout,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Workout not found',
          'workout': null,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch workout',
          'workout': null,
        };
      }
    } catch (e) {
      debugPrint('Get workout by ID error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'workout': null,
      };
    }
  }

  static Future<Map<String, dynamic>> updateWorkout(int id, UpdateWorkoutRequest request) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        WorkoutDetail? workout;
        if (data['workout'] != null) {
          workout = WorkoutDetail.fromJson(data['workout']);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Workout updated successfully',
          'workout': workout,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update workout',
        };
      }
    } catch (e) {
      debugPrint('Update workout error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteWorkout(int id) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Workout deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete workout',
        };
      }
    } catch (e) {
      debugPrint('Delete workout error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

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
      final response = await http.get(
        Uri.parse('$baseUrl/stats/daily?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = WorkoutStats(
          workoutCount: _toInt(data['workout_count']),
          totalDuration: _toInt(data['total_duration']),
          totalCalories: _toInt(data['total_calories']),
          totalDistance: _toDouble(data['total_distance']),
          avgHeartRate: _toDoubleNullable(data['avg_heart_rate']),
        );
        return {
          'success': true,
          'stats': stats,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'stats': null,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch daily stats',
          'stats': null,
        };
      }
    } catch (e) {
      debugPrint('Get daily stats error: $e');
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
      final response = await http.get(
        Uri.parse('$baseUrl/stats/weekly?start_date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<WeeklyWorkoutStats> stats = [];
        final Set<String> addedDates = {};
        
        if (data is List) {
          for (var item in data) {
            try {
              final dateStr = item['date'] as String;
              if (!addedDates.contains(dateStr)) {
                addedDates.add(dateStr);
                stats.add(WeeklyWorkoutStats.fromJson(item));
              }
            } catch (e) {
              debugPrint('Error parsing weekly stats item: $e');
            }
          }
        }
        // Sort by date
        stats.sort((a, b) => a.date.compareTo(b.date));
        return {
          'success': true,
          'stats': stats,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'stats': [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch weekly stats',
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

  static Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
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
        Uri.parse('$baseUrl/stats/monthly?year=$year&month=$month'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> stats = [];
        final Set<String> addedDates = {};
        
        if (data is List) {
          for (var item in data) {
            final date = item['date'];
            if (!addedDates.contains(date)) {
              addedDates.add(date);
              stats.add({
                'date': date,
                'workout_count': _toInt(item['workout_count']),
                'total_duration': _toInt(item['total_duration']),
                'total_calories': _toInt(item['total_calories']),
                'total_distance': _toDouble(item['total_distance']),
              });
            }
          }
        }
        return {
          'success': true,
          'stats': stats,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'stats': [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch monthly stats',
          'stats': [],
        };
      }
    } catch (e) {
      debugPrint('Get monthly stats error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'stats': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getIntensityDistribution({
    DateTime? startDate,
    DateTime? endDate,
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
      String url = '$baseUrl/stats/intensity';
      final params = <String, String>{};
      
      if (startDate != null) params['start_date'] = _formatDateForApi(startDate);
      if (endDate != null) params['end_date'] = _formatDateForApi(endDate);
      
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<IntensityDistribution> distribution = [];
        final Set<String> addedIntensities = {};
        
        if (data is List) {
          for (var item in data) {
            try {
              final intensity = item['intensity']?.toString() ?? '';
              if (!addedIntensities.contains(intensity)) {
                addedIntensities.add(intensity);
                distribution.add(IntensityDistribution(
                  intensity: intensity,
                  count: _toInt(item['count']),
                  totalDuration: _toInt(item['total_duration']),
                ));
              }
            } catch (e) {
              debugPrint('Error parsing intensity item: $e');
            }
          }
        }
        return {
          'success': true,
          'distribution': distribution,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'distribution': [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch intensity distribution',
          'distribution': [],
        };
      }
    } catch (e) {
      debugPrint('Get intensity distribution error: $e');
      return {
        'success': true,
        'distribution': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getWorkoutTypeStats({
    DateTime? startDate,
    DateTime? endDate,
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
      String url = '$baseUrl/stats/workout-types';
      final params = <String, String>{};
      
      if (startDate != null) params['start_date'] = _formatDateForApi(startDate);
      if (endDate != null) params['end_date'] = _formatDateForApi(endDate);
      
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<WorkoutTypeStats> stats = [];
        final Set<String> addedWorkouts = {};
        
        if (data is List) {
          for (var item in data) {
            try {
              final workoutName = item['workout_name']?.toString() ?? '';
              if (!addedWorkouts.contains(workoutName)) {
                addedWorkouts.add(workoutName);
                stats.add(WorkoutTypeStats(
                  workoutName: workoutName,
                  count: _toInt(item['count']),
                  totalDuration: _toInt(item['total_duration']),
                  totalCalories: _toInt(item['total_calories']),
                  avgHeartRate: _toDoubleNullable(item['avg_heart_rate']),
                ));
              }
            } catch (e) {
              debugPrint('Error parsing workout type stats item: $e');
            }
          }
        }
        return {
          'success': true,
          'stats': stats,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'stats': [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch workout type stats',
          'stats': [],
        };
      }
    } catch (e) {
      debugPrint('Get workout type stats error: $e');
      return {
        'success': true,
        'stats': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getSummary() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        WorkoutStats? today;
        if (data['today'] != null) {
          final t = data['today'];
          today = WorkoutStats(
            workoutCount: _toInt(t['workout_count']),
            totalDuration: _toInt(t['total_duration']),
            totalCalories: _toInt(t['total_calories']),
            totalDistance: _toDouble(t['total_distance']),
            avgHeartRate: _toDoubleNullable(t['avg_heart_rate']),
          );
        }

        List<WeeklyWorkoutStats> weeklySummary = [];
        final Set<String> addedWeeklyDates = {};
        if (data['weekly_summary'] != null && data['weekly_summary'] is List) {
          for (var item in data['weekly_summary']) {
            try {
              final dateStr = item['date'] as String;
              if (!addedWeeklyDates.contains(dateStr)) {
                addedWeeklyDates.add(dateStr);
                weeklySummary.add(WeeklyWorkoutStats.fromJson(item));
              }
            } catch (e) {
              debugPrint('Error parsing weekly summary item: $e');
            }
          }
        }
        weeklySummary.sort((a, b) => a.date.compareTo(b.date));

        List<IntensityDistribution> intensityDistribution = [];
        final Set<String> addedIntensities = {};
        if (data['intensity_distribution'] != null && data['intensity_distribution'] is List) {
          for (var item in data['intensity_distribution']) {
            try {
              final intensity = item['intensity']?.toString() ?? '';
              if (!addedIntensities.contains(intensity)) {
                addedIntensities.add(intensity);
                intensityDistribution.add(IntensityDistribution(
                  intensity: intensity,
                  count: _toInt(item['count']),
                  totalDuration: _toInt(item['total_duration']),
                ));
              }
            } catch (e) {
              debugPrint('Error parsing intensity item: $e');
            }
          }
        }

        List<WorkoutTypeStats> topWorkouts = [];
        final Set<String> addedTopWorkouts = {};
        if (data['top_workouts'] != null && data['top_workouts'] is List) {
          for (var item in data['top_workouts']) {
            try {
              final workoutName = item['workout_name']?.toString() ?? '';
              if (!addedTopWorkouts.contains(workoutName)) {
                addedTopWorkouts.add(workoutName);
                topWorkouts.add(WorkoutTypeStats(
                  workoutName: workoutName,
                  count: _toInt(item['count']),
                  totalDuration: _toInt(item['total_duration']),
                  totalCalories: _toInt(item['total_calories']),
                  avgHeartRate: _toDoubleNullable(item['avg_heart_rate']),
                ));
              }
            } catch (e) {
              debugPrint('Error parsing top workout item: $e');
            }
          }
        }

        return {
          'success': true,
          'today': today,
          'weekly_summary': weeklySummary,
          'intensity_distribution': intensityDistribution,
          'top_workouts': topWorkouts,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch summary',
        };
      }
    } catch (e) {
      debugPrint('Get summary error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}