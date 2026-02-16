import 'package:flutter/material.dart';
class FoodCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  FoodCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class FoodItem {
  final String id;
  final String name;
  final String brand;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String? servingSize;
  final String? servingUnit;
  final String categoryId;
  final bool isCustom;
  final String? imageUrl;
  final List<String>? tags;

  FoodItem({
    required this.id,
    required this.name,
    this.brand = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.servingSize,
    this.servingUnit = 'g',
    required this.categoryId,
    this.isCustom = false,
    this.imageUrl,
    this.tags,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      calories: json['calories'] ?? 0,
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: json['fiber']?.toDouble(),
      sugar: json['sugar']?.toDouble(),
      sodium: json['sodium']?.toDouble(),
      servingSize: json['serving_size']?.toString(),
      servingUnit: json['serving_unit'] ?? 'g',
      categoryId: json['category_id'] ?? 'other',
      isCustom: json['is_custom'] ?? false,
      imageUrl: json['image_url'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'category_id': categoryId,
      'is_custom': isCustom,
      'tags': tags,
    };
  }
}

class LoggedFood {
  final String id;
  final FoodItem food;
  final double quantity;
  final String servingUnit;
  final DateTime time;
  final String mealType;
  final String? notes;

  LoggedFood({
    required this.id,
    required this.food,
    required this.quantity,
    required this.servingUnit,
    required this.time,
    required this.mealType,
    this.notes,
  });

  int get calories => (food.calories * quantity).round();
  double get protein => food.protein * quantity;
  double get carbs => food.carbs * quantity;
  double get fat => food.fat * quantity;

  Map<String, dynamic> toJson() {
    return {
      'food_id': food.id,
      'quantity': quantity,
      'serving_unit': servingUnit,
      'time': time.toIso8601String(),
      'meal_type': mealType,
      'notes': notes,
    };
  }
}