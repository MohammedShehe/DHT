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

// Goal Types
enum GoalType {
  steps, water, sleep, meditation, workouts, calories
}

enum GoalPeriod { daily, weekly, monthly }

enum GoalStatus { active, completed, expired }

// Goal Categories for browsing
enum GoalMainCategory {
  fitness, nutrition, mindfulness, wellness, all
}

extension GoalMainCategoryExtension on GoalMainCategory {
  String get displayName {
    switch (this) {
      case GoalMainCategory.fitness:
        return 'Fitness';
      case GoalMainCategory.nutrition:
        return 'Nutrition';
      case GoalMainCategory.mindfulness:
        return 'Mindfulness';
      case GoalMainCategory.wellness:
        return 'Wellness';
      case GoalMainCategory.all:
        return 'All Goals';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalMainCategory.fitness:
        return Icons.fitness_center;
      case GoalMainCategory.nutrition:
        return Icons.restaurant;
      case GoalMainCategory.mindfulness:
        return Icons.self_improvement;
      case GoalMainCategory.wellness:
        return Icons.spa;
      case GoalMainCategory.all:
        return Icons.apps;
    }
  }

  Color get color {
    switch (this) {
      case GoalMainCategory.fitness:
        return Colors.blue;
      case GoalMainCategory.nutrition:
        return Colors.orange;
      case GoalMainCategory.mindfulness:
        return Colors.purple;
      case GoalMainCategory.wellness:
        return Colors.teal;
      case GoalMainCategory.all:
        return Colors.grey;
    }
  }
}

// Goal Template for browsing
class GoalTemplate {
  final String id;
  final String name;
  final String description;
  final GoalType type;
  final GoalPeriod period;
  final double defaultTarget;
  final GoalMainCategory category;
  final List<String> tags;
  final IconData icon;
  final Color color;
  final int popularity;
  final bool isRecommended;

  GoalTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.period,
    required this.defaultTarget,
    required this.category,
    required this.tags,
    required this.icon,
    required this.color,
    this.popularity = 50,
    this.isRecommended = false,
  });

  factory GoalTemplate.fromType(GoalType type) {
    switch (type) {
      case GoalType.steps:
        return GoalTemplate(
          id: 'template_steps',
          name: 'Daily Steps',
          description: 'Walk a certain number of steps each day to stay active',
          type: GoalType.steps,
          period: GoalPeriod.daily,
          defaultTarget: 10000,
          category: GoalMainCategory.fitness,
          tags: ['walking', 'cardio', 'fitness'],
          icon: Icons.directions_walk,
          color: Colors.blue,
          popularity: 95,
          isRecommended: true,
        );
      case GoalType.water:
        return GoalTemplate(
          id: 'template_water',
          name: 'Water Intake',
          description: 'Stay hydrated by drinking enough water daily',
          type: GoalType.water,
          period: GoalPeriod.daily,
          defaultTarget: 8,
          category: GoalMainCategory.wellness,
          tags: ['hydration', 'health', 'wellness'],
          icon: Icons.local_drink,
          color: Colors.cyan,
          popularity: 90,
          isRecommended: true,
        );
      case GoalType.sleep:
        return GoalTemplate(
          id: 'template_sleep',
          name: 'Sleep Hours',
          description: 'Get quality sleep for better health and recovery',
          type: GoalType.sleep,
          period: GoalPeriod.daily,
          defaultTarget: 8,
          category: GoalMainCategory.wellness,
          tags: ['rest', 'recovery', 'health'],
          icon: Icons.bedtime,
          color: Colors.purple,
          popularity: 88,
          isRecommended: true,
        );
      case GoalType.meditation:
        return GoalTemplate(
          id: 'template_meditation',
          name: 'Meditation',
          description: 'Practice mindfulness and reduce stress',
          type: GoalType.meditation,
          period: GoalPeriod.daily,
          defaultTarget: 10,
          category: GoalMainCategory.mindfulness,
          tags: ['mindfulness', 'stress', 'mental'],
          icon: Icons.self_improvement,
          color: Colors.indigo,
          popularity: 85,
          isRecommended: true,
        );
      case GoalType.workouts:
        return GoalTemplate(
          id: 'template_workouts',
          name: 'Weekly Workouts',
          description: 'Complete workouts each week to build strength',
          type: GoalType.workouts,
          period: GoalPeriod.weekly,
          defaultTarget: 5,
          category: GoalMainCategory.fitness,
          tags: ['exercise', 'strength', 'fitness'],
          icon: Icons.fitness_center,
          color: Colors.green,
          popularity: 92,
          isRecommended: true,
        );
      case GoalType.calories:
        return GoalTemplate(
          id: 'template_calories',
          name: 'Monthly Calories',
          description: 'Track calorie intake for weight management',
          type: GoalType.calories,
          period: GoalPeriod.monthly,
          defaultTarget: 50000,
          category: GoalMainCategory.nutrition,
          tags: ['nutrition', 'weight', 'diet'],
          icon: Icons.local_fire_department,
          color: Colors.orange,
          popularity: 80,
          isRecommended: true,
        );
    }
  }

  static List<GoalTemplate> getAllTemplates() {
    return GoalType.values.map((type) => GoalTemplate.fromType(type)).toList();
  }

  static List<GoalTemplate> getTemplatesByCategory(GoalMainCategory category) {
    if (category == GoalMainCategory.all) {
      return getAllTemplates();
    }
    return getAllTemplates().where((t) => t.category == category).toList();
  }

  static List<GoalTemplate> getRecommendedTemplates() {
    return getAllTemplates().where((t) => t.isRecommended).toList();
  }

  static List<GoalTemplate> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllTemplates().where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
             t.description.toLowerCase().contains(lowerQuery) ||
             t.tags.any((tag) => tag.contains(lowerQuery));
    }).toList();
  }
}

class Goal {
  final String id;
  final GoalType type;
  final double targetValue;
  final GoalPeriod period;
  double currentValue;
  final DateTime createdAt;
  DateTime? completedAt;
  GoalStatus status;
  List<String> tags;
  String? category;

  Goal({
    required this.id,
    required this.type,
    required this.targetValue,
    required this.period,
    this.currentValue = 0,
    required this.createdAt,
    this.completedAt,
    this.status = GoalStatus.active,
    this.tags = const [],
    this.category,
  });

  double get progress {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0, 1);
  }

  bool get isCompleted => currentValue >= targetValue;

  String get formattedProgress {
    switch (type) {
      case GoalType.water:
        return '${currentValue.toInt()}/${targetValue.toInt()} glasses';
      case GoalType.sleep:
        return '${currentValue.toStringAsFixed(1)}/${targetValue.toStringAsFixed(1)} hours';
      case GoalType.meditation:
        return '${currentValue.toInt()}/${targetValue.toInt()} min';
      case GoalType.workouts:
        return '${currentValue.toInt()}/${targetValue.toInt()} workouts';
      case GoalType.steps:
        return '${currentValue.toInt()}/${targetValue.toInt()} steps';
      case GoalType.calories:
        return '${currentValue.toInt()}/${targetValue.toInt()} kcal';
    }
  }

  IconData get icon {
    switch (type) {
      case GoalType.steps:
        return Icons.directions_walk;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.workouts:
        return Icons.fitness_center;
      case GoalType.water:
        return Icons.local_drink;
      case GoalType.sleep:
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
      case GoalType.workouts:
        return Colors.green;
      case GoalType.water:
        return Colors.cyan;
      case GoalType.sleep:
        return Colors.purple;
      case GoalType.meditation:
        return Colors.indigo;
    }
  }

  GoalTemplate get template => GoalTemplate.fromType(type);

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'].toString(),
      type: _parseGoalType(json['type']),
      targetValue: (json['targetValue'] ?? json['target'] ?? 0).toDouble(),
      period: _parseGoalPeriod(json['period']),
      currentValue: (json['currentValue'] ?? json['current'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      status: _parseGoalStatus(json['status']),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      category: json['category'],
    );
  }

  static GoalType _parseGoalType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'steps': return GoalType.steps;
        case 'water': return GoalType.water;
        case 'sleep': return GoalType.sleep;
        case 'meditation': return GoalType.meditation;
        case 'workouts': return GoalType.workouts;
        case 'calories': return GoalType.calories;
      }
    }
    return GoalType.steps;
  }

  static GoalPeriod _parseGoalPeriod(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'daily': return GoalPeriod.daily;
        case 'weekly': return GoalPeriod.weekly;
        case 'monthly': return GoalPeriod.monthly;
      }
    }
    return GoalPeriod.daily;
  }

  static GoalStatus _parseGoalStatus(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'completed': return GoalStatus.completed;
        case 'expired': return GoalStatus.expired;
        default: return GoalStatus.active;
      }
    }
    return GoalStatus.active;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last.toLowerCase(),
      'targetValue': targetValue,
      'period': period.toString().split('.').last.toLowerCase(),
      'tags': tags,
      'category': category,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'type': type.toString().split('.').last.toLowerCase(),
      'targetValue': targetValue,
      'period': period.toString().split('.').last.toLowerCase(),
      'currentValue': currentValue,
      'tags': tags,
      'category': category,
    };
  }
}

class Reminder {
  final String id;
  final String title;
  final String description;
  final TimeOfDay time;
  final List<int> repeatDays;
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