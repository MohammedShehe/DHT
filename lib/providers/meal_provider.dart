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

  // Cache for meals by date
  final Map<String, List<Meal>> _mealsCache = {};
  final Map<String, DailyMealSummary?> _summaryCache = {}; // Changed to nullable

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

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
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
      // Clear cache for the date of the meal
      final mealDate = DateTime(
        request.mealTime.year,
        request.mealTime.month,
        request.mealTime.day
      );
      final dateKey = _getDateKey(mealDate);
      _mealsCache.remove(dateKey);
      _summaryCache.remove(dateKey);
      
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
    final dateKey = _getDateKey(targetDate);
    
    // Check cache first
    if (_mealsCache.containsKey(dateKey)) {
      _todaysMeals = _mealsCache[dateKey] ?? [];
      _todaysSummary = _summaryCache[dateKey];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final result = await MealService.getMeals(targetDate);

    _isLoading = false;
    if (result['success']) {
      _todaysMeals = result['meals'];
      _todaysSummary = result['summary'];
      
      // Update cache
      _mealsCache[dateKey] = _todaysMeals;
      _summaryCache[dateKey] = _todaysSummary;
    } else {
      _error = result['message'];
    }
    notifyListeners();
  }

  // Refresh meals for a specific date (clear cache and reload)
  Future<void> refreshMealsForDate(DateTime date) async {
    final dateKey = _getDateKey(date);
    _mealsCache.remove(dateKey);
    _summaryCache.remove(dateKey);
    await loadTodaysMeals(date: date);
    _showMessage('Meals refreshed for ${_formatDate(date)}');
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
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
      // Clear cache for the date of the updated meal
      // Since we don't know the meal date, clear all caches to be safe
      _mealsCache.clear();
      _summaryCache.clear();
      
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
      // Clear cache for the date of the deleted meal
      // Since we don't know the meal date, clear all caches to be safe
      _mealsCache.clear();
      _summaryCache.clear();
      
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