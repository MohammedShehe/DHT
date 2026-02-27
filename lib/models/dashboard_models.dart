// lib/models/dashboard_models.dart
import 'package:flutter/material.dart';

class DashboardSummary {
  final int currentStreak;
  final int totalPoints;
  final int level;
  final double levelProgress;
  final int stepsToday;
  final int caloriesBurned;
  final double sleepHours;
  final double waterGlasses;  
  final int meditationMinutes;
  final Map<String, dynamic>? goalsProgress;

  DashboardSummary({
    required this.currentStreak,
    required this.totalPoints,
    required this.level,
    required this.levelProgress,
    required this.stepsToday,
    required this.caloriesBurned,
    required this.sleepHours,
    required this.waterGlasses,  
    required this.meditationMinutes,
    this.goalsProgress,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      currentStreak: json['currentStreak'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      level: json['level'] ?? 1,
      levelProgress: (json['levelProgress'] ?? 0).toDouble(),
      stepsToday: json['stepsToday'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      sleepHours: (json['sleepHours'] ?? 0).toDouble(),
      waterGlasses: (json['waterGlasses'] ?? 0).toDouble(), 
      meditationMinutes: json['meditationMinutes'] ?? 0,
      goalsProgress: json['goalsProgress'],
    );
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class ActivitySummary {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  ActivitySummary({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.icon,
    required this.color,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      id: json['id'].toString(),
      type: json['type'] ?? 'activity',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      value: json['value'] ?? 0,
      unit: json['unit'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      icon: _getIconForType(json['type']),
      color: _getColorForType(json['type']),
    );
  }

  static IconData _getIconForType(String? type) {
    switch (type) {
      case 'steps':
        return Icons.directions_walk;
      case 'water':
        return Icons.local_drink;
      case 'sleep':
        return Icons.bedtime;
      case 'workout':
        return Icons.fitness_center;
      case 'meditation':
        return Icons.self_improvement;
      case 'calories':
        return Icons.local_fire_department;
      case 'meal':
        return Icons.restaurant;
      default:
        return Icons.notifications;
    }
  }

  static Color _getColorForType(String? type) {
    switch (type) {
      case 'steps':
        return Colors.blue;
      case 'water':
        return Colors.cyan;
      case 'sleep':
        return Colors.purple;
      case 'workout':
        return Colors.green;
      case 'meditation':
        return Colors.indigo;
      case 'calories':
        return Colors.orange;
      case 'meal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class HealthTip {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? action;

  HealthTip({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.action,
  });

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: _getIconForCategory(json['category']),
      color: _getColorForCategory(json['category']),
      action: json['action'],
    );
  }

  static IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'hydration':
        return Icons.local_drink;
      case 'activity':
        return Icons.directions_run;
      case 'sleep':
        return Icons.bedtime;
      case 'nutrition':
        return Icons.restaurant;
      case 'mindfulness':
        return Icons.self_improvement;
      default:
        return Icons.lightbulb;
    }
  }

  static Color _getColorForCategory(String? category) {
    switch (category) {
      case 'hydration':
        return Colors.blue;
      case 'activity':
        return Colors.green;
      case 'sleep':
        return Colors.purple;
      case 'nutrition':
        return Colors.orange;
      case 'mindfulness':
        return Colors.indigo;
      default:
        return Colors.teal;
    }
  }
}