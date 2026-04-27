// lib/models/medication_models.dart
import 'package:flutter/material.dart';

class MedicationUnit {
  final String value;
  final String label;
  final String category;

  MedicationUnit({
    required this.value,
    required this.label,
    required this.category,
  });

  factory MedicationUnit.fromJson(Map<String, dynamic> json) {
    return MedicationUnit(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class MedicationStatus {
  final String value;
  final String label;
  final String color;
  final String icon;

  MedicationStatus({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  factory MedicationStatus.fromJson(Map<String, dynamic> json) {
    return MedicationStatus(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      color: json['color'] ?? '#888888',
      icon: json['icon'] ?? 'check_circle',
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

class MedicationSchedule {
  final int? id;
  final String timeOfDay;
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
    return MedicationSchedule(
      id: json['id'] as int?,
      timeOfDay: json['time_of_day'] ?? '08:00:00',
      daysOfWeek: json['days_of_week'] ?? 'all',
      dosageOverride: json['dosage_override'] != null 
          ? double.tryParse(json['dosage_override'].toString()) 
          : null,
      unitOverride: json['unit_override']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'time_of_day': timeOfDay,
      'days_of_week': daysOfWeek,
      if (dosageOverride != null) 'dosage_override': dosageOverride,
      if (unitOverride != null) 'unit_override': unitOverride,
    };
  }

  String get formattedTime {
    final parts = timeOfDay.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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

class Medication {
  final int id;
  final int userId;
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MedicationSchedule> schedules;

  Medication({
    required this.id,
    required this.userId,
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
    required this.createdAt,
    required this.updatedAt,
    required this.schedules,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    List<MedicationSchedule> schedules = [];
    if (json['schedules'] != null && json['schedules'] is List) {
      schedules = (json['schedules'] as List)
          .map((s) => MedicationSchedule.fromJson(s))
          .toList();
    }

    return Medication(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      dosage: json['dosage'] is int 
          ? (json['dosage'] as int).toDouble() 
          : double.parse(json['dosage'].toString()),
      unit: json['unit'] as String,
      color: json['color'] as String? ?? '#3B82F6',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      instructions: json['instructions'] as String?,
      prescribedBy: json['prescribed_by'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      schedules: schedules,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'color': color,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'instructions': instructions,
      'prescribed_by': prescribedBy,
      'notes': notes,
      'schedules': schedules.map((s) => s.toJson()).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (name.isNotEmpty) 'name': name,
      'dosage': dosage,
      'unit': unit,
      'color': color,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      if (instructions != null) 'instructions': instructions,
      if (prescribedBy != null) 'prescribed_by': prescribedBy,
      if (notes != null) 'notes': notes,
    };
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
}

class MedicationAdherenceLog {
  final int id;
  final int medicationId;
  final int? scheduleId;
  final DateTime logDate;
  final TimeOfDay logTime;
  final String status;
  final TimeOfDay? actualTime;
  final String? notes;
  final String medicationName;
  final double dosage;
  final String unit;
  final String color;
  final String? scheduledTime;

  MedicationAdherenceLog({
    required this.id,
    required this.medicationId,
    this.scheduleId,
    required this.logDate,
    required this.logTime,
    required this.status,
    this.actualTime,
    this.notes,
    required this.medicationName,
    required this.dosage,
    required this.unit,
    required this.color,
    this.scheduledTime,
  });

  factory MedicationAdherenceLog.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String? timeStr) {
      if (timeStr == null) return const TimeOfDay(hour: 0, minute: 0);
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return MedicationAdherenceLog(
      id: json['id'] as int,
      medicationId: json['medication_id'] as int,
      scheduleId: json['schedule_id'] as int?,
      logDate: DateTime.parse(json['log_date']),
      logTime: parseTime(json['log_time']),
      status: json['status'] as String? ?? 'taken',
      actualTime: json['actual_time'] != null ? parseTime(json['actual_time']) : null,
      notes: json['notes'] as String?,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] is int 
          ? (json['dosage'] as int).toDouble() 
          : double.parse(json['dosage'].toString()),
      unit: json['unit'] as String,
      color: json['color'] as String? ?? '#3B82F6',
      scheduledTime: json['scheduled_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medication_id': medicationId,
      'schedule_id': scheduleId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'log_time': '${logTime.hour.toString().padLeft(2, '0')}:${logTime.minute.toString().padLeft(2, '0')}:00',
      'status': status,
      if (actualTime != null) 
        'actual_time': '${actualTime!.hour.toString().padLeft(2, '0')}:${actualTime!.minute.toString().padLeft(2, '0')}:00',
      if (notes != null) 'notes': notes,
    };
  }

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

class DailyMedicationSummary {
  final DateTime date;
  final int totalMedications;
  final int totalDosesExpected;
  final int totalDosesTaken;
  final int overallAdherence;
  final List<MedicationDaySummary> medications;

  DailyMedicationSummary({
    required this.date,
    required this.totalMedications,
    required this.totalDosesExpected,
    required this.totalDosesTaken,
    required this.overallAdherence,
    required this.medications,
  });

  factory DailyMedicationSummary.fromJson(Map<String, dynamic> json) {
    List<MedicationDaySummary> medications = [];
    if (json['medications'] != null && json['medications'] is List) {
      medications = (json['medications'] as List)
          .map((m) => MedicationDaySummary.fromJson(m))
          .toList();
    }

    return DailyMedicationSummary(
      date: DateTime.parse(json['date']),
      totalMedications: json['total_medications'] as int? ?? 0,
      totalDosesExpected: json['total_doses_expected'] as int? ?? 0,
      totalDosesTaken: json['total_doses_taken'] as int? ?? 0,
      overallAdherence: json['overall_adherence'] as int? ?? 100,
      medications: medications,
    );
  }
}

class MedicationDaySummary {
  final int id;
  final String name;
  final double dosage;
  final String unit;
  final String color;
  final List<ExpectedDose> expectedDoses;
  final List<TakenDose> takenDoses;
  final double adherenceRate;
  final bool isComplete;

  MedicationDaySummary({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.color,
    required this.expectedDoses,
    required this.takenDoses,
    required this.adherenceRate,
    required this.isComplete,
  });

  factory MedicationDaySummary.fromJson(Map<String, dynamic> json) {
    List<ExpectedDose> expectedDoses = [];
    if (json['expected_doses'] != null && json['expected_doses'] is List) {
      expectedDoses = (json['expected_doses'] as List)
          .map((d) => ExpectedDose.fromJson(d))
          .toList();
    }

    List<TakenDose> takenDoses = [];
    if (json['taken_doses'] != null && json['taken_doses'] is List) {
      takenDoses = (json['taken_doses'] as List)
          .map((d) => TakenDose.fromJson(d))
          .toList();
    }

    return MedicationDaySummary(
      id: json['id'] as int,
      name: json['name'] as String,
      dosage: json['dosage'] is int 
          ? (json['dosage'] as int).toDouble() 
          : double.parse(json['dosage'].toString()),
      unit: json['unit'] as String,
      color: json['color'] as String? ?? '#3B82F6',
      expectedDoses: expectedDoses,
      takenDoses: takenDoses,
      adherenceRate: json['adherence_rate'] as double? ?? 0.0,
      isComplete: json['is_complete'] as bool? ?? false,
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

class ExpectedDose {
  final int? scheduleId;
  final String scheduledTime;
  final double dosage;
  final String unit;

  ExpectedDose({
    this.scheduleId,
    required this.scheduledTime,
    required this.dosage,
    required this.unit,
  });

  factory ExpectedDose.fromJson(Map<String, dynamic> json) {
    return ExpectedDose(
      scheduleId: json['schedule_id'] as int?,
      scheduledTime: json['scheduled_time'] as String,
      dosage: json['dosage'] is int 
          ? (json['dosage'] as int).toDouble() 
          : double.parse(json['dosage'].toString()),
      unit: json['unit'] as String,
    );
  }

  String get formattedTime {
    final parts = scheduledTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class TakenDose {
  final int? scheduleId;
  final String takenTime;
  final String status;
  final String? actualTime;
  final String? notes;

  TakenDose({
    this.scheduleId,
    required this.takenTime,
    required this.status,
    this.actualTime,
    this.notes,
  });

  factory TakenDose.fromJson(Map<String, dynamic> json) {
    return TakenDose(
      scheduleId: json['schedule_id'] as int?,
      takenTime: json['taken_time'] as String,
      status: json['status'] as String,
      actualTime: json['actual_time'] as String?,
      notes: json['notes'] as String?,
    );
  }

  String get formattedTakenTime {
    final parts = takenTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class MedicationAdherenceRate {
  final int medicationId;
  final String medicationName;
  final DateTime startDate;
  final DateTime endDate;
  final int expectedDoses;
  final int takenDoses;
  final int missedDoses;
  final int adherenceRate;
  final List<MedicationSchedule> schedules;

  MedicationAdherenceRate({
    required this.medicationId,
    required this.medicationName,
    required this.startDate,
    required this.endDate,
    required this.expectedDoses,
    required this.takenDoses,
    required this.missedDoses,
    required this.adherenceRate,
    required this.schedules,
  });

  factory MedicationAdherenceRate.fromJson(Map<String, dynamic> json) {
    List<MedicationSchedule> schedules = [];
    if (json['schedules'] != null && json['schedules'] is List) {
      schedules = (json['schedules'] as List)
          .map((s) => MedicationSchedule.fromJson(s))
          .toList();
    }

    return MedicationAdherenceRate(
      medicationId: json['medication_id'] as int,
      medicationName: json['medication_name'] as String,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      expectedDoses: json['expected_doses'] as int,
      takenDoses: json['taken_doses'] as int,
      missedDoses: json['missed_doses'] as int,
      adherenceRate: json['adherence_rate'] as int,
      schedules: schedules,
    );
  }
}

class MedicationStats {
  final int medicationId;
  final String period;
  final List<MedicationDailyStat> data;
  final MedicationStatsSummary summary;

  MedicationStats({
    required this.medicationId,
    required this.period,
    required this.data,
    required this.summary,
  });

  factory MedicationStats.fromJson(Map<String, dynamic> json) {
    List<MedicationDailyStat> data = [];
    if (json['data'] != null && json['data'] is List) {
      data = (json['data'] as List)
          .map((d) => MedicationDailyStat.fromJson(d))
          .toList();
    }

    return MedicationStats(
      medicationId: json['medication_id'] as int,
      period: json['period'] as String,
      data: data,
      summary: MedicationStatsSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}

class MedicationDailyStat {
  final DateTime date;
  final int totalDoses;
  final int taken;
  final int late;
  final int missed;
  final int skipped;
  final int adherenceRate;

  MedicationDailyStat({
    required this.date,
    required this.totalDoses,
    required this.taken,
    required this.late,
    required this.missed,
    required this.skipped,
    required this.adherenceRate,
  });

  factory MedicationDailyStat.fromJson(Map<String, dynamic> json) {
    return MedicationDailyStat(
      date: DateTime.parse(json['date']),
      totalDoses: json['total_doses'] as int,
      taken: json['taken'] as int,
      late: json['late'] as int,
      missed: json['missed'] as int,
      skipped: json['skipped'] as int,
      adherenceRate: json['adherence_rate'] as int,
    );
  }
}

class MedicationStatsSummary {
  final int totalDoses;
  final int totalTaken;
  final int totalLate;
  final int totalMissed;
  final int totalSkipped;
  final int averageAdherence;

  MedicationStatsSummary({
    required this.totalDoses,
    required this.totalTaken,
    required this.totalLate,
    required this.totalMissed,
    required this.totalSkipped,
    required this.averageAdherence,
  });

  factory MedicationStatsSummary.fromJson(Map<String, dynamic> json) {
    return MedicationStatsSummary(
      totalDoses: json['total_doses'] as int? ?? 0,
      totalTaken: json['total_taken'] as int? ?? 0,
      totalLate: json['total_late'] as int? ?? 0,
      totalMissed: json['total_missed'] as int? ?? 0,
      totalSkipped: json['total_skipped'] as int? ?? 0,
      averageAdherence: json['average_adherence'] as int? ?? 100,
    );
  }
}

class UpcomingDose {
  final int medicationId;
  final String name;
  final double dosage;
  final String unit;
  final String color;
  final int scheduleId;
  final String scheduledTime;
  final double actualDosage;
  final String actualUnit;

  UpcomingDose({
    required this.medicationId,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.color,
    required this.scheduleId,
    required this.scheduledTime,
    required this.actualDosage,
    required this.actualUnit,
  });

  factory UpcomingDose.fromJson(Map<String, dynamic> json) {
    return UpcomingDose(
      medicationId: json['medication_id'] as int,
      name: json['name'] as String,
      dosage: json['dosage'] is int 
          ? (json['dosage'] as int).toDouble() 
          : double.parse(json['dosage'].toString()),
      unit: json['unit'] as String,
      color: json['color'] as String? ?? '#3B82F6',
      scheduleId: json['schedule_id'] as int,
      scheduledTime: json['scheduled_time'] as String,
      actualDosage: json['actual_dosage'] is int 
          ? (json['actual_dosage'] as int).toDouble() 
          : double.parse(json['actual_dosage'].toString()),
      actualUnit: json['actual_unit'] as String,
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

  String get formattedScheduledTime {
    final parts = scheduledTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}