import 'package:flutter/material.dart';

class SleepLog {
  final int id;
  final int userId;
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  final int interruptions;
  final String sleepQuality;
  final DateTime sleepDate;
  final double totalHours;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepLog({
    required this.id,
    required this.userId,
    required this.bedtime,
    required this.wakeTime,
    required this.interruptions,
    required this.sleepQuality,
    required this.sleepDate,
    required this.totalHours,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to TimeOfDay
    TimeOfDay parseTime(dynamic timeStr) {
      if (timeStr == null) return const TimeOfDay(hour: 0, minute: 0);
      final parts = timeStr.toString().split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    // Helper to safely convert any value to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to safely convert any value to int
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper to safely parse DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return SleepLog(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      bedtime: parseTime(json['bedtime']),
      wakeTime: parseTime(json['wake_time']),
      interruptions: parseInt(json['interruptions']),
      sleepQuality: json['sleep_quality']?.toString() ?? 'Good',
      sleepDate: parseDateTime(json['sleep_date']),
      totalHours: parseDouble(json['total_hours']),
      notes: json['notes']?.toString(),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bedtime': '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}:00',
      'wake_time': '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}:00',
      'interruptions': interruptions,
      'sleep_quality': sleepQuality,
      'sleep_date': sleepDate.toIso8601String().split('T')[0],
      'total_hours': totalHours,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedBedtime {
    return '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedWakeTime {
    return '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}';
  }

  // Get absolute hours (handle negative values from backend)
  double get absoluteTotalHours {
    return totalHours.abs();
  }

  Color get qualityColor {
    switch (sleepQuality.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get qualityDisplay {
    switch (sleepQuality.toLowerCase()) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return sleepQuality;
    }
  }
}

class WeeklySleepStat {
  final int dayOfWeek;
  final String dayName;
  final int logCount;
  final double avgHours;
  final double avgInterruptions;
  final int excellentCount;
  final int goodCount;
  final int fairCount;
  final int poorCount;
  final String? mostCommonBedtime;
  final String? mostCommonWaketime;

  WeeklySleepStat({
    required this.dayOfWeek,
    required this.dayName,
    required this.logCount,
    required this.avgHours,
    required this.avgInterruptions,
    required this.excellentCount,
    required this.goodCount,
    required this.fairCount,
    required this.poorCount,
    this.mostCommonBedtime,
    this.mostCommonWaketime,
  });

  factory WeeklySleepStat.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return WeeklySleepStat(
      dayOfWeek: parseInt(json['day_of_week']),
      dayName: json['day_name']?.toString() ?? '',
      logCount: parseInt(json['log_count']),
      avgHours: parseDouble(json['avg_hours']),
      avgInterruptions: parseDouble(json['avg_interruptions']),
      excellentCount: parseInt(json['excellent_count']),
      goodCount: parseInt(json['good_count']),
      fairCount: parseInt(json['fair_count']),
      poorCount: parseInt(json['poor_count']),
      mostCommonBedtime: json['most_common_bedtime']?.toString(),
      mostCommonWaketime: json['most_common_waketime']?.toString(),
    );
  }
}

class SleepQualityType {
  final String value;
  final String label;
  final String color;
  final String description;

  SleepQualityType({
    required this.value,
    required this.label,
    required this.color,
    required this.description,
  });

  factory SleepQualityType.fromJson(Map<String, dynamic> json) {
    return SleepQualityType(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      color: json['color']?.toString() ?? '#888888',
      description: json['description']?.toString() ?? '',
    );
  }

  Color get colorValue {
    try {
      final colorStr = color.replaceFirst('#', '0xff');
      return Color(int.parse(colorStr));
    } catch (e) {
      return Colors.grey;
    }
  }
}

// Additional model classes needed for the provider
class SleepSummary {
  final int totalLogs;
  final double averageSleepHours;
  final double averageInterruptions;
  final double bestSleepHours;
  final double worstSleepHours;
  final Map<String, dynamic> qualityDistribution;
  final String mostCommonQuality;

  SleepSummary({
    required this.totalLogs,
    required this.averageSleepHours,
    required this.averageInterruptions,
    required this.bestSleepHours,
    required this.worstSleepHours,
    required this.qualityDistribution,
    required this.mostCommonQuality,
  });

  factory SleepSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return SleepSummary(
      totalLogs: parseInt(json['total_logs']),
      averageSleepHours: parseDouble(json['average_sleep_hours']),
      averageInterruptions: parseDouble(json['average_interruptions']),
      bestSleepHours: parseDouble(json['best_sleep_hours']),
      worstSleepHours: parseDouble(json['worst_sleep_hours']),
      qualityDistribution: json['quality_distribution'] as Map<String, dynamic>? ?? {},
      mostCommonQuality: json['most_common_quality']?.toString() ?? 'No data',
    );
  }
}

class SleepComparison {
  final Map<String, dynamic> currentWeek;
  final Map<String, dynamic> previousWeek;
  final Map<String, dynamic> changes;

  SleepComparison({
    required this.currentWeek,
    required this.previousWeek,
    required this.changes,
  });

  factory SleepComparison.fromJson(Map<String, dynamic> json) {
    return SleepComparison(
      currentWeek: json['current_week'] as Map<String, dynamic>? ?? {},
      previousWeek: json['previous_week'] as Map<String, dynamic>? ?? {},
      changes: json['changes'] as Map<String, dynamic>? ?? {},
    );
  }
}

class SleepConsistency {
  final double consistencyScore;
  final int bedtimeVarianceMinutes;
  final String message;
  final bool hasData;

  SleepConsistency({
    required this.consistencyScore,
    required this.bedtimeVarianceMinutes,
    required this.message,
    required this.hasData,
  });

  factory SleepConsistency.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return SleepConsistency(
      consistencyScore: parseDouble(json['consistency_score']),
      bedtimeVarianceMinutes: parseInt(json['bedtime_variance_minutes']),
      message: json['message']?.toString() ?? '',
      hasData: json['has_data'] == true,
    );
  }
}

class SleepTrend {
  final String week;
  final double avgHours;
  final double avgInterruptions;
  final int totalLogs;
  final Map<String, int> qualityCounts;

  SleepTrend({
    required this.week,
    required this.avgHours,
    required this.avgInterruptions,
    required this.totalLogs,
    required this.qualityCounts,
  });

  factory SleepTrend.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return SleepTrend(
      week: json['week']?.toString() ?? '',
      avgHours: parseDouble(json['avg_hours']),
      avgInterruptions: parseDouble(json['avg_interruptions']),
      totalLogs: parseInt(json['total_logs']),
      qualityCounts: {
        'excellent': parseInt(json['excellent_count']),
        'good': parseInt(json['good_count']),
        'fair': parseInt(json['fair_count']),
        'poor': parseInt(json['poor_count']),
      },
    );
  }
}