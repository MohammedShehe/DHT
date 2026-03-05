import 'dart:convert';
import 'package:flutter/material.dart';

enum RepeatType { all, weekdays, weekends, custom }
enum NotificationAction { openActivity, logWater, logMeal, takeMedication, meditate, noAction }

class NotificationPreference {
  final int? id;
  final String notificationType;
  final bool isEnabled;
  final String title;
  final String message;
  final TimeOfDay time;
  final String repeatDays;
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final bool isPredefined;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreference({
    this.id,
    this.notificationType = 'custom',
    this.isEnabled = true,
    required this.title,
    required this.message,
    required this.time,
    this.repeatDays = 'all',
    this.actionType,
    this.actionData,
    this.isPredefined = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    // Parse time string (HH:MM:SS or HH:MM)
    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    // Parse action data if exists
    Map<String, dynamic>? actionData;
    if (json['action_data'] != null) {
      try {
        if (json['action_data'] is String) {
          actionData = jsonDecode(json['action_data']);
        } else {
          actionData = json['action_data'];
        }
      } catch (e) {
        actionData = null;
      }
    }

    return NotificationPreference(
      id: json['id'] as int?,
      notificationType: json['notification_type'] ?? 'custom',
      isEnabled: json['is_enabled'] == 1 || json['is_enabled'] == true,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      time: parseTime(json['time'] ?? '12:00:00'),
      repeatDays: json['repeat_days'] ?? 'all',
      actionType: json['action_type'],
      actionData: actionData,
      isPredefined: json['is_predefined'] == 1 || json['is_predefined'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'notification_type': notificationType,
      'is_enabled': isEnabled ? 1 : 0,
      'title': title,
      'message': message,
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
      'repeat_days': repeatDays,
      'action_type': actionType,
      'action_data': actionData != null ? jsonEncode(actionData) : null,
      'is_predefined': isPredefined ? 1 : 0,
    };
  }

  // Convert repeatDays string to list of day indices
  List<int> get dayIndices {
    if (repeatDays == 'all') {
      return [0, 1, 2, 3, 4, 5, 6];
    } else if (repeatDays == 'weekdays') {
      return [1, 2, 3, 4, 5];
    } else if (repeatDays == 'weekends') {
      return [0, 6];
    } else {
      // Custom days like 'mon,tue,wed'
      final dayMap = {'sun': 0, 'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6};
      return repeatDays.split(',').map((d) => dayMap[d.trim()] ?? 0).toList();
    }
  }

  // Format days for display
  String get formattedDays {
    if (repeatDays == 'all') return 'Every day';
    if (repeatDays == 'weekdays') return 'Weekdays';
    if (repeatDays == 'weekends') return 'Weekends';
    
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return dayIndices.map((i) => days[i]).join(', ');
  }

  // Get notification action enum
  NotificationAction get action {
    switch (actionType) {
      case 'open_activity': return NotificationAction.openActivity;
      case 'log_water': return NotificationAction.logWater;
      case 'log_meal': return NotificationAction.logMeal;
      case 'take_medication': return NotificationAction.takeMedication;
      case 'meditate': return NotificationAction.meditate;
      default: return NotificationAction.noAction;
    }
  }

  // Get action icon
  IconData get actionIcon {
    switch (action) {
      case NotificationAction.openActivity: return Icons.fitness_center;
      case NotificationAction.logWater: return Icons.local_drink;
      case NotificationAction.logMeal: return Icons.restaurant;
      case NotificationAction.takeMedication: return Icons.medication;
      case NotificationAction.meditate: return Icons.self_improvement;
      case NotificationAction.noAction: return Icons.notifications;
    }
  }

  // Get action color
  Color get actionColor {
    switch (action) {
      case NotificationAction.openActivity: return Colors.green;
      case NotificationAction.logWater: return Colors.blue;
      case NotificationAction.logMeal: return Colors.orange;
      case NotificationAction.takeMedication: return Colors.purple;
      case NotificationAction.meditate: return Colors.indigo;
      case NotificationAction.noAction: return Colors.grey;
    }
  }
}

class FCMToken {
  final String fcmToken;
  final String? deviceType;
  final String? deviceName;
  final DateTime lastUsed;
  final DateTime createdAt;

  FCMToken({
    required this.fcmToken,
    this.deviceType,
    this.deviceName,
    required this.lastUsed,
    required this.createdAt,
  });

  factory FCMToken.fromJson(Map<String, dynamic> json) {
    return FCMToken(
      fcmToken: json['fcm_token'],
      deviceType: json['device_type'],
      deviceName: json['device_name'],
      lastUsed: json['last_used'] != null 
          ? DateTime.parse(json['last_used']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class NotificationHistory {
  final int id;
  final String title;
  final String message;
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final DateTime scheduledFor;
  final String status;
  final DateTime? sentAt;
  final DateTime createdAt;
  final String? prefTitle;
  final String? notificationType;

  NotificationHistory({
    required this.id,
    required this.title,
    required this.message,
    this.actionType,
    this.actionData,
    required this.scheduledFor,
    required this.status,
    this.sentAt,
    required this.createdAt,
    this.prefTitle,
    this.notificationType,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      actionType: json['action_type'],
      actionData: json['action_data'] != null ? jsonDecode(json['action_data']) : null,
      scheduledFor: DateTime.parse(json['scheduled_for']),
      status: json['status'],
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      prefTitle: json['pref_title'],
      notificationType: json['notification_type'],
    );
  }

  Color get statusColor {
    switch (status) {
      case 'sent': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'sent': return Icons.check_circle;
      case 'pending': return Icons.hourglass_empty;
      case 'failed': return Icons.error;
      case 'cancelled': return Icons.cancel;
      default: return Icons.info;
    }
  }
}