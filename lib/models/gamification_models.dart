import 'package:flutter/material.dart';

enum BadgeRarity { common, rare, epic, legendary }
enum BadgeCategory { activity, nutrition, sleep, hydration, consistency, social }

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final BadgeRarity rarity;
  final BadgeCategory category;
  final int pointsValue;
  final DateTime? earnedDate;
  final bool isEarned;
  final Map<String, dynamic> requirements;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.rarity,
    required this.category,
    required this.pointsValue,
    this.earnedDate,
    this.isEarned = false,
    this.requirements = const {},
  });

  Color get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.amber;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case BadgeCategory.activity:
        return Icons.directions_run;
      case BadgeCategory.nutrition:
        return Icons.restaurant;
      case BadgeCategory.sleep:
        return Icons.bedtime;
      case BadgeCategory.hydration:
        return Icons.local_drink;
      case BadgeCategory.consistency:
        return Icons.calendar_today;
      case BadgeCategory.social:
        return Icons.people;
    }
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['iconPath'],
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.toString() == 'BadgeRarity.${json['rarity']}',
        orElse: () => BadgeRarity.common,
      ),
      category: BadgeCategory.values.firstWhere(
        (e) => e.toString() == 'BadgeCategory.${json['category']}',
        orElse: () => BadgeCategory.activity,
      ),
      pointsValue: json['pointsValue'],
      earnedDate: json['earnedDate'] != null 
          ? DateTime.parse(json['earnedDate']) 
          : null,
      isEarned: json['isEarned'] ?? false,
      requirements: json['requirements'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'rarity': rarity.toString().split('.').last,
      'category': category.toString().split('.').last,
      'pointsValue': pointsValue,
      'earnedDate': earnedDate?.toIso8601String(),
      'isEarned': isEarned,
      'requirements': requirements,
    };
  }
}

class UserStats {
  final int currentStreak;
  final int longestStreak;
  final int totalPoints;
  final int level;
  final int pointsToNextLevel;
  final double levelProgress;
  final Map<String, int> categoryPoints;
  final int badgesEarned;
  final int totalBadges;

  UserStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalPoints,
    required this.level,
    required this.pointsToNextLevel,
    required this.levelProgress,
    required this.categoryPoints,
    required this.badgesEarned,
    required this.totalBadges,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      level: json['level'] ?? 1,
      pointsToNextLevel: json['pointsToNextLevel'] ?? 100,
      levelProgress: json['levelProgress']?.toDouble() ?? 0.0,
      categoryPoints: Map<String, int>.from(json['categoryPoints'] ?? {}),
      badgesEarned: json['badgesEarned'] ?? 0,
      totalBadges: json['totalBadges'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalPoints': totalPoints,
      'level': level,
      'pointsToNextLevel': pointsToNextLevel,
      'levelProgress': levelProgress,
      'categoryPoints': categoryPoints,
      'badgesEarned': badgesEarned,
      'totalBadges': totalBadges,
    };
  }
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? profilePic;
  final int points;
  final int streak;
  final int rank;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.profilePic,
    required this.points,
    required this.streak,
    required this.rank,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'],
      userName: json['userName'],
      profilePic: json['profilePic'],
      points: json['points'],
      streak: json['streak'],
      rank: json['rank'],
      isCurrentUser: json['isCurrentUser'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'profilePic': profilePic,
      'points': points,
      'streak': streak,
      'rank': rank,
      'isCurrentUser': isCurrentUser,
    };
  }
}

enum GoalType {
  steps, calories, workoutMinutes, waterGlasses, sleepHours, meditation
}

enum GoalPeriod { daily, weekly, monthly }

enum GoalStatus { active, completed, expired }

class Goal {
  final String id;
  final String title;
  final String description;
  final GoalType type;
  final GoalPeriod period;
  final double target;
  double current;
  final DateTime startDate;
  final DateTime? endDate;
  GoalStatus status;
  final int pointsReward;
  final String? badgeRewardId;
  DateTime? completedAt;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.period,
    required this.target,
    this.current = 0,
    required this.startDate,
    this.endDate,
    this.status = GoalStatus.active,
    required this.pointsReward,
    this.badgeRewardId,
    this.completedAt,
  });

  double get progress {
    if (target == 0) return 0;
    return (current / target).clamp(0, 1);
  }

  String get formattedProgress {
    if (type == GoalType.waterGlasses) {
      return '${current.toInt()}/${target.toInt()} glasses';
    } else if (type == GoalType.sleepHours) {
      return '${current.toStringAsFixed(1)}/${target.toStringAsFixed(1)} hours';
    } else {
      return '${current.toInt()}/${target.toInt()}';
    }
  }

  IconData get icon {
    switch (type) {
      case GoalType.steps:
        return Icons.directions_walk;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.workoutMinutes:
        return Icons.fitness_center;
      case GoalType.waterGlasses:
        return Icons.local_drink;
      case GoalType.sleepHours:
        return Icons.bedtime;
      case GoalType.meditation:
        return Icons.self_improvement;
    }
  }

  Color get color {
    switch (type) {
      case GoalType.steps:
        return Colors.blue;
      case GoalType.calories:
        return Colors.orange;
      case GoalType.workoutMinutes:
        return Colors.green;
      case GoalType.waterGlasses:
        return Colors.cyan;
      case GoalType.sleepHours:
        return Colors.purple;
      case GoalType.meditation:
        return Colors.indigo;
    }
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: GoalType.values.firstWhere(
        (e) => e.toString() == 'GoalType.${json['type']}',
        orElse: () => GoalType.steps,
      ),
      period: GoalPeriod.values.firstWhere(
        (e) => e.toString() == 'GoalPeriod.${json['period']}',
        orElse: () => GoalPeriod.daily,
      ),
      target: json['target']?.toDouble() ?? 0,
      current: json['current']?.toDouble() ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: GoalStatus.values.firstWhere(
        (e) => e.toString() == 'GoalStatus.${json['status']}',
        orElse: () => GoalStatus.active,
      ),
      pointsReward: json['pointsReward'] ?? 0,
      badgeRewardId: json['badgeRewardId'],
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'period': period.toString().split('.').last,
      'target': target,
      'current': current,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'pointsReward': pointsReward,
      'badgeRewardId': badgeRewardId,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

class Reminder {
  final String id;
  final String title;
  final String description;
  final TimeOfDay time;
  final List<int> repeatDays; // 0-6, Sunday to Saturday
  final bool isEnabled;
  final String? action;
  final Map<String, dynamic>? actionData;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.repeatDays,
    this.isEnabled = true,
    this.action,
    this.actionData,
  });

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<String> get formattedDays {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return repeatDays.map((d) => days[d]).toList();
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      time: TimeOfDay(
        hour: json['hour'] ?? 0,
        minute: json['minute'] ?? 0,
      ),
      repeatDays: List<int>.from(json['repeatDays'] ?? []),
      isEnabled: json['isEnabled'] ?? true,
      action: json['action'],
      actionData: json['actionData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hour': time.hour,
      'minute': time.minute,
      'repeatDays': repeatDays,
      'isEnabled': isEnabled,
      'action': action,
      'actionData': actionData,
    };
  }
}