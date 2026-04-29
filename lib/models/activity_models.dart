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

// Medication Schedule Class
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
    
    final hour = parts.isNotEmpty ? int.parse(parts[0]) : 8;
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    final validHour = hour.clamp(0, 23);
    final validMinute = minute.clamp(0, 59);
    
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

  bool get hasLog => id > 0;
  
  Color get statusColor {
    switch (status) {
      case 'taken': return Colors.green;
      case 'late': return Colors.orange;
      case 'missed': return Colors.red;
      case 'skipped': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'taken': return 'Taken';
      case 'late': return 'Late';
      case 'missed': return 'Missed';
      case 'skipped': return 'Skipped';
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

  bool get hasLog => logId > 0;
  
  bool get isTaken => hasLog && (status == 'taken' || status == 'late');
  bool get isPending => !hasLog;
  bool get isMissed => !hasLog && isPastDue;
  
  bool get isPastDue {
    if (hasLog) return false;
    
    final now = DateTime.now();
    final scheduledHour = scheduledTime.hour;
    final scheduledMinute = scheduledTime.minute;
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    if (currentHour > scheduledHour) return true;
    if (currentHour == scheduledHour && currentMinute >= scheduledMinute) return true;
    return false;
  }

  String get displayStatus {
    if (hasLog) {
      if (status == 'taken') return 'Taken';
      if (status == 'late') return 'Late';
      if (status == 'missed') return 'Missed';
      if (status == 'skipped') return 'Skipped';
      return status;
    }
    if (isPastDue) return 'Late';
    return 'Pending';
  }

  Color get statusColor {
    if (hasLog) {
      if (status == 'taken') return Colors.green;
      if (status == 'late') return Colors.orange;
      if (status == 'missed') return Colors.red;
      if (status == 'skipped') return Colors.grey;
      return Colors.grey;
    }
    if (isPastDue) return Colors.orange;
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
    List<MedicationSchedule> schedules = [];
    if (json['schedules'] != null && json['schedules'] is List) {
      schedules = (json['schedules'] as List)
          .map((s) => MedicationSchedule.fromJson(s))
          .toList();
    }

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

    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr).toLocal();
      } catch (e) {
        return DateTime.now();
      }
    }

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
          status: existingLog.hasLog ? existingLog.status : 'pending',
          logId: existingLog.id,
          notes: existingLog.notes,
        ));
      }
    }
    
    return doses;
  }

  // ===== NEW HELPER METHODS FOR MEDICATION REMINDERS AND TRACKING =====

  // Get all doses for a specific date range (for adherence tracking)
  List<MedicationDose> getDosesForDateRange(DateTime startDate, DateTime endDate) {
    final doses = <MedicationDose>[];
    
    for (DateTime date = startDate; date.isBefore(endDate); date = date.add(const Duration(days: 1))) {
      doses.addAll(getTodaysDoses(date));
    }
    
    return doses;
  }

  // Calculate adherence rate for a date range
  double getAdherenceRate(DateTime startDate, DateTime endDate) {
    final doses = getDosesForDateRange(startDate, endDate);
    if (doses.isEmpty) return 100.0;
    
    int takenCount = doses.where((d) => d.isTaken).length;
    return (takenCount / doses.length) * 100;
  }

  // Check if medication is due soon (within next X minutes)
  bool isDueSoon(int minutes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doses = getTodaysDoses(today);
    
    for (var dose in doses) {
      if (dose.isPending) {
        final minutesUntil = dose.scheduledTime.difference(now).inMinutes;
        if (minutesUntil <= minutes && minutesUntil > 0) {
          return true;
        }
      }
    }
    return false;
  }

  // Get upcoming doses (within next X hours)
  List<MedicationDose> getUpcomingDoses(int hours) {
    final doses = <MedicationDose>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var dose in getTodaysDoses(today)) {
      if (dose.isPending && dose.scheduledTime.isAfter(now)) {
        final minutesUntil = dose.scheduledTime.difference(now).inMinutes;
        if (minutesUntil <= hours * 60) {
          doses.add(dose);
        }
      }
    }
    return doses;
  }

  // Get missed doses for today
  List<MedicationDose> getMissedDoses() {
    final today = DateTime.now();
    final doses = getTodaysDoses(today);
    return doses.where((d) => d.isMissed).toList();
  }

  // Get late doses for today
  List<MedicationDose> getLateDoses() {
    final today = DateTime.now();
    final doses = getTodaysDoses(today);
    return doses.where((d) => d.isPastDue && d.isPending).toList();
  }

  // Get doses that are taken on time
  List<MedicationDose> getTakenDoses() {
    final today = DateTime.now();
    final doses = getTodaysDoses(today);
    return doses.where((d) => d.isTaken).toList();
  }

  // Get pending doses (not taken yet, not late)
  List<MedicationDose> getPendingDoses() {
    final today = DateTime.now();
    final doses = getTodaysDoses(today);
    return doses.where((d) => d.isPending && !d.isPastDue).toList();
  }

  // Get adherence summary for today
  Map<String, dynamic> getTodaysAdherenceSummary() {
    final today = DateTime.now();
    final doses = getTodaysDoses(today);
    
    int total = doses.length;
    int taken = doses.where((d) => d.isTaken).length;
    int missed = doses.where((d) => d.isMissed).length;
    int late = doses.where((d) => d.isPastDue && d.isPending).length;
    int pending = doses.where((d) => d.isPending && !d.isPastDue).length;
    
    double percentage = total > 0 ? (taken / total) * 100 : 100.0;
    
    return {
      'total': total,
      'taken': taken,
      'missed': missed,
      'late': late,
      'pending': pending,
      'percentage': percentage,
      'status': percentage == 100 ? 'complete' : (taken > 0 ? 'partial' : 'none'),
    };
  }

  // Get the next upcoming dose
  MedicationDose? getNextUpcomingDose() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doses = getTodaysDoses(today);
    
    final upcoming = doses.where((d) => d.isPending && d.scheduledTime.isAfter(now)).toList();
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return upcoming.first;
  }

  // Get time until next dose (in minutes)
  int? getMinutesUntilNextDose() {
    final nextDose = getNextUpcomingDose();
    if (nextDose == null) return null;
    
    final minutesUntil = nextDose.scheduledTime.difference(DateTime.now()).inMinutes;
    return minutesUntil > 0 ? minutesUntil : null;
  }

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