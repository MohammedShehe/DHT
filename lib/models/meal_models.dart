import 'package:flutter/material.dart';

class FoodCategory {
  final int id;
  final String name;
  final String icon;
  final String color;
  final int displayOrder;

  FoodCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.displayOrder,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      displayOrder: json['display_order'] as int,
    );
  }
}

class FoodItem {
  final int id;
  final String name;
  final String brand;
  final int categoryId;
  final String? categoryName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String? servingSize;
  final String servingUnit;
  final bool isCustom;
  final int? createdBy;
  final int useCount;

  FoodItem({
    required this.id,
    required this.name,
    this.brand = '',
    required this.categoryId,
    this.categoryName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.servingSize,
    this.servingUnit = 'g',
    this.isCustom = false,
    this.createdBy,
    this.useCount = 0,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand']?.toString() ?? '',
      categoryId: json['category_id'] as int,
      categoryName: json['category_name']?.toString(),
      calories: json['calories'] != null ? int.parse(json['calories'].toString()) : 0,
      protein: json['protein'] != null ? double.parse(json['protein'].toString()) : 0.0,
      carbs: json['carbs'] != null ? double.parse(json['carbs'].toString()) : 0.0,
      fat: json['fat'] != null ? double.parse(json['fat'].toString()) : 0.0,
      fiber: json['fiber'] != null ? double.tryParse(json['fiber'].toString()) : null,
      sugar: json['sugar'] != null ? double.tryParse(json['sugar'].toString()) : null,
      sodium: json['sodium'] != null ? double.tryParse(json['sodium'].toString()) : null,
      servingSize: json['serving_size']?.toString(),
      servingUnit: json['serving_unit']?.toString() ?? 'g',
      isCustom: json['is_custom'] == 1 || json['is_custom'] == true,
      createdBy: json['created_by'] as int?,
      useCount: json['use_count'] != null ? int.parse(json['use_count'].toString()) : 0,
    );
  }
}

class MealItem {
  final int id;
  final int? foodItemId;
  final String? foodName;
  final double quantity;
  final String servingUnit;
  final String? customFoodName;
  final int? customCalories;
  final double? customProtein;
  final double? customCarbs;
  final double? customFat;
  final String? notes;

  MealItem({
    required this.id,
    this.foodItemId,
    this.foodName,
    required this.quantity,
    required this.servingUnit,
    this.customFoodName,
    this.customCalories,
    this.customProtein,
    this.customCarbs,
    this.customFat,
    this.notes,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] as int,
      foodItemId: json['food_item_id'] as int?,
      foodName: json['food_name']?.toString(),
      quantity: json['quantity'] != null ? double.parse(json['quantity'].toString()) : 0.0,
      servingUnit: json['serving_unit']?.toString() ?? 'g',
      customFoodName: json['custom_food_name']?.toString(),
      customCalories: json['calories'] != null ? int.tryParse(json['calories'].toString()) : null,
      customProtein: json['protein'] != null ? double.tryParse(json['protein'].toString()) : null,
      customCarbs: json['carbs'] != null ? double.tryParse(json['carbs'].toString()) : null,
      customFat: json['fat'] != null ? double.tryParse(json['fat'].toString()) : null,
      notes: json['notes']?.toString(),
    );
  }

  int get calories {
    if (customCalories != null) return customCalories!;
    return 0;
  }

  double get protein => customProtein ?? 0.0;
  double get carbs => customCarbs ?? 0.0;
  double get fat => customFat ?? 0.0;
}

class Meal {
  final int id;
  final String mealType;
  final DateTime mealTime;
  final String? notes;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MealItem> items;

  Meal({
    required this.id,
    required this.mealType,
    required this.mealTime,
    this.notes,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<MealItem> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((item) => MealItem.fromJson(item))
          .toList();
    }

    return Meal(
      id: json['id'] as int,
      mealType: json['meal_type'] as String,
      mealTime: DateTime.parse(json['meal_time'] as String),
      notes: json['notes']?.toString(),
      totalCalories: json['total_calories'] != null ? int.parse(json['total_calories'].toString()) : 0,
      totalProtein: json['total_protein'] != null ? double.parse(json['total_protein'].toString()) : 0.0,
      totalCarbs: json['total_carbs'] != null ? double.parse(json['total_carbs'].toString()) : 0.0,
      totalFat: json['total_fat'] != null ? double.parse(json['total_fat'].toString()) : 0.0,
      photoUrl: json['photo_url']?.toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: items,
    );
  }

  String get formattedTime {
    return '${mealTime.hour.toString().padLeft(2, '0')}:${mealTime.minute.toString().padLeft(2, '0')}';
  }

  String get itemsSummary {
    return items.map((item) {
      if (item.customFoodName != null) {
        return '${item.customFoodName} (${item.quantity.toStringAsFixed(1)} ${item.servingUnit})';
      } else {
        return '${item.foodName} (${item.quantity.toStringAsFixed(1)} ${item.servingUnit})';
      }
    }).join(', ');
  }
}

class DailyMealSummary {
  final List<Meal> meals;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  DailyMealSummary({
    required this.meals,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory DailyMealSummary.fromJson(Map<String, dynamic> json) {
    List<Meal> meals = [];
    if (json['meals'] != null && json['meals'] is List) {
      meals = (json['meals'] as List)
          .map((meal) => Meal.fromJson(meal))
          .toList();
    }

    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    return DailyMealSummary(
      meals: meals,
      totalCalories: summary['calories'] != null ? int.parse(summary['calories'].toString()) : 0,
      totalProtein: summary['protein'] != null ? double.parse(summary['protein'].toString()) : 0.0,
      totalCarbs: summary['carbs'] != null ? double.parse(summary['carbs'].toString()) : 0.0,
      totalFat: summary['fat'] != null ? double.parse(summary['fat'].toString()) : 0.0,
    );
  }
}

class WeeklyMealSummary {
  final DateTime date;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int mealCount;

  WeeklyMealSummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealCount,
  });

  factory WeeklyMealSummary.fromJson(Map<String, dynamic> json) {
    return WeeklyMealSummary(
      date: DateTime.parse(json['date'] as String),
      totalCalories: json['total_calories'] != null ? int.parse(json['total_calories'].toString()) : 0,
      totalProtein: json['total_protein'] != null ? double.parse(json['total_protein'].toString()) : 0.0,
      totalCarbs: json['total_carbs'] != null ? double.parse(json['total_carbs'].toString()) : 0.0,
      totalFat: json['total_fat'] != null ? double.parse(json['total_fat'].toString()) : 0.0,
      mealCount: json['meal_count'] != null ? int.parse(json['meal_count'].toString()) : 0,
    );
  }
}

class FavoriteFood {
  final int id;
  final FoodItem food;
  final DateTime lastUsed;
  final int useCount;

  FavoriteFood({
    required this.id,
    required this.food,
    required this.lastUsed,
    required this.useCount,
  });

  factory FavoriteFood.fromJson(Map<String, dynamic> json) {
    return FavoriteFood(
      id: json['id'] as int,
      food: FoodItem.fromJson(json),
      lastUsed: DateTime.parse(json['last_used'] as String),
      useCount: json['use_count'] != null ? int.parse(json['use_count'].toString()) : 0,
    );
  }
}