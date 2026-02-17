import 'package:flutter/material.dart';

class Meal {
  final String id;
  final String type;
  final int calories;
  final String time;
  final String items;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? photoUrl;

  Meal({
    required this.id,
    required this.type,
    required this.calories,
    required this.time,
    required this.items,
    this.protein,
    this.carbs,
    this.fat,
    this.photoUrl,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      calories: json['calories'] ?? 0,
      time: json['time'] ?? '',
      items: json['items'] ?? '',
      protein: json['protein']?.toDouble(),
      carbs: json['carbs']?.toDouble(),
      fat: json['fat']?.toDouble(),
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'calories': calories,
      'time': time,
      'items': items,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'photo_url': photoUrl,
    };
  }
}

class Workout {
  final String id;
  final String type;
  final int duration;
  final int calories;
  final String time;
  final String intensity;
  final String? notes;

  Workout({
    required this.id,
    required this.type,
    required this.duration,
    required this.calories,
    required this.time,
    required this.intensity,
    this.notes,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      duration: json['duration'] ?? 0,
      calories: json['calories'] ?? 0,
      time: json['time'] ?? '',
      intensity: json['intensity'] ?? 'Moderate',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'duration': duration,
      'calories': calories,
      'time': time,
      'intensity': intensity,
      'notes': notes,
    };
  }
}

class Sleep {
  final String id;
  final DateTime date;
  final TimeOfDay bedTime;
  final TimeOfDay wakeTime;
  final double duration;
  final int interruptions;
  final String quality;
  final double? deepSleep;
  final double? remSleep;
  final double? lightSleep;

  Sleep({
    required this.id,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.duration,
    required this.interruptions,
    required this.quality,
    this.deepSleep,
    this.remSleep,
    this.lightSleep,
  });

  factory Sleep.fromJson(Map<String, dynamic> json) {
    return Sleep(
      id: json['id'].toString(),
      date: DateTime.parse(json['date']),
      bedTime: TimeOfDay(
        hour: json['bed_hour'] ?? 0,
        minute: json['bed_minute'] ?? 0,
      ),
      wakeTime: TimeOfDay(
        hour: json['wake_hour'] ?? 0,
        minute: json['wake_minute'] ?? 0,
      ),
      duration: json['duration']?.toDouble() ?? 0,
      interruptions: json['interruptions'] ?? 0,
      quality: json['quality'] ?? 'Good',
      deepSleep: json['deep_sleep']?.toDouble(),
      remSleep: json['rem_sleep']?.toDouble(),
      lightSleep: json['light_sleep']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'bed_hour': bedTime.hour,
      'bed_minute': bedTime.minute,
      'wake_hour': wakeTime.hour,
      'wake_minute': wakeTime.minute,
      'duration': duration,
      'interruptions': interruptions,
      'quality': quality,
      'deep_sleep': deepSleep,
      'rem_sleep': remSleep,
      'light_sleep': lightSleep,
    };
  }
}

class DailyNutrition {
  final DateTime date;
  final int totalCalories;
  final int goalCalories;
  final double protein;
  final double carbs;
  final double fat;
  final int waterGlasses;
  final List<Meal> meals;

  DailyNutrition({
    required this.date,
    required this.totalCalories,
    required this.goalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waterGlasses,
    required this.meals,
  });

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    return DailyNutrition(
      date: DateTime.parse(json['date']),
      totalCalories: json['total_calories'] ?? 0,
      goalCalories: json['goal_calories'] ?? 2000,
      protein: json['protein']?.toDouble() ?? 0,
      carbs: json['carbs']?.toDouble() ?? 0,
      fat: json['fat']?.toDouble() ?? 0,
      waterGlasses: json['water_glasses'] ?? 0,
      meals: (json['meals'] as List? ?? [])
          .map((m) => Meal.fromJson(m))
          .toList(),
    );
  }
}

class Hydration {
  final String id;
  final int amount; // in ml
  final DateTime time;
  final String? type; // water, sports drink, juice, etc.
  final String? notes;

  Hydration({
    required this.id,
    required this.amount,
    required this.time,
    this.type,
    this.notes,
  });

  factory Hydration.fromJson(Map<String, dynamic> json) {
    return Hydration(
      id: json['id'].toString(),
      amount: json['amount'] ?? 0,
      time: DateTime.parse(json['time']),
      type: json['type'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'time': time.toIso8601String(),
      'type': type,
      'notes': notes,
    };
  }
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String unit;
  final List<DateTime> scheduledTimes;
  final List<bool> taken;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final String? instructions;
  final String? prescribedBy;
  final String? color; // For UI differentiation
  final bool isActive;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.scheduledTimes,
    required this.taken,
    required this.startDate,
    this.endDate,
    this.notes,
    this.instructions,
    this.prescribedBy,
    this.color,
    this.isActive = true,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Handle scheduled_times - ensure it's a List
    List<DateTime> scheduledTimes = [];
    if (json['scheduled_times'] != null && json['scheduled_times'] is List) {
      scheduledTimes = (json['scheduled_times'] as List)
          .where((t) => t != null)
          .map((t) {
            try {
              return DateTime.parse(t.toString());
            } catch (e) {
              debugPrint('Error parsing scheduled time: $e');
              return DateTime.now();
            }
          })
          .toList();
    }

    // Handle taken - ensure it's a List of booleans
    List<bool> taken = [];
    if (json['taken'] != null && json['taken'] is List) {
      taken = (json['taken'] as List)
          .map((t) => t == true || t == 1 || t == '1' || t == 'true')
          .toList();
    }

    // If taken list is empty but we have scheduled times, initialize with false
    if (taken.isEmpty && scheduledTimes.isNotEmpty) {
      taken = List.generate(scheduledTimes.length, (index) => false);
    }

    // If taken list length doesn't match scheduled times, adjust it
    if (taken.isNotEmpty && scheduledTimes.isNotEmpty && taken.length != scheduledTimes.length) {
      List<bool> adjustedTaken = [];
      for (int i = 0; i < scheduledTimes.length; i++) {
        if (i < taken.length) {
          adjustedTaken.add(taken[i]);
        } else {
          adjustedTaken.add(false);
        }
      }
      taken = adjustedTaken;
    }

    return Medication(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      unit: json['unit'] ?? 'mg',
      scheduledTimes: scheduledTimes,
      taken: taken,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      notes: json['notes'],
      instructions: json['instructions'],
      prescribedBy: json['prescribed_by'],
      color: json['color'],
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1' || json['is_active'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'scheduled_times': scheduledTimes.map((t) => t.toIso8601String()).toList(),
      'taken': taken.map((t) => t ? 1 : 0).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'instructions': instructions,
      'prescribed_by': prescribedBy,
      'color': color,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class DailyHydration {
  final DateTime date;
  final int totalAmount;
  final int goalAmount;
  final List<Hydration> entries;

  DailyHydration({
    required this.date,
    required this.totalAmount,
    required this.goalAmount,
    required this.entries,
  });

  factory DailyHydration.fromJson(Map<String, dynamic> json) {
    return DailyHydration(
      date: DateTime.parse(json['date']),
      totalAmount: json['total_amount'] ?? 0,
      goalAmount: json['goal_amount'] ?? 2500,
      entries: (json['entries'] as List? ?? [])
          .map((e) => Hydration.fromJson(e))
          .toList(),
    );
  }
}