import 'package:flutter/material.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';
import '../services/meal_service.dart';

class MealProvider extends ChangeNotifier {
  List<FoodCategory> _categories = [];
  List<FoodItem> _foods = [];
  List<FoodItem> _popularFoods = [];
  List<FoodItem> _customFoods = [];
  List<FavoriteFood> _favorites = [];
  List<Meal> _todaysMeals = [];
  DailyMealSummary? _todaysSummary;
  List<WeeklyMealSummary> _weeklySummary = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<FoodCategory> get categories => _categories;
  List<FoodItem> get foods => _foods;
  List<FoodItem> get popularFoods => _popularFoods;
  List<FoodItem> get customFoods => _customFoods;
  List<FavoriteFood> get favorites => _favorites;
  List<Meal> get todaysMeals => _todaysMeals;
  DailyMealSummary? get todaysSummary => _todaysSummary;
  List<WeeklyMealSummary> get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  // Initialize provider
  MealProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadCategories(),
      loadPopularFoods(),
      loadCustomFoods(),
      loadFavorites(),
    ]);
  }

  Future<void> loadCategories() async {
    final result = await MealService.getCategories();
    if (result['success']) {
      _categories = result['categories'];
      notifyListeners();
    }
  }

  Future<void> loadPopularFoods() async {
    final result = await MealService.getPopularFoods();
    if (result['success']) {
      _popularFoods = result['foods'];
      notifyListeners();
    }
  }

  Future<void> loadCustomFoods() async {
    final result = await MealService.getUserCustomFoods();
    if (result['success']) {
      _customFoods = result['foods'];
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    final result = await MealService.getFavorites();
    if (result['success']) {
      _favorites = result['favorites'];
      notifyListeners();
    }
  }

  Future<void> searchFoods({String? query, int? categoryId}) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.searchFoods(
      query: query,
      categoryId: categoryId,
    );

    _isLoading = false;
    if (result['success']) {
      _foods = result['foods'];
    } else {
      _error = result['message'];
    }
    notifyListeners();
  }

  Future<void> loadFoodsByCategory(int categoryId) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.getFoodsByCategory(categoryId);

    _isLoading = false;
    if (result['success']) {
      _foods = result['foods'];
    } else {
      _error = result['message'];
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> createCustomFood(CreateCustomFoodRequest request) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.createCustomFood(request);

    _isLoading = false;
    if (result['success']) {
      await loadCustomFoods();
      _showMessage(result['message'] ?? 'Food created successfully');
    } else {
      _showMessage(result['message'] ?? 'Failed to create food', isError: true);
      _error = result['message'];
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> updateCustomFood(int foodId, CreateCustomFoodRequest request) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.updateCustomFood(foodId, request);

    _isLoading = false;
    if (result['success']) {
      await loadCustomFoods();
      _showMessage(result['message'] ?? 'Food updated successfully');
    } else {
      _showMessage(result['message'] ?? 'Failed to update food', isError: true);
      _error = result['message'];
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteCustomFood(int foodId) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.deleteCustomFood(foodId);

    _isLoading = false;
    if (result['success']) {
      await loadCustomFoods();
      _showMessage(result['message'] ?? 'Food deleted successfully');
    } else {
      _showMessage(result['message'] ?? 'Failed to delete food', isError: true);
      _error = result['message'];
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> createMeal(CreateMealRequest request) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.createMeal(request);

    _isLoading = false;
    if (result['success']) {
      await loadTodaysMeals();
      _showMessage(result['message'] ?? 'Meal logged successfully');
    } else {
      _showMessage(result['message'] ?? 'Failed to log meal', isError: true);
      _error = result['message'];
    }
    notifyListeners();
    return result;
  }

  Future<void> loadTodaysMeals({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    _isLoading = true;
    notifyListeners();

    final result = await MealService.getMeals(targetDate);

    _isLoading = false;
    if (result['success']) {
      _todaysMeals = result['meals'];
      _todaysSummary = result['summary'];
    } else {
      _error = result['message'];
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> getMealById(int id) async {
    final result = await MealService.getMealById(id);
    return result;
  }

  Future<Map<String, dynamic>> updateMeal(int id, UpdateMealRequest request) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.updateMeal(id, request);

    _isLoading = false;
    if (result['success']) {
      await loadTodaysMeals();
      _showMessage(result['message'] ?? 'Meal updated successfully');
    } else {
      _showMessage(result['message'] ?? 'Failed to update meal', isError: true);
      _error = result['message'];
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteMeal(int id) async {
    _isLoading = true;
    notifyListeners();

    final result = await MealService.deleteMeal(id);

    _isLoading = false;
    if (result['success']) {
      await loadTodaysMeals();
      _showMessage(result['message'] ?? 'Meal deleted successfully');
    } else {
      _showMessage(result['message'] ?? 'Failed to delete meal', isError: true);
      _error = result['message'];
    }
    notifyListeners();
    return result;
  }

  Future<void> loadWeeklySummary({DateTime? startDate}) async {
    final date = startDate ?? DateTime.now().subtract(const Duration(days: 6));
    
    final result = await MealService.getWeeklyMealSummary(date);
    if (result['success']) {
      _weeklySummary = result['summary'];
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> addToFavorites(int foodId) async {
    final result = await MealService.addToFavorites(foodId);
    if (result['success']) {
      await loadFavorites();
      _showMessage(result['message'] ?? 'Added to favorites');
    } else {
      _showMessage(result['message'] ?? 'Failed to add to favorites', isError: true);
    }
    return result;
  }

  Future<Map<String, dynamic>> removeFromFavorites(int foodId) async {
    final result = await MealService.removeFromFavorites(foodId);
    if (result['success']) {
      await loadFavorites();
      _showMessage(result['message'] ?? 'Removed from favorites');
    } else {
      _showMessage(result['message'] ?? 'Failed to remove from favorites', isError: true);
    }
    return result;
  }

  bool isFavorite(int foodId) {
    return _favorites.any((f) => f.food.id == foodId);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }

  void clearSearch() {
    _foods = [];
    notifyListeners();
  }
}