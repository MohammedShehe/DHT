import 'package:flutter/material.dart';

class DrinkType {
  final String value;
  final String label;
  final String color;
  final String icon;

  DrinkType({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  factory DrinkType.fromJson(Map<String, dynamic> json) {
    return DrinkType(
      value: json['value'] ?? 'water',
      label: json['label'] ?? 'Water',
      color: json['color'] ?? '#3B82F6',
      icon: json['icon'] ?? 'local_drink',
    );
  }

  Color get colorValue {
    try {
      final colorStr = color.replaceFirst('#', '0xff');
      return Color(int.parse(colorStr));
    } catch (e) {
      return Colors.blue;
    }
  }
}

class PresetAmount {
  final int value;
  final String label;
  final String icon;

  PresetAmount({
    required this.value,
    required this.label,
    required this.icon,
  });

  factory PresetAmount.fromJson(Map<String, dynamic> json) {
    return PresetAmount(
      value: json['value'] ?? 250,
      label: json['label'] ?? '250ml',
      icon: json['icon'] ?? '🌊',
    );
  }
}

class HydrationLog {
  final int id;
  final int userId;
  final int amountMl;
  final String drinkType;
  final String? customDrinkName;
  final TimeOfDay consumptionTime;
  final DateTime logDate;
  final String? notes;
  final DateTime createdAt;

  HydrationLog({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.drinkType,
    this.customDrinkName,
    required this.consumptionTime,
    required this.logDate,
    this.notes,
    required this.createdAt,
  });

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String? timeStr) {
      if (timeStr == null) return const TimeOfDay(hour: 12, minute: 0);
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      try {
        final dateStr = dateValue.toString();
        if (dateStr.contains('T')) {
          return DateTime.parse(dateStr);
        }
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (e) {}
      return DateTime.now();
    }

    return HydrationLog(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      amountMl: json['amount_ml'] as int? ?? 0,
      drinkType: json['drink_type']?.toString() ?? 'water',
      customDrinkName: json['custom_drink_name']?.toString(),
      consumptionTime: parseTime(json['consumption_time']?.toString()),
      logDate: parseDate(json['log_date']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount_ml': amountMl,
      'drink_type': drinkType,
      'custom_drink_name': customDrinkName,
      'consumption_time': '${consumptionTime.hour.toString().padLeft(2, '0')}:${consumptionTime.minute.toString().padLeft(2, '0')}:00',
      'log_date': '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}',
      'notes': notes,
    };
  }

  String get formattedTime {
    return '${consumptionTime.hour.toString().padLeft(2, '0')}:${consumptionTime.minute.toString().padLeft(2, '0')}';
  }

  String get displayName {
    if (customDrinkName != null && customDrinkName!.isNotEmpty) {
      return customDrinkName!;
    }
    return drinkType;
  }
}

class HydrationGoal {
  final int? id;
  final int userId;
  final int dailyTargetMl;
  final DateTime createdAt;
  final DateTime updatedAt;

  HydrationGoal({
    this.id,
    required this.userId,
    required this.dailyTargetMl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HydrationGoal.fromJson(Map<String, dynamic> json) {
    return HydrationGoal(
      id: json['id'] as int?,
      userId: json['user_id'] as int? ?? 0,
      dailyTargetMl: json['daily_target_ml'] as int? ?? 2500,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : DateTime.now(),
    );
  }
}

class DailyHydrationStats {
  final DateTime date;
  final int totalMl;
  final int totalEntries;
  final int dailyTargetMl;
  final int percentage;
  final int remainingMl;
  final bool completed;
  final Map<String, int> breakdown;

  DailyHydrationStats({
    required this.date,
    required this.totalMl,
    required this.totalEntries,
    required this.dailyTargetMl,
    required this.percentage,
    required this.remainingMl,
    required this.completed,
    required this.breakdown,
  });

  factory DailyHydrationStats.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    
    return DailyHydrationStats(
      date: DateTime.parse(json['date']),
      totalMl: json['total_ml'] as int? ?? 0,
      totalEntries: json['total_entries'] as int? ?? 0,
      dailyTargetMl: json['daily_target_ml'] as int? ?? 2500,
      percentage: json['percentage'] as int? ?? 0,
      remainingMl: json['remaining_ml'] as int? ?? 0,
      completed: json['completed'] == true,
      breakdown: {
        'water': breakdown['water'] as int? ?? 0,
        'sports_drink': breakdown['sports_drink'] as int? ?? 0,
        'juice': breakdown['juice'] as int? ?? 0,
        'tea': breakdown['tea'] as int? ?? 0,
        'coffee': breakdown['coffee'] as int? ?? 0,
        'milk': breakdown['milk'] as int? ?? 0,
        'soda': breakdown['soda'] as int? ?? 0,
        'other': breakdown['other'] as int? ?? 0,
      },
    );
  }
}

class WeeklyHydrationStats {
  final DateTime date;
  final String dayName;
  final int totalMl;
  final int totalEntries;
  final int dailyTarget;
  final int percentage;
  final Map<String, int> breakdown;

  WeeklyHydrationStats({
    required this.date,
    required this.dayName,
    required this.totalMl,
    required this.totalEntries,
    required this.dailyTarget,
    required this.percentage,
    required this.breakdown,
  });

  factory WeeklyHydrationStats.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    
    return WeeklyHydrationStats(
      date: DateTime.parse(json['date']),
      dayName: json['day_name']?.toString() ?? '',
      totalMl: json['total_ml'] as int? ?? 0,
      totalEntries: json['total_entries'] as int? ?? 0,
      dailyTarget: json['daily_target'] as int? ?? 2500,
      percentage: json['percentage'] as int? ?? 0,
      breakdown: {
        'water': breakdown['water'] as int? ?? 0,
        'sports_drink': breakdown['sports_drink'] as int? ?? 0,
        'juice': breakdown['juice'] as int? ?? 0,
        'tea': breakdown['tea'] as int? ?? 0,
        'coffee': breakdown['coffee'] as int? ?? 0,
        'milk': breakdown['milk'] as int? ?? 0,
        'soda': breakdown['soda'] as int? ?? 0,
        'other': breakdown['other'] as int? ?? 0,
      },
    );
  }
}

class DrinkTypeDistribution {
  final String drinkType;
  final String label;
  final String color;
  final String icon;
  final int totalMl;
  final int entryCount;
  final int percentage;

  DrinkTypeDistribution({
    required this.drinkType,
    required this.label,
    required this.color,
    required this.icon,
    required this.totalMl,
    required this.entryCount,
    required this.percentage,
  });

  factory DrinkTypeDistribution.fromJson(Map<String, dynamic> json) {
    return DrinkTypeDistribution(
      drinkType: json['drink_type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      color: json['color']?.toString() ?? '#6B7280',
      icon: json['icon']?.toString() ?? 'local_drink',
      totalMl: json['total_ml'] as int? ?? 0,
      entryCount: json['entry_count'] as int? ?? 0,
      percentage: json['percentage'] as int? ?? 0,
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

class HourlyHydrationDistribution {
  final int hour;
  final String label;
  final int totalMl;
  final int entryCount;

  HourlyHydrationDistribution({
    required this.hour,
    required this.label,
    required this.totalMl,
    required this.entryCount,
  });

  factory HourlyHydrationDistribution.fromJson(Map<String, dynamic> json) {
    return HourlyHydrationDistribution(
      hour: json['hour'] as int? ?? 0,
      label: json['label']?.toString() ?? '',
      totalMl: json['total_ml'] as int? ?? 0,
      entryCount: json['entry_count'] as int? ?? 0,
    );
  }
}

class HydrationSummaryStats {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final int totalEntries;
  final int totalMl;
  final int avgDailyMl;
  final int avgPerEntry;
  final int daysWithData;
  final int dailyTarget;
  final int achievementPercentage;

  HydrationSummaryStats({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalEntries,
    required this.totalMl,
    required this.avgDailyMl,
    required this.avgPerEntry,
    required this.daysWithData,
    required this.dailyTarget,
    required this.achievementPercentage,
  });

  factory HydrationSummaryStats.fromJson(Map<String, dynamic> json) {
    return HydrationSummaryStats(
      period: json['period']?.toString() ?? 'week',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalEntries: json['total_entries'] as int? ?? 0,
      totalMl: json['total_ml'] as int? ?? 0,
      avgDailyMl: json['avg_daily_ml'] as int? ?? 0,
      avgPerEntry: json['avg_per_entry'] as int? ?? 0,
      daysWithData: json['days_with_data'] as int? ?? 0,
      dailyTarget: json['daily_target'] as int? ?? 2500,
      achievementPercentage: json['achievement_percentage'] as int? ?? 0,
    );
  }
}

class HydrationTrend {
  final DateTime date;
  final int totalMl;
  final int entryCount;
  final int waterMl;
  final int otherMl;
  final int percentage;
  final int targetMl;

  HydrationTrend({
    required this.date,
    required this.totalMl,
    required this.entryCount,
    required this.waterMl,
    required this.otherMl,
    required this.percentage,
    required this.targetMl,
  });

  factory HydrationTrend.fromJson(Map<String, dynamic> json) {
    return HydrationTrend(
      date: DateTime.parse(json['date']),
      totalMl: json['total_ml'] as int? ?? 0,
      entryCount: json['entry_count'] as int? ?? 0,
      waterMl: json['water_ml'] as int? ?? 0,
      otherMl: json['other_ml'] as int? ?? 0,
      percentage: json['percentage'] as int? ?? 0,
      targetMl: json['target_ml'] as int? ?? 2500,
    );
  }
}