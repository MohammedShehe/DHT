import 'package:flutter/material.dart';

class WorkoutType {
  final int id;
  final String name;
  final bool isCustom;
  final int? createdBy;

  WorkoutType({
    required this.id,
    required this.name,
    this.isCustom = false,
    this.createdBy,
  });

  factory WorkoutType.fromJson(Map<String, dynamic> json) {
    return WorkoutType(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      isCustom: json['is_custom'] == 1 || json['is_custom'] == true || json['is_custom'] == '1',
      createdBy: _toIntNullable(json['created_by']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_custom': isCustom ? 1 : 0,
      'created_by': createdBy,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class WorkoutDetail {
  final int id;
  final int? workoutTypeId;
  final String? customWorkoutName;
  final DateTime workoutTime;
  final int durationMinutes;
  final String intensity;
  final double? distance;
  final int? heartRate;
  final String? feeling;
  final String? notes;
  final int? caloriesBurned;
  final String? workoutTypeName;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutDetail({
    required this.id,
    this.workoutTypeId,
    this.customWorkoutName,
    required this.workoutTime,
    required this.durationMinutes,
    required this.intensity,
    this.distance,
    this.heartRate,
    this.feeling,
    this.notes,
    this.caloriesBurned,
    this.workoutTypeName,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    if (customWorkoutName != null && customWorkoutName!.isNotEmpty) {
      return customWorkoutName!;
    }
    return workoutTypeName ?? 'Workout';
  }

  String get formattedTime {
    final localTime = workoutTime.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }

  // Get the date in local timezone for consistent display
  DateTime get localDate {
    return DateTime(workoutTime.year, workoutTime.month, workoutTime.day);
  }

  Color get intensityColor {
    switch (intensity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'very_high':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String get intensityDisplay {
    switch (intensity.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'High';
      case 'very_high':
        return 'Very High';
      default:
        return intensity;
    }
  }

  String get feelingDisplay {
    switch (feeling) {
      case 'very_bad':
        return 'Very Bad';
      case 'bad':
        return 'Bad';
      case 'neutral':
        return 'Neutral';
      case 'good':
        return 'Good';
      case 'excellent':
        return 'Excellent';
      default:
        return feeling ?? 'Not recorded';
    }
  }

  Color get feelingColor {
    switch (feeling) {
      case 'very_bad':
        return Colors.red;
      case 'bad':
        return Colors.orange;
      case 'neutral':
        return Colors.grey;
      case 'good':
        return Colors.lightGreen;
      case 'excellent':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  factory WorkoutDetail.fromJson(Map<String, dynamic> json) {
    // Parse workout_time with proper timezone handling
    DateTime workoutTime;
    if (json['workout_time'] != null) {
      // Parse as UTC and convert to local
      workoutTime = DateTime.parse(json['workout_time'] as String).toLocal();
    } else {
      workoutTime = DateTime.now();
    }

    return WorkoutDetail(
      id: _toInt(json['id']),
      workoutTypeId: _toIntNullable(json['workout_type_id']),
      customWorkoutName: json['custom_workout_name']?.toString(),
      workoutTime: workoutTime,
      durationMinutes: _toInt(json['duration_minutes']),
      intensity: json['intensity']?.toString() ?? 'moderate',
      distance: _toDoubleNullable(json['distance']),
      heartRate: _toIntNullable(json['heart_rate']),
      feeling: json['feeling']?.toString(),
      notes: json['notes']?.toString(),
      caloriesBurned: _toIntNullable(json['calories_burned']),
      workoutTypeName: json['workout_type_name']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String).toLocal() 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String).toLocal() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Send time in UTC to server
    final utcTime = DateTime.utc(
      workoutTime.year,
      workoutTime.month,
      workoutTime.day,
      workoutTime.hour,
      workoutTime.minute,
    );
    
    return {
      'workout_type_id': workoutTypeId,
      'custom_workout_name': customWorkoutName,
      'workout_time': utcTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'intensity': intensity,
      'distance': distance,
      'heart_rate': heartRate,
      'feeling': feeling,
      'notes': notes,
    };
  }
}

class CreateWorkoutRequest {
  int? workoutTypeId;
  String? customWorkoutName;
  DateTime workoutTime;
  int durationMinutes;
  String intensity;
  double? distance;
  int? heartRate;
  String? feeling;
  String? notes;

  CreateWorkoutRequest({
    this.workoutTypeId,
    this.customWorkoutName,
    required this.workoutTime,
    required this.durationMinutes,
    required this.intensity,
    this.distance,
    this.heartRate,
    this.feeling,
    this.notes,
  }) {
    if (workoutTypeId == null && (customWorkoutName == null || customWorkoutName!.isEmpty)) {
      throw ArgumentError('Either workoutTypeId or customWorkoutName must be provided');
    }
  }

  Map<String, dynamic> toJson() {
    // Send time in UTC to server
    final utcTime = DateTime.utc(
      workoutTime.year,
      workoutTime.month,
      workoutTime.day,
      workoutTime.hour,
      workoutTime.minute,
    );
    
    return {
      'workout_type_id': workoutTypeId,
      'custom_workout_name': customWorkoutName,
      'workout_time': utcTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'intensity': intensity,
      'distance': distance,
      'heart_rate': heartRate,
      'feeling': feeling,
      'notes': notes,
    };
  }
}

class UpdateWorkoutRequest {
  int? workoutTypeId;
  String? customWorkoutName;
  DateTime? workoutTime;
  int? durationMinutes;
  String? intensity;
  double? distance;
  int? heartRate;
  String? feeling;
  String? notes;

  UpdateWorkoutRequest({
    this.workoutTypeId,
    this.customWorkoutName,
    this.workoutTime,
    this.durationMinutes,
    this.intensity,
    this.distance,
    this.heartRate,
    this.feeling,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (workoutTypeId != null) json['workout_type_id'] = workoutTypeId;
    if (customWorkoutName != null) json['custom_workout_name'] = customWorkoutName;
    if (workoutTime != null) {
      final utcTime = DateTime.utc(
        workoutTime!.year,
        workoutTime!.month,
        workoutTime!.day,
        workoutTime!.hour,
        workoutTime!.minute,
      );
      json['workout_time'] = utcTime.toIso8601String();
    }
    if (durationMinutes != null) json['duration_minutes'] = durationMinutes;
    if (intensity != null) json['intensity'] = intensity;
    if (distance != null) json['distance'] = distance;
    if (heartRate != null) json['heart_rate'] = heartRate;
    if (feeling != null) json['feeling'] = feeling;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

class WorkoutStats {
  final int workoutCount;
  final int totalDuration;
  final int totalCalories;
  final double totalDistance;
  final double? avgHeartRate;

  WorkoutStats({
    required this.workoutCount,
    required this.totalDuration,
    required this.totalCalories,
    required this.totalDistance,
    this.avgHeartRate,
  });

  factory WorkoutStats.fromJson(Map<String, dynamic> json) {
    return WorkoutStats(
      workoutCount: _toInt(json['workout_count']),
      totalDuration: _toInt(json['total_duration']),
      totalCalories: _toInt(json['total_calories']),
      totalDistance: _toDouble(json['total_distance']),
      avgHeartRate: _toDoubleNullable(json['avg_heart_rate']),
    );
  }
}

class WeeklyWorkoutStats {
  final DateTime date;
  final int workoutCount;
  final int totalDuration;
  final int totalCalories;
  final double totalDistance;
  final double? avgHeartRate;

  WeeklyWorkoutStats({
    required this.date,
    required this.workoutCount,
    required this.totalDuration,
    required this.totalCalories,
    required this.totalDistance,
    this.avgHeartRate,
  });

  // Get the date in local timezone
  DateTime get localDate {
    return DateTime(date.year, date.month, date.day);
  }

  factory WeeklyWorkoutStats.fromJson(Map<String, dynamic> json) {
    // Parse date and convert to local date (ignore time)
    DateTime parsedDate;
    if (json['date'] != null) {
      final dateStr = json['date'] as String;
      // Handle YYYY-MM-DD format
      if (dateStr.contains('T')) {
        parsedDate = DateTime.parse(dateStr).toLocal();
      } else {
        final parts = dateStr.split('-');
        parsedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } else {
      parsedDate = DateTime.now();
    }
    
    return WeeklyWorkoutStats(
      date: parsedDate,
      workoutCount: _toInt(json['workout_count']),
      totalDuration: _toInt(json['total_duration']),
      totalCalories: _toInt(json['total_calories']),
      totalDistance: _toDouble(json['total_distance']),
      avgHeartRate: _toDoubleNullable(json['avg_heart_rate']),
    );
  }
}

class IntensityDistribution {
  final String intensity;
  final int count;
  final int totalDuration;

  IntensityDistribution({
    required this.intensity,
    required this.count,
    required this.totalDuration,
  });

  factory IntensityDistribution.fromJson(Map<String, dynamic> json) {
    return IntensityDistribution(
      intensity: json['intensity']?.toString() ?? '',
      count: _toInt(json['count']),
      totalDuration: _toInt(json['total_duration']),
    );
  }
}

class WorkoutTypeStats {
  final String workoutName;
  final int count;
  final int totalDuration;
  final int totalCalories;
  final double? avgHeartRate;

  WorkoutTypeStats({
    required this.workoutName,
    required this.count,
    required this.totalDuration,
    required this.totalCalories,
    this.avgHeartRate,
  });

  factory WorkoutTypeStats.fromJson(Map<String, dynamic> json) {
    return WorkoutTypeStats(
      workoutName: json['workout_name']?.toString() ?? '',
      count: _toInt(json['count']),
      totalDuration: _toInt(json['total_duration']),
      totalCalories: _toInt(json['total_calories']),
      avgHeartRate: _toDoubleNullable(json['avg_heart_rate']),
    );
  }
}

// Helper functions for safe type conversion
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}