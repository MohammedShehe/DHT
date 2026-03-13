class CreateMealRequest {
  final String mealType;
  final DateTime mealTime;
  final String? notes;
  final List<CreateMealItem> items;

  CreateMealRequest({
    required this.mealType,
    required this.mealTime,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'meal_type': mealType,
      'meal_time': mealTime.toIso8601String(),
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateMealItem {
  final int? foodItemId;
  final double quantity;
  final String servingUnit;
  final String? customFoodName;
  final int? customCalories;
  final double? customProtein;
  final double? customCarbs;
  final double? customFat;

  CreateMealItem({
    this.foodItemId,
    required this.quantity,
    required this.servingUnit,
    this.customFoodName,
    this.customCalories,
    this.customProtein,
    this.customCarbs,
    this.customFat,
  }) {
    if (foodItemId == null && customFoodName == null) {
      throw ArgumentError('Either foodItemId or customFoodName must be provided');
    }
    if (customFoodName != null && (customCalories == null || customProtein == null || 
        customCarbs == null || customFat == null)) {
      throw ArgumentError('Custom food must include calories, protein, carbs, and fat');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'food_item_id': foodItemId,
      'quantity': quantity,
      'serving_unit': servingUnit,
      'custom_food_name': customFoodName,
      'custom_calories': customCalories,
      'custom_protein': customProtein,
      'custom_carbs': customCarbs,
      'custom_fat': customFat,
    };
  }
}

class UpdateMealRequest {
  final String? mealType;
  final DateTime? mealTime;
  final String? notes;
  final List<CreateMealItem>? items;

  UpdateMealRequest({
    this.mealType,
    this.mealTime,
    this.notes,
    this.items,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (mealType != null) json['meal_type'] = mealType;
    if (mealTime != null) json['meal_time'] = mealTime!.toIso8601String();
    if (notes != null) json['notes'] = notes;
    if (items != null) {
      json['items'] = items!.map((item) => item.toJson()).toList();
    }
    return json;
  }
}

class CreateCustomFoodRequest {
  final String name;
  final String brand;
  final int categoryId;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String? servingSize;
  final String servingUnit;

  CreateCustomFoodRequest({
    required this.name,
    this.brand = '',
    required this.categoryId,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.servingSize,
    this.servingUnit = 'g',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'category_id': categoryId,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
    };
  }
}