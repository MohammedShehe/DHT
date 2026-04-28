import 'package:flutter/material.dart';
import 'meal_models.dart';

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
  final int amount;
  final DateTime time;
  final String? type;
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

// Medication Schedule Class - FIXED
class MedicationSchedule {
  final int? id;
  final TimeOfDay timeOfDay;
  final String daysOfWeek;
  final double? dosageOverride;
  final String? unitOverride;

  MedicationSchedule({
    this.id,
    required this.timeOfDay,
    required this.daysOfWeek,
    this.dosageOverride,
    this.unitOverride,
  });

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    final timeStr = json['time_of_day']?.toString() ?? '08:00:00';
    final parts = timeStr.split(':');
    
    // Ensure we have valid hour and minute
    final hour = parts.isNotEmpty ? int.parse(parts[0]) : 8;
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    
    // Validate hour and minute ranges
    final validHour = hour.clamp(0, 23);
    final validMinute = minute.clamp(0, 59);
    
    debugPrint('Parsing schedule time: $timeStr -> hour: $validHour, minute: $validMinute');
    
    return MedicationSchedule(
      id: json['id'] as int?,
      timeOfDay: TimeOfDay(hour: validHour, minute: validMinute),
      daysOfWeek: json['days_of_week']?.toString() ?? 'all',
      dosageOverride: json['dosage_override'] != null 
          ? double.tryParse(json['dosage_override'].toString()) 
          : null,
      unitOverride: json['unit_override']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'time_of_day': '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}:00',
      'days_of_week': daysOfWeek,
      if (dosageOverride != null) 'dosage_override': dosageOverride,
      if (unitOverride != null) 'unit_override': unitOverride,
    };
  }

  String get formattedTime {
    final period = timeOfDay.hour >= 12 ? 'PM' : 'AM';
    final displayHour = timeOfDay.hour == 0 ? 12 : (timeOfDay.hour > 12 ? timeOfDay.hour - 12 : timeOfDay.hour);
    return '$displayHour:${timeOfDay.minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedDays {
    if (daysOfWeek == 'all') return 'Every day';
    if (daysOfWeek == 'weekdays') return 'Weekdays';
    if (daysOfWeek == 'weekends') return 'Weekends';
    
    const dayMap = {
      'sun': 'Sun', 'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed',
      'thu': 'Thu', 'fri': 'Fri', 'sat': 'Sat'
    };
    return daysOfWeek.split(',').map((d) => dayMap[d.trim()] ?? d).join(', ');
  }
}

// Medication Adherence Log Entry
class MedicationAdherenceLogEntry {
  final int id;
  final int? scheduleId;
  final DateTime logDate;
  final TimeOfDay logTime;
  final String status;
  final TimeOfDay? actualTime;
  final String? notes;

  MedicationAdherenceLogEntry({
    required this.id,
    this.scheduleId,
    required this.logDate,
    required this.logTime,
    required this.status,
    this.actualTime,
    this.notes,
  });

  factory MedicationAdherenceLogEntry.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String? timeStr) {
      if (timeStr == null) return const TimeOfDay(hour: 0, minute: 0);
      final parts = timeStr.split(':');
      // Ensure we have valid hour and minute
      final hour = parts.isNotEmpty ? int.parse(parts[0]) : 0;
      final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      final validHour = hour.clamp(0, 23);
      final validMinute = minute.clamp(0, 59);
      return TimeOfDay(hour: validHour, minute: validMinute);
    }

    return MedicationAdherenceLogEntry(
      id: json['id'] as int,
      scheduleId: json['schedule_id'] as int?,
      logDate: DateTime.parse(json['log_date']),
      logTime: parseTime(json['log_time']),
      status: json['status'] as String? ?? 'taken',
      actualTime: json['actual_time'] != null ? parseTime(json['actual_time']) : null,
      notes: json['notes'] as String?,
    );
  }

  factory MedicationAdherenceLogEntry.empty() {
    return MedicationAdherenceLogEntry(
      id: 0,
      logDate: DateTime.now(),
      logTime: const TimeOfDay(hour: 0, minute: 0),
      status: 'pending',
    );
  }

  Color get statusColor {
    switch (status) {
      case 'taken': return Colors.green;
      case 'late': return Colors.orange;
      case 'missed': return Colors.red;
      case 'skipped': return Colors.grey;
      case 'pending': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'taken': return 'Taken';
      case 'late': return 'Late';
      case 'missed': return 'Missed';
      case 'skipped': return 'Skipped';
      case 'pending': return 'Pending';
      default: return status;
    }
  }
}

// Medication Dose for a specific day
class MedicationDose {
  final int medicationId;
  final String medicationName;
  final int? scheduleId;
  final DateTime scheduledTime;
  final double actualDosage;
  final String unit;
  final String status;
  final int logId;
  final String? notes;

  MedicationDose({
    required this.medicationId,
    required this.medicationName,
    this.scheduleId,
    required this.scheduledTime,
    required this.actualDosage,
    required this.unit,
    required this.status,
    required this.logId,
    this.notes,
  });

  String get formattedTime {
    final period = scheduledTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = scheduledTime.hour == 0 ? 12 : (scheduledTime.hour > 12 ? scheduledTime.hour - 12 : scheduledTime.hour);
    return '$displayHour:${scheduledTime.minute.toString().padLeft(2, '0')} $period';
  }

  bool get isTaken => status == 'taken' || status == 'late';
  bool get isPending => status == 'pending';
  bool get isMissed => status == 'missed';
  bool get isPastDue => !isTaken && scheduledTime.isBefore(DateTime.now());

  Color get statusColor {
    if (isTaken) return Colors.green;
    if (isPastDue && isPending) return Colors.red;
    if (isMissed) return Colors.red;
    return Colors.grey;
  }
}

// Main Medication Class
class Medication {
  final int id;
  final String name;
  final double dosage;
  final String unit;
  final String color;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final String? prescribedBy;
  final String? notes;
  final bool isActive;
  final List<MedicationSchedule> schedules;
  final Map<String, List<MedicationAdherenceLogEntry>> adherenceLogs;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.color,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.prescribedBy,
    this.notes,
    this.isActive = true,
    required this.schedules,
    this.adherenceLogs = const {},
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Parse schedules
    List<MedicationSchedule> schedules = [];
    if (json['schedules'] != null && json['schedules'] is List) {
      schedules = (json['schedules'] as List)
          .map((s) => MedicationSchedule.fromJson(s))
          .toList();
      debugPrint('Parsed ${schedules.length} schedules for medication ${json['name']}');
    }

    // Parse adherence logs
    Map<String, List<MedicationAdherenceLogEntry>> adherenceLogs = {};
    if (json['adherence_logs'] != null && json['adherence_logs'] is List) {
      for (var log in json['adherence_logs']) {
        final date = log['log_date'] as String?;
        if (date != null) {
          if (!adherenceLogs.containsKey(date)) {
            adherenceLogs[date] = [];
          }
          adherenceLogs[date]!.add(MedicationAdherenceLogEntry.fromJson(log));
        }
      }
    }

    // Parse dates - handle UTC to local conversion
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr).toLocal();
      } catch (e) {
        return DateTime.now();
      }
    }

    // Parse dosage safely
    double parseDosage(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Medication(
      id: json['id'] as int,
      name: json['name'] as String,
      dosage: parseDosage(json['dosage']),
      unit: json['unit'] as String,
      color: json['color'] as String? ?? '#3B82F6',
      startDate: parseDate(json['start_date'] as String?),
      endDate: json['end_date'] != null ? parseDate(json['end_date'] as String) : null,
      instructions: json['instructions'] as String?,
      prescribedBy: json['prescribed_by'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      schedules: schedules,
      adherenceLogs: adherenceLogs,
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

  String get dosageDisplay {
    return '${dosage.toStringAsFixed(dosage.truncate() == dosage ? 0 : 1)} $unit';
  }

  bool get isCurrentlyActive {
    final today = DateTime.now();
    if (startDate.isAfter(today)) return false;
    if (endDate != null && endDate!.isBefore(today)) return false;
    return isActive;
  }

  // Get today's scheduled doses with their taken status
  List<MedicationDose> getTodaysDoses(DateTime today) {
    final doses = <MedicationDose>[];
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todaysLogs = adherenceLogs[todayStr] ?? [];

    for (var schedule in schedules) {
      if (_shouldTakeToday(schedule, today)) {
        final doseTime = DateTime(
          today.year,
          today.month,
          today.day,
          schedule.timeOfDay.hour,
          schedule.timeOfDay.minute,
        );
        
        // Check if already taken
        final existingLog = todaysLogs.firstWhere(
          (log) => log.scheduleId == schedule.id,
          orElse: () => MedicationAdherenceLogEntry.empty(),
        );
        
        doses.add(MedicationDose(
          medicationId: id,
          medicationName: name,
          scheduleId: schedule.id,
          scheduledTime: doseTime,
          actualDosage: schedule.dosageOverride ?? dosage,
          unit: schedule.unitOverride ?? unit,
          status: existingLog.id > 0 ? existingLog.status : 'pending',
          logId: existingLog.id,
          notes: existingLog.notes,
        ));
      }
    }
    
    debugPrint('Medication ${name}: generated ${doses.length} doses for ${todayStr}');
    return doses;
  }

  // Check if medication should be taken on a specific day
  bool _shouldTakeToday(MedicationSchedule schedule, DateTime date) {
    if (schedule.daysOfWeek == 'all') return true;
    if (schedule.daysOfWeek == 'weekdays') return date.weekday >= 1 && date.weekday <= 5;
    if (schedule.daysOfWeek == 'weekends') return date.weekday == 6 || date.weekday == 7;
    
    final dayName = _weekdayToShortName[date.weekday]!;
    return schedule.daysOfWeek.split(',').contains(dayName);
  }
}

const Map<int, String> _weekdayToShortName = {
  1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat', 7: 'sun',
};