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
      print('Error getting meals: $e');
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
      print('Error getting workouts: $e');
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
      print('Error getting sleep: $e');
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
      print('Error getting weekly summary: $e');
      return {};
    }
  }
}