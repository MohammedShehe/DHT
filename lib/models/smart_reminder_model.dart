import 'package:flutter/material.dart';

enum ReminderPriority { low, medium, high, critical }
enum ReminderCategory {
  hydration,
  activity,
  sleep,
  nutrition,
  mindfulness,
  medication,
  goal,
  streak,
  achievement
}

class SmartReminder {
  final String id;
  final String title;
  final String message;
  final ReminderCategory category;
  final ReminderPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? actionData;
  final String? actionType;
  final DateTime? expiresAt;
  final int? pointsReward;

  SmartReminder({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
    this.actionData,
    this.actionType,
    this.expiresAt,
    this.pointsReward,
  });

  // Getters for UI
  IconData get icon {
    switch (category) {
      case ReminderCategory.hydration:
        return Icons.water_drop;
      case ReminderCategory.activity:
        return Icons.directions_run;
      case ReminderCategory.sleep:
        return Icons.bedtime;
      case ReminderCategory.nutrition:
        return Icons.restaurant;
      case ReminderCategory.mindfulness:
        return Icons.self_improvement;
      case ReminderCategory.medication:
        return Icons.medication;
      case ReminderCategory.goal:
        return Icons.flag;
      case ReminderCategory.streak:
        return Icons.local_fire_department;
      case ReminderCategory.achievement:
        return Icons.emoji_events;
    }
  }

  Color get color {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.grey;
      case ReminderPriority.medium:
        return Colors.blue;
      case ReminderPriority.high:
        return Colors.orange;
      case ReminderPriority.critical:
        return Colors.red;
    }
  }

  factory SmartReminder.fromJson(Map<String, dynamic> json) {
    return SmartReminder(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      category: ReminderCategory.values.firstWhere(
        (e) => e.toString() == 'ReminderCategory.${json['category']}',
        orElse: () => ReminderCategory.goal,
      ),
      priority: ReminderPriority.values.firstWhere(
        (e) => e.toString() == 'ReminderPriority.${json['priority']}',
        orElse: () => ReminderPriority.medium,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      actionData: json['actionData'],
      actionType: json['actionType'],
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      pointsReward: json['pointsReward'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionData': actionData,
      'actionType': actionType,
      'expiresAt': expiresAt?.toIso8601String(),
      'pointsReward': pointsReward,
    };
  }
}

class SmartReminderTemplate {
  final String id;
  final String title;
  final String messageTemplate;
  final ReminderCategory category;
  final ReminderPriority priority;
  final List<String> triggers;
  final Map<String, dynamic>? actionData;
  final String? actionType;
  final int? pointsReward;

  SmartReminderTemplate({
    required this.id,
    required this.title,
    required this.messageTemplate,
    required this.category,
    required this.priority,
    required this.triggers,
    this.actionData,
    this.actionType,
    this.pointsReward,
  });

  SmartReminder createReminder({Map<String, String>? replacements}) {
    String message = messageTemplate;
    if (replacements != null) {
      replacements.forEach((key, value) {
        message = message.replaceAll('{$key}', value);
      });
    }

    return SmartReminder(
      id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      category: category,
      priority: priority,
      timestamp: DateTime.now(),
      actionData: actionData,
      actionType: actionType,
      pointsReward: pointsReward,
    );
  }
}