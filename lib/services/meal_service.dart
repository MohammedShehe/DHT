import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_service.dart';
import '../utils/api_config.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';

class MealService {
  static String get baseUrl => '${ApiConfig.baseUrl}/meals';

  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) return true;
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return response.statusCode >= 200 && response.statusCode < 300
            ? {'success': true}
            : {'success': false, 'message': 'Empty response with status ${response.statusCode}'};
      }
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to parse response'};
    }
  }

  static Future<Map<String, dynamic>> getCategories() async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'categories': []};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final categories = data.map((c) => FoodCategory.fromJson(c)).toList();
          return {'success': true, 'categories': categories};
        }
        return {'success': true, 'categories': []};
      }
      return {'success': false, 'message': 'Failed to fetch categories', 'categories': []};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'categories': []};
    }
  }

  static Future<Map<String, dynamic>> searchFoods({
    String? query,
    int? categoryId,
    int limit = 50,
  }) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'foods': []};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      String url = '$baseUrl/foods/search?limit=$limit';
      if (query != null && query.isNotEmpty) url += '&q=${Uri.encodeComponent(query)}';
      if (categoryId != null) url += '&category_id=$categoryId';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final foods = data.map((f) => FoodItem.fromJson(f)).toList();
          return {'success': true, 'foods': foods};
        }
        return {'success': true, 'foods': []};
      }
      return {'success': false, 'message': 'Failed to search foods', 'foods': []};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'foods': []};
    }
  }

  static Future<Map<String, dynamic>> getFoodsByCategory(int categoryId, {int limit = 100}) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'foods': []};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/foods/category/$categoryId?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final foods = data.map((f) => FoodItem.fromJson(f)).toList();
          return {'success': true, 'foods': foods};
        }
        return {'success': true, 'foods': []};
      }
      return {'success': false, 'message': 'Failed to fetch foods', 'foods': []};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'foods': []};
    }
  }

  static Future<Map<String, dynamic>> getPopularFoods({int limit = 20}) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'foods': []};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/foods/popular?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final foods = data.map((f) => FoodItem.fromJson(f)).toList();
          return {'success': true, 'foods': foods};
        }
        return {'success': true, 'foods': []};
      }
      return {'success': false, 'message': 'Failed to fetch popular foods', 'foods': []};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'foods': []};
    }
  }

  static Future<Map<String, dynamic>> getUserCustomFoods() async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'foods': []};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/foods/custom'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final foods = data.map((f) => FoodItem.fromJson(f)).toList();
          return {'success': true, 'foods': foods};
        }
        return {'success': true, 'foods': []};
      }
      return {'success': false, 'message': 'Failed to fetch custom foods', 'foods': []};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'foods': []};
    }
  }

  static Future<Map<String, dynamic>> createCustomFood(CreateCustomFoodRequest request) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/foods/custom'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        final food = data['food'] != null ? FoodItem.fromJson(data['food']) : null;
        return {
          'success': true,
          'message': data['message'] ?? 'Food created successfully',
          'food': food,
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create food',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCustomFood(int foodId, CreateCustomFoodRequest request) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/foods/custom/$foodId'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        final food = data['food'] != null ? FoodItem.fromJson(data['food']) : null;
        return {
          'success': true,
          'message': data['message'] ?? 'Food updated successfully',
          'food': food,
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update food',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCustomFood(int foodId) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/foods/custom/$foodId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': true,
          'message': data['message'] ?? 'Food deleted successfully',
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete food',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createMeal(CreateMealRequest request) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        final meal = data['meal'] != null ? Meal.fromJson(data['meal']) : null;
        return {
          'success': true,
          'message': data['message'] ?? 'Meal logged successfully',
          'meal': meal,
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to log meal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMeals(DateTime date) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'meals': [], 'summary': null};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = DailyMealSummary.fromJson(data);
        return {
          'success': true,
          'meals': summary.meals,
          'summary': summary,
        };
      }
      return {
        'success': false,
        'message': 'Failed to fetch meals',
        'meals': [],
        'summary': null,
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'meals': [], 'summary': null};
    }
  }

  static Future<Map<String, dynamic>> getMealById(int id) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'meal': null};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meal = Meal.fromJson(data);
        return {'success': true, 'meal': meal};
      }
      if (response.statusCode == 404) {
        return {'success': false, 'message': 'Meal not found', 'meal': null};
      }
      return {'success': false, 'message': 'Failed to fetch meal', 'meal': null};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'meal': null};
    }
  }

  static Future<Map<String, dynamic>> updateMeal(int id, UpdateMealRequest request) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        final meal = data['meal'] != null ? Meal.fromJson(data['meal']) : null;
        return {
          'success': true,
          'message': data['message'] ?? 'Meal updated successfully',
          'meal': meal,
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update meal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteMeal(int id) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
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
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getWeeklyMealSummary(DateTime startDate) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'summary': []};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = startDate.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/summary/weekly?start_date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final summary = data.map((s) => WeeklyMealSummary.fromJson(s)).toList();
          return {'success': true, 'summary': summary};
        }
        return {'success': true, 'summary': []};
      }
      return {'success': false, 'message': 'Failed to fetch weekly summary', 'summary': []};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'summary': []};
    }
  }

  static Future<Map<String, dynamic>> getFavorites({int limit = 20}) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection', 'favorites': []};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favorites?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final favorites = data.map((f) => FavoriteFood.fromJson(f)).toList();
          return {'success': true, 'favorites': favorites};
        }
        return {'success': true, 'favorites': []};
      }
      return {'success': false, 'message': 'Failed to fetch favorites', 'favorites': []};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'favorites': []};
    }
  }

  static Future<Map<String, dynamic>> addToFavorites(int foodId) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$foodId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': true,
          'message': data['message'] ?? 'Added to favorites',
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add to favorites',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeFromFavorites(int foodId) async {
    if (!await _checkNetwork()) {
      return {'success': false, 'message': 'No internet connection'};
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$foodId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': true,
          'message': data['message'] ?? 'Removed from favorites',
        };
      } else {
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to remove from favorites',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}