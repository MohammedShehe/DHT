import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/api_config.dart';
import '../models/activity_models.dart';

class ActivityService {
  static String get baseUrl => '${ApiConfig.baseUrl}/activities';

  // Meals
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
        return (data['meals'] as List)
            .map((meal) => Meal.fromJson(meal))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveMeal(Meal meal) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/meals'),
      headers: headers,
      body: json.encode(meal.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save meal');
    }
  }

  static Future<void> updateMeal(Meal meal) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/meals/${meal.id}'),
      headers: headers,
      body: json.encode(meal.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update meal');
    }
  }

  static Future<void> deleteMeal(String mealId) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/meals/$mealId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete meal');
    }
  }

  // Workouts
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

  // Sleep
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

  // Hydration
  static Future<List<Hydration>> getHydration(DateTime date) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = date.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/hydration?date=$formattedDate'),
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
      Uri.parse('$baseUrl/hydration'),
      headers: headers,
      body: json.encode(hydration.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save hydration record');
    }
  }

  static Future<void> updateHydration(Hydration hydration) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/hydration/${hydration.id}'),
      headers: headers,
      body: json.encode(hydration.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update hydration record');
    }
  }

  static Future<void> deleteHydration(String hydrationId) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/hydration/$hydrationId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hydration record');
    }
  }

  // Medications
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

  // Weekly summaries
  static Future<Map<String, dynamic>> getWeeklySummary(DateTime startDate) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = startDate.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/summary/weekly?start_date=$formattedDate'),
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