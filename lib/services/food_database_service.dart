import 'package:flutter/material.dart';
import '../models/food_model.dart';

class FoodDatabaseService {
  static final FoodDatabaseService _instance = FoodDatabaseService._internal();
  factory FoodDatabaseService() => _instance;
  FoodDatabaseService._internal();

  List<FoodItem> _foods = [];
  List<FoodCategory> _categories = [];
  bool _isInitialized = false;

  // Popular foods database
  static const Map<String, List<Map<String, dynamic>>> _commonFoods = {
    'breakfast': [
      {'name': 'Oatmeal', 'calories': 150, 'protein': 5, 'carbs': 27, 'fat': 3, 'serving': '1 cup cooked'},
      {'name': 'Scrambled Eggs', 'calories': 140, 'protein': 10, 'carbs': 1, 'fat': 10, 'serving': '2 eggs'},
      {'name': 'Greek Yogurt', 'calories': 100, 'protein': 17, 'carbs': 6, 'fat': 0, 'serving': '150g'},
      {'name': 'Banana', 'calories': 105, 'protein': 1.3, 'carbs': 27, 'fat': 0.4, 'serving': '1 medium'},
      {'name': 'Whole Wheat Toast', 'calories': 80, 'protein': 4, 'carbs': 14, 'fat': 1, 'serving': '1 slice'},
      {'name': 'Cereal with Milk', 'calories': 200, 'protein': 8, 'carbs': 35, 'fat': 4, 'serving': '1 bowl'},
      {'name': 'Pancakes', 'calories': 180, 'protein': 5, 'carbs': 30, 'fat': 5, 'serving': '2 medium'},
      {'name': 'Smoothie', 'calories': 250, 'protein': 10, 'carbs': 45, 'fat': 5, 'serving': '12 oz'},
    ],
    'lunch': [
      {'name': 'Grilled Chicken Breast', 'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6, 'serving': '100g'},
      {'name': 'Brown Rice', 'calories': 215, 'protein': 5, 'carbs': 45, 'fat': 1.8, 'serving': '1 cup cooked'},
      {'name': 'Quinoa', 'calories': 220, 'protein': 8, 'carbs': 39, 'fat': 3.6, 'serving': '1 cup cooked'},
      {'name': 'Salmon Fillet', 'calories': 200, 'protein': 22, 'carbs': 0, 'fat': 12, 'serving': '100g'},
      {'name': 'Caesar Salad', 'calories': 330, 'protein': 8, 'carbs': 10, 'fat': 28, 'serving': '1 bowl'},
      {'name': 'Turkey Sandwich', 'calories': 350, 'protein': 20, 'carbs': 40, 'fat': 12, 'serving': '1 sandwich'},
      {'name': 'Vegetable Soup', 'calories': 120, 'protein': 4, 'carbs': 20, 'fat': 3, 'serving': '1 cup'},
      {'name': 'Tuna Salad', 'calories': 190, 'protein': 25, 'carbs': 5, 'fat': 8, 'serving': '100g'},
    ],
    'dinner': [
      {'name': 'Steak', 'calories': 250, 'protein': 26, 'carbs': 0, 'fat': 17, 'serving': '100g'},
      {'name': 'Baked Potato', 'calories': 160, 'protein': 4, 'carbs': 37, 'fat': 0.2, 'serving': '1 medium'},
      {'name': 'Steamed Broccoli', 'calories': 55, 'protein': 3.7, 'carbs': 11, 'fat': 0.6, 'serving': '1 cup'},
      {'name': 'Spaghetti', 'calories': 220, 'protein': 8, 'carbs': 43, 'fat': 1.3, 'serving': '1 cup cooked'},
      {'name': 'Meatballs', 'calories': 250, 'protein': 15, 'carbs': 8, 'fat': 18, 'serving': '4 pieces'},
      {'name': 'Stir-fry Vegetables', 'calories': 120, 'protein': 4, 'carbs': 18, 'fat': 4, 'serving': '1 cup'},
      {'name': 'Curry', 'calories': 350, 'protein': 12, 'carbs': 25, 'fat': 22, 'serving': '1 cup'},
      {'name': 'Fish Tacos', 'calories': 300, 'protein': 18, 'carbs': 30, 'fat': 12, 'serving': '2 tacos'},
    ],
    'snacks': [
      {'name': 'Apple', 'calories': 95, 'protein': 0.5, 'carbs': 25, 'fat': 0.3, 'serving': '1 medium'},
      {'name': 'Almonds', 'calories': 160, 'protein': 6, 'carbs': 6, 'fat': 14, 'serving': '1 oz (23 nuts)'},
      {'name': 'Protein Bar', 'calories': 200, 'protein': 15, 'carbs': 22, 'fat': 8, 'serving': '1 bar'},
      {'name': 'Greek Yogurt', 'calories': 100, 'protein': 17, 'carbs': 6, 'fat': 0, 'serving': '150g'},
      {'name': 'Hummus', 'calories': 70, 'protein': 2, 'carbs': 6, 'fat': 5, 'serving': '2 tbsp'},
      {'name': 'Carrot Sticks', 'calories': 50, 'protein': 1, 'carbs': 12, 'fat': 0, 'serving': '1 cup'},
      {'name': 'Trail Mix', 'calories': 150, 'protein': 5, 'carbs': 15, 'fat': 9, 'serving': '1/4 cup'},
      {'name': 'Cottage Cheese', 'calories': 110, 'protein': 13, 'carbs': 5, 'fat': 5, 'serving': '1/2 cup'},
    ],
    'fruits': [
      {'name': 'Apple', 'calories': 95, 'protein': 0.5, 'carbs': 25, 'fat': 0.3, 'serving': '1 medium'},
      {'name': 'Banana', 'calories': 105, 'protein': 1.3, 'carbs': 27, 'fat': 0.4, 'serving': '1 medium'},
      {'name': 'Orange', 'calories': 62, 'protein': 1.2, 'carbs': 15, 'fat': 0.2, 'serving': '1 medium'},
      {'name': 'Strawberries', 'calories': 49, 'protein': 1, 'carbs': 11.7, 'fat': 0.5, 'serving': '1 cup'},
      {'name': 'Blueberries', 'calories': 85, 'protein': 1.1, 'carbs': 21, 'fat': 0.5, 'serving': '1 cup'},
      {'name': 'Grapes', 'calories': 104, 'protein': 1.1, 'carbs': 27, 'fat': 0.2, 'serving': '1 cup'},
      {'name': 'Watermelon', 'calories': 46, 'protein': 0.9, 'carbs': 11.5, 'fat': 0.2, 'serving': '1 cup'},
      {'name': 'Pineapple', 'calories': 82, 'protein': 0.9, 'carbs': 22, 'fat': 0.2, 'serving': '1 cup'},
    ],
    'vegetables': [
      {'name': 'Spinach', 'calories': 7, 'protein': 0.9, 'carbs': 1.1, 'fat': 0.1, 'serving': '1 cup'},
      {'name': 'Broccoli', 'calories': 55, 'protein': 3.7, 'carbs': 11, 'fat': 0.6, 'serving': '1 cup'},
      {'name': 'Carrots', 'calories': 50, 'protein': 1.1, 'carbs': 12, 'fat': 0.3, 'serving': '1 cup'},
      {'name': 'Tomatoes', 'calories': 22, 'protein': 1.1, 'carbs': 4.8, 'fat': 0.2, 'serving': '1 medium'},
      {'name': 'Bell Peppers', 'calories': 30, 'protein': 1, 'carbs': 7, 'fat': 0.3, 'serving': '1 cup'},
      {'name': 'Cucumber', 'calories': 16, 'protein': 0.7, 'carbs': 3.6, 'fat': 0.2, 'serving': '1 cup'},
      {'name': 'Kale', 'calories': 33, 'protein': 2.2, 'carbs': 6, 'fat': 0.6, 'serving': '1 cup'},
      {'name': 'Sweet Potato', 'calories': 103, 'protein': 2, 'carbs': 24, 'fat': 0.2, 'serving': '1 medium'},
    ],
    'protein': [
      {'name': 'Chicken Breast', 'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6, 'serving': '100g'},
      {'name': 'Ground Beef', 'calories': 250, 'protein': 26, 'carbs': 0, 'fat': 17, 'serving': '100g'},
      {'name': 'Salmon', 'calories': 200, 'protein': 22, 'carbs': 0, 'fat': 12, 'serving': '100g'},
      {'name': 'Tuna', 'calories': 130, 'protein': 28, 'carbs': 0, 'fat': 1, 'serving': '100g'},
      {'name': 'Eggs', 'calories': 70, 'protein': 6, 'carbs': 0.6, 'fat': 5, 'serving': '1 large'},
      {'name': 'Tofu', 'calories': 144, 'protein': 17, 'carbs': 3, 'fat': 9, 'serving': '100g'},
      {'name': 'Greek Yogurt', 'calories': 100, 'protein': 17, 'carbs': 6, 'fat': 0, 'serving': '150g'},
      {'name': 'Cottage Cheese', 'calories': 110, 'protein': 13, 'carbs': 5, 'fat': 5, 'serving': '1/2 cup'},
    ],
    'grains': [
      {'name': 'White Rice', 'calories': 205, 'protein': 4.2, 'carbs': 45, 'fat': 0.4, 'serving': '1 cup cooked'},
      {'name': 'Brown Rice', 'calories': 215, 'protein': 5, 'carbs': 45, 'fat': 1.8, 'serving': '1 cup cooked'},
      {'name': 'Quinoa', 'calories': 220, 'protein': 8, 'carbs': 39, 'fat': 3.6, 'serving': '1 cup cooked'},
      {'name': 'Oats', 'calories': 150, 'protein': 5, 'carbs': 27, 'fat': 3, 'serving': '1/2 cup dry'},
      {'name': 'Whole Wheat Bread', 'calories': 80, 'protein': 4, 'carbs': 14, 'fat': 1, 'serving': '1 slice'},
      {'name': 'Pasta', 'calories': 220, 'protein': 8, 'carbs': 43, 'fat': 1.3, 'serving': '1 cup cooked'},
      {'name': 'Couscous', 'calories': 176, 'protein': 6, 'carbs': 36, 'fat': 0.3, 'serving': '1 cup cooked'},
      {'name': 'Barley', 'calories': 193, 'protein': 3.5, 'carbs': 44, 'fat': 0.7, 'serving': '1 cup cooked'},
    ],
    'dairy': [
      {'name': 'Milk', 'calories': 103, 'protein': 8, 'carbs': 12, 'fat': 2.4, 'serving': '1 cup'},
      {'name': 'Cheese', 'calories': 113, 'protein': 7, 'carbs': 0.4, 'fat': 9, 'serving': '1 slice'},
      {'name': 'Yogurt', 'calories': 100, 'protein': 10, 'carbs': 12, 'fat': 2, 'serving': '150g'},
      {'name': 'Butter', 'calories': 100, 'protein': 0.1, 'carbs': 0, 'fat': 11, 'serving': '1 tbsp'},
      {'name': 'Cottage Cheese', 'calories': 110, 'protein': 13, 'carbs': 5, 'fat': 5, 'serving': '1/2 cup'},
      {'name': 'Sour Cream', 'calories': 60, 'protein': 1, 'carbs': 2, 'fat': 5, 'serving': '2 tbsp'},
      {'name': 'Ice Cream', 'calories': 270, 'protein': 5, 'carbs': 31, 'fat': 14, 'serving': '1 cup'},
      {'name': 'Cream Cheese', 'calories': 50, 'protein': 1, 'carbs': 1, 'fat': 5, 'serving': '1 tbsp'},
    ],
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize categories
    _categories = [
      FoodCategory(id: 'breakfast', name: 'Breakfast', icon: Icons.breakfast_dining, color: Color(0xFFFF9800)),
      FoodCategory(id: 'lunch', name: 'Lunch', icon: Icons.lunch_dining, color: Color(0xFF4CAF50)),
      FoodCategory(id: 'dinner', name: 'Dinner', icon: Icons.dinner_dining, color: Color(0xFF9C27B0)),
      FoodCategory(id: 'snacks', name: 'Snacks', icon: Icons.cookie, color: Color(0xFFFF5722)),
      FoodCategory(id: 'fruits', name: 'Fruits', icon: Icons.apple, color: Color(0xFFE91E63)),
      FoodCategory(id: 'vegetables', name: 'Vegetables', icon: Icons.eco, color: Color(0xFF8BC34A)),
      FoodCategory(id: 'protein', name: 'Protein', icon: Icons.fitness_center, color: Color(0xFFF44336)),
      FoodCategory(id: 'grains', name: 'Grains', icon: Icons.grain, color: Color(0xFF795548)),
      FoodCategory(id: 'dairy', name: 'Dairy', icon: Icons.egg, color: Color(0xFF2196F3)),
      FoodCategory(id: 'beverages', name: 'Beverages', icon: Icons.local_drink, color: Color(0xFF00BCD4)),
      FoodCategory(id: 'fastfood', name: 'Fast Food', icon: Icons.fastfood, color: Color(0xFFFF6D00)),
      FoodCategory(id: 'desserts', name: 'Desserts', icon: Icons.cake, color: Color(0xFFD81B60)),
      FoodCategory(id: 'other', name: 'Other', icon: Icons.category, color: Color(0xFF607D8B)),
    ];

    // Initialize foods from common foods database
    int id = 1;
    _commonFoods.forEach((category, foods) {
      for (var food in foods) {
        _foods.add(FoodItem(
          id: 'food_$id',
          name: food['name'],
          calories: food['calories'],
          protein: food['protein'].toDouble(),
          carbs: food['carbs'].toDouble(),
          fat: food['fat'].toDouble(),
          servingSize: food['serving'],
          servingUnit: 'serving',
          categoryId: category,
          tags: [category],
        ));
        id++;
      }
    });

    _isInitialized = true;
  }

  List<FoodCategory> get categories => _categories;

  List<FoodItem> searchFoods(String query, {String? categoryId}) {
    if (query.isEmpty) {
      return categoryId != null 
          ? _foods.where((f) => f.categoryId == categoryId).toList()
          : _foods;
    }

    final lowerQuery = query.toLowerCase();
    return _foods.where((food) {
      final matchesQuery = food.name.toLowerCase().contains(lowerQuery) ||
          food.brand.toLowerCase().contains(lowerQuery);
      
      if (categoryId != null) {
        return matchesQuery && food.categoryId == categoryId;
      }
      return matchesQuery;
    }).toList();
  }

  List<FoodItem> getFoodsByCategory(String categoryId) {
    return _foods.where((f) => f.categoryId == categoryId).toList();
  }

  FoodItem? getFoodById(String id) {
    try {
      return _foods.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<FoodItem> addCustomFood(FoodItem food) async {
    final newFood = FoodItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: food.name,
      brand: food.brand,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      fiber: food.fiber,
      sugar: food.sugar,
      sodium: food.sodium,
      servingSize: food.servingSize,
      servingUnit: food.servingUnit,
      categoryId: food.categoryId,
      isCustom: true,
      tags: food.tags,
    );
    
    _foods.add(newFood);
    return newFood;
  }

  List<String> getCommonServingUnits() {
    return ['g', 'ml', 'oz', 'cup', 'tbsp', 'tsp', 'piece', 'slice', 'serving'];
  }
}