import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';
import '../models/activity_models.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';

class ActivityService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _sharedPreferences;
  static String? _token;

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

  static Future<Map<String, String>> getMultipartHeaders() async {
    if (_token == null) {
      await initializeToken();
    }
    
    if (_token == null) {
      throw Exception('No authentication token found');
    }
    
    return {
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

  // ==================== MEAL ENDPOINTS ====================

  static Future<List<Meal>> getMeals(DateTime date) async {
    try {
      final headers = await getAuthHeaders();
      final formattedDate = date.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/meals?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'] is List) {
          return (data['meals'] as List)
              .map((meal) => Meal.fromJson(meal))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get meals error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> saveMeal(CreateMealRequest request) async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/meals'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': true,
          'message': data['message'] ?? 'Meal logged successfully',
          'meal': data['meal'] != null ? Meal.fromJson(data['meal']) : null,
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save meal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateMeal(int mealId, UpdateMealRequest request) async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/meals/$mealId'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': true,
          'message': data['message'] ?? 'Meal updated successfully',
          'meal': data['meal'] != null ? Meal.fromJson(data['meal']) : null,
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update meal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteMeal(int mealId) async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/meals/$mealId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': true,
          'message': data['message'] ?? 'Meal deleted successfully',
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete meal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ==================== WORKOUT ENDPOINTS ====================

  static Future<List<Workout>> getWorkouts(DateTime date) async {
    try {
      final headers = await getAuthHeaders();
      final formattedDate = date.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/workouts?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['workouts'] as List)
            .map((workout) => Workout.fromJson(workout))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveWorkout(Workout workout) async {
    final headers = await getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/workouts'),
      headers: headers,
      body: json.encode(workout.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save workout');
    }
  }

  static Future<void> updateWorkout(Workout workout) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/workouts/${workout.id}'),
      headers: headers,
      body: json.encode(workout.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update workout');
    }
  }

  static Future<void> deleteWorkout(String workoutId) async {
    final headers = await getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/workouts/$workoutId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete workout');
    }
  }

  // ==================== SLEEP ENDPOINTS ====================

  static Future<List<Sleep>> getSleep(DateTime date) async {
    try {
      final headers = await getAuthHeaders();
      final formattedDate = date.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/sleep?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['sleep'] as List)
            .map((sleep) => Sleep.fromJson(sleep))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveSleep(Sleep sleep) async {
    final headers = await getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/sleep'),
      headers: headers,
      body: json.encode(sleep.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save sleep record');
    }
  }

  static Future<void> updateSleep(Sleep sleep) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/sleep/${sleep.id}'),
      headers: headers,
      body: json.encode(sleep.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update sleep record');
    }
  }

  static Future<void> deleteSleep(String sleepId) async {
    final headers = await getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/sleep/$sleepId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete sleep record');
    }
  }

  // ==================== HYDRATION ENDPOINTS ====================

  static Future<List<Hydration>> getHydration(DateTime date) async {
    try {
      final headers = await getAuthHeaders();
      final formattedDate = date.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/water?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['hydrations'] as List)
            .map((h) => Hydration.fromJson(h))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHydration(Hydration hydration) async {
    final headers = await getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/water/log'),
      headers: headers,
      body: json.encode({'glasses': hydration.amount ~/ 250}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save hydration record');
    }
  }

  static Future<void> updateHydration(Hydration hydration) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/water/log/${hydration.id}'),
      headers: headers,
      body: json.encode({'glasses': hydration.amount ~/ 250}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update hydration record');
    }
  }

  static Future<void> deleteHydration(String hydrationId) async {
    final headers = await getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/water/log/$hydrationId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hydration record');
    }
  }

  // ==================== MEDICATION ENDPOINTS ====================

  static Future<List<Medication>> getMedications() async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications'),
        headers: headers,
      );

      debugPrint('📋 Get medications response: ${response.statusCode}');
      debugPrint('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final medications = data.map((m) => Medication.fromJson(m)).toList();
          debugPrint('✅ Loaded ${medications.length} medications');
          return medications;
        }
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ Medications endpoint returned 404');
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get medications error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createMedication(Map<String, dynamic> medicationData) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await getAuthHeaders();
      
      final requestBody = {
        'name': medicationData['name'],
        'dosage': double.parse(medicationData['dosage'].toString()),
        'unit': medicationData['unit'] ?? 'mg',
        'color': medicationData['color'] ?? '#3B82F6',
        'start_date': medicationData['start_date']?.split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
        'end_date': medicationData['end_date'] != null 
            ? medicationData['end_date'].split('T')[0] 
            : null,
        'instructions': medicationData['instructions'],
        'prescribed_by': medicationData['prescribed_by'],
        'notes': medicationData['notes'],
        'schedules': (medicationData['scheduled_times'] as List).map((time) {
          return {
            'time_of_day': time.toIso8601String().split('T')[1].substring(0, 8),
            'days_of_week': 'all',
          };
        }).toList(),
      };
      
      debugPrint('Creating medication: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/medications'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Medication created successfully',
          'medication': data['medication'] != null 
              ? Medication.fromJson(data['medication']) 
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create medication',
        };
      }
    } catch (e) {
      debugPrint('Create medication error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateMedication(int medicationId, Map<String, dynamic> medicationData) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await getAuthHeaders();
      
      final requestBody = <String, dynamic>{};
      if (medicationData['name'] != null) requestBody['name'] = medicationData['name'];
      if (medicationData['dosage'] != null) requestBody['dosage'] = double.parse(medicationData['dosage'].toString());
      if (medicationData['unit'] != null) requestBody['unit'] = medicationData['unit'];
      if (medicationData['color'] != null) requestBody['color'] = medicationData['color'];
      if (medicationData['start_date'] != null) {
        requestBody['start_date'] = medicationData['start_date'].split('T')[0];
      }
      if (medicationData['end_date'] != null) {
        requestBody['end_date'] = medicationData['end_date'].split('T')[0];
      }
      if (medicationData['instructions'] != null) requestBody['instructions'] = medicationData['instructions'];
      if (medicationData['prescribed_by'] != null) requestBody['prescribed_by'] = medicationData['prescribed_by'];
      if (medicationData['notes'] != null) requestBody['notes'] = medicationData['notes'];
      
      final response = await http.put(
        Uri.parse('$baseUrl/medications/$medicationId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Medication updated successfully',
          'medication': data['medication'] != null 
              ? Medication.fromJson(data['medication']) 
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update medication',
        };
      }
    } catch (e) {
      debugPrint('Update medication error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteMedication(int medicationId) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/medications/$medicationId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Medication deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete medication',
        };
      }
    } catch (e) {
      debugPrint('Delete medication error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> logMedicationIntake({
    required int medicationId,
    int? scheduleId,
    required String logDate,
    required String logTime,
    String status = 'taken',
    String? actualTime,
    String? notes,
  }) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await getAuthHeaders();
      
      final requestBody = {
        'medication_id': medicationId,
        'log_date': logDate,
        'log_time': logTime,
        'status': status,
      };
      if (scheduleId != null) requestBody['schedule_id'] = scheduleId;
      if (actualTime != null) requestBody['actual_time'] = actualTime;
      if (notes != null) requestBody['notes'] = notes;
      
      debugPrint('Logging medication intake: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/medications/logs'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Medication intake logged successfully',
          'logId': data['id'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log intake',
        };
      }
    } catch (e) {
      debugPrint('Log medication intake error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateMedicationLogStatus(int logId, String status, {String? actualTime}) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await getAuthHeaders();
      
      final requestBody = {'status': status};
      if (actualTime != null) requestBody['actual_time'] = actualTime;
      
      final response = await http.patch(
        Uri.parse('$baseUrl/medications/logs/$logId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      debugPrint('Update log status error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMedicationLogsByDate(DateTime date) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'logs': []};
    }

    try {
      final headers = await getAuthHeaders();
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications/logs/date/$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'logs': data is List ? data : [],
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch logs', 'logs': []};
      }
    } catch (e) {
      debugPrint('Get logs by date error: $e');
      return {'success': false, 'message': 'Connection error: $e', 'logs': []};
    }
  }

  static Future<Map<String, dynamic>> getMedicationDailySummary(DateTime date) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'summary': null};
    }

    try {
      final headers = await getAuthHeaders();
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications/summary/daily?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'summary': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch daily summary', 'summary': null};
      }
    } catch (e) {
      debugPrint('Get daily summary error: $e');
      return {'success': false, 'message': 'Connection error: $e', 'summary': null};
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingMedicationDoses() async {
    if (!await _checkNetwork()) {
      return [];
    }

    try {
      final headers = await getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications/upcoming'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((d) => d as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get upcoming doses error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMissedMedicationDoses(DateTime date) async {
    if (!await _checkNetwork()) {
      return [];
    }

    try {
      final headers = await getAuthHeaders();
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications/missed?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((d) => d as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get missed doses error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getMedicationAdherenceRate(int medicationId, DateTime startDate, DateTime endDate) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'adherence': null};
    }

    try {
      final headers = await getAuthHeaders();
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications/$medicationId/adherence?start_date=$startStr&end_date=$endStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'adherence': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch adherence rate', 'adherence': null};
      }
    } catch (e) {
      debugPrint('Get adherence rate error: $e');
      return {'success': false, 'message': 'Connection error: $e', 'adherence': null};
    }
  }


  static Future<Map<String, dynamic>> getWeeklySummary(DateTime startDate) async {
    try {
      final headers = await getAuthHeaders();
      final formattedDate = startDate.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/meals/summary/weekly?start_date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both List and Map responses
        if (data is List) {
          // Return default empty map for list responses
          return {
            'calories': List.filled(7, 0.0),
            'workout_minutes': List.filled(7, 0.0),
            'sleep_hours': List.filled(7, 0.0),
            'hydration': List.filled(7, 0.0),
          };
        }
        return data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Get weekly summary error: $e');
      return {};
    }
  }
}