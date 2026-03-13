import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/api_config.dart';
import '../models/activity_models.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';

class ActivityService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Meal>> getMeals(DateTime date) async {
    try {
      final headers = await AuthService.getAuthHeaders();
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
      return [];
    }
  }

  static Future<Map<String, dynamic>> saveMeal(CreateMealRequest request) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
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
      final headers = await AuthService.getAuthHeaders();
      
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
      final headers = await AuthService.getAuthHeaders();
      
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

  static Future<List<Workout>> getWorkouts(DateTime date) async {
    try {
      final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/workouts/$workoutId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete workout');
    }
  }

  static Future<List<Sleep>> getSleep(DateTime date) async {
    try {
      final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/sleep/$sleepId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete sleep record');
    }
  }

  static Future<List<Hydration>> getHydration(DateTime date) async {
    try {
      final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
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
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/water/log/$hydrationId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hydration record');
    }
  }

  static Future<List<Medication>> getMedications() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['medications'] as List)
            .map((m) => Medication.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getMedicationsForDate(DateTime date) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = date.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/medications/daily?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveMedication(Medication medication) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/medications'),
      headers: headers,
      body: json.encode(medication.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save medication');
    }
  }

  static Future<void> updateMedication(Medication medication) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/medications/${medication.id}'),
      headers: headers,
      body: json.encode(medication.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update medication');
    }
  }

  static Future<void> deleteMedication(String medicationId) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/medications/$medicationId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete medication');
    }
  }

  static Future<void> markMedicationTaken(String medicationId, int timeIndex, bool taken) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/medications/$medicationId/taken'),
      headers: headers,
      body: json.encode({
        'time_index': timeIndex,
        'taken': taken ? 1 : 0,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark medication status');
    }
  }

  static Future<Map<String, dynamic>> getWeeklySummary(DateTime startDate) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = startDate.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/meals/summary/weekly?start_date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}