enum FitnessDataType {
  steps,
  calories,
  distance,
  heartRate,
  weight,
  height,
  sleep,
  activity,
}

enum FitnessDataSource {
  googleFit,
  manual,
  wearable,
}

class FitnessDataPoint {
  final DateTime startTime;
  final DateTime endTime;
  final double value;
  final String unit;
  final FitnessDataType type;
  final FitnessDataSource source;
  final Map<String, dynamic>? metadata;

  FitnessDataPoint({
    required this.startTime,
    required this.endTime,
    required this.value,
    required this.unit,
    required this.type,
    required this.source,
    this.metadata,
  });

  factory FitnessDataPoint.fromJson(Map<String, dynamic> json) {
    return FitnessDataPoint(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      value: json['value'].toDouble(),
      unit: json['unit'],
      type: FitnessDataType.values.firstWhere(
        (e) => e.toString() == 'FitnessDataType.${json['type']}',
        orElse: () => FitnessDataType.steps,
      ),
      source: FitnessDataSource.values.firstWhere(
        (e) => e.toString() == 'FitnessDataSource.${json['source']}',
        orElse: () => FitnessDataSource.manual,
      ),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'value': value,
      'unit': unit,
      'type': type.toString().split('.').last,
      'source': source.toString().split('.').last,
      'metadata': metadata,
    };
  }
}

class FitnessActivity {
  final String id;
  final String name;
  final int activityType;
  final DateTime startTime;
  final DateTime endTime;
  final double duration;
  final int calories;
  final int steps;
  final double distance;
  final List<FitnessDataPoint>? heartRatePoints;

  FitnessActivity({
    required this.id,
    required this.name,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.calories,
    required this.steps,
    required this.distance,
    this.heartRatePoints,
  });

  factory FitnessActivity.fromJson(Map<String, dynamic> json) {
    return FitnessActivity(
      id: json['id'],
      name: json['name'],
      activityType: json['activityType'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: json['duration'].toDouble(),
      calories: json['calories'],
      steps: json['steps'],
      distance: json['distance'].toDouble(),
      heartRatePoints: json['heartRatePoints'] != null
          ? (json['heartRatePoints'] as List)
              .map((p) => FitnessDataPoint.fromJson(p))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'activityType': activityType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'calories': calories,
      'steps': steps,
      'distance': distance,
      'heartRatePoints': heartRatePoints?.map((p) => p.toJson()).toList(),
    };
  }
}

class FitnessSession {
  final String id;
  final String name;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? appPackageName;
  final List<FitnessActivity>? activities;

  FitnessSession({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.appPackageName,
    this.activities,
  });

  factory FitnessSession.fromJson(Map<String, dynamic> json) {
    return FitnessSession(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      appPackageName: json['appPackageName'],
      activities: json['activities'] != null
          ? (json['activities'] as List)
              .map((a) => FitnessActivity.fromJson(a))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'appPackageName': appPackageName,
      'activities': activities?.map((a) => a.toJson()).toList(),
    };
  }
}

class DailyFitnessSummary {
  final DateTime date;
  final int totalSteps;
  final int totalCalories;
  final double totalDistance;
  final double totalActiveMinutes;
  final double averageHeartRate;
  final int totalActivities;
  final Map<int, int>? activityBreakdown;

  DailyFitnessSummary({
    required this.date,
    required this.totalSteps,
    required this.totalCalories,
    required this.totalDistance,
    required this.totalActiveMinutes,
    required this.averageHeartRate,
    required this.totalActivities,
    this.activityBreakdown,
  });

  factory DailyFitnessSummary.fromJson(Map<String, dynamic> json) {
    return DailyFitnessSummary(
      date: DateTime.parse(json['date']),
      totalSteps: json['totalSteps'],
      totalCalories: json['totalCalories'],
      totalDistance: json['totalDistance'].toDouble(),
      totalActiveMinutes: json['totalActiveMinutes'].toDouble(),
      averageHeartRate: json['averageHeartRate'].toDouble(),
      totalActivities: json['totalActivities'],
      activityBreakdown: json['activityBreakdown'] != null
          ? Map<int, int>.from(json['activityBreakdown'])
          : null,
    );
  }
}

class SleepSegment {
  final DateTime startTime;
  final DateTime endTime;
  final int sleepType;

  SleepSegment({
    required this.startTime,
    required this.endTime,
    required this.sleepType,
  });

  factory SleepSegment.fromJson(Map<String, dynamic> json) {
    return SleepSegment(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      sleepType: json['sleepType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'sleepType': sleepType,
    };
  }
}

class SleepSession {
  final DateTime startTime;
  final DateTime endTime;
  final double duration;
  final int sleepType;
  final double? deepSleepDuration;
  final double? lightSleepDuration;
  final double? remSleepDuration;
  final int? awakeDuration;
  final List<SleepSegment>? segments;

  SleepSession({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.sleepType,
    this.deepSleepDuration,
    this.lightSleepDuration,
    this.remSleepDuration,
    this.awakeDuration,
    this.segments,
  });

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: json['duration'].toDouble(),
      sleepType: json['sleepType'],
      deepSleepDuration: json['deepSleepDuration']?.toDouble(),
      lightSleepDuration: json['lightSleepDuration']?.toDouble(),
      remSleepDuration: json['remSleepDuration']?.toDouble(),
      awakeDuration: json['awakeDuration'],
      segments: json['segments'] != null
          ? (json['segments'] as List)
              .map((s) => SleepSegment.fromJson(s))
              .toList()
          : null,
    );
  }
}