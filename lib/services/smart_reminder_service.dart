import 'dart:math';
import 'package:flutter/material.dart';
import '../models/smart_reminder_model.dart';
import '../models/health_profile_model.dart';
import '../models/gamification_models.dart';
import '../services/goal_service.dart';
import '../services/health_service.dart';
import '../services/auth_service.dart';

class SmartReminderService {
  static final SmartReminderService _instance = SmartReminderService._internal();
  factory SmartReminderService() => _instance;
  SmartReminderService._internal();

  List<SmartReminder> _generatedReminders = [];
  DateTime _lastGenerationTime = DateTime.now().subtract(const Duration(hours: 1));

  // Helper method to safely convert any value to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper method to safely convert any value to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Template definitions for different reminder types
  final List<SmartReminderTemplate> _templates = [
    // Hydration reminders
    SmartReminderTemplate(
      id: 'hydration_morning',
      title: 'Start Your Day Hydrated',
      messageTemplate: 'Good morning! Drinking water first thing boosts metabolism by {boost}%. Start with a glass now.',
      category: ReminderCategory.hydration,
      priority: ReminderPriority.high,
      triggers: ['time_morning', 'low_hydration_yesterday'],
      actionData: {'screen': 'activity', 'tab': 3},
      actionType: 'log_water',
      pointsReward: 5,
    ),
    SmartReminderTemplate(
      id: 'hydration_progress',
      title: 'Hydration Check',
      messageTemplate: "You've had {glasses} glasses today. {message}",
      category: ReminderCategory.hydration,
      priority: ReminderPriority.medium,
      triggers: ['midday_check'],
      actionData: {'screen': 'activity', 'tab': 3},
      actionType: 'log_water',
    ),
    SmartReminderTemplate(
      id: 'hydration_evening',
      title: 'Evening Hydration',
      messageTemplate: 'Evening reminder: {hoursUntilBed} hours until bedtime. Time for your last glass of water.',
      category: ReminderCategory.hydration,
      priority: ReminderPriority.medium,
      triggers: ['time_evening'],
      actionData: {'screen': 'activity', 'tab': 3},
      actionType: 'log_water',
    ),

    // Activity reminders
    SmartReminderTemplate(
      id: 'activity_sedentary',
      title: 'Time to Move',
      messageTemplate: "You've been sitting for {hours} hours. A {minutes} minute walk can boost your energy and focus.",
      category: ReminderCategory.activity,
      priority: ReminderPriority.medium,
      triggers: ['prolonged_inactivity'],
      actionData: {'screen': 'activity', 'tab': 1},
      actionType: 'open_activity',
    ),
    SmartReminderTemplate(
      id: 'activity_steps_progress',
      title: 'Steps Progress',
      messageTemplate: "You're at {steps} steps ({percentage}% of daily goal). {message}",
      category: ReminderCategory.activity,
      priority: ReminderPriority.medium,
      triggers: ['steps_check'],
      actionData: {'screen': 'activity', 'tab': 1},
      actionType: 'open_activity',
    ),
    SmartReminderTemplate(
      id: 'activity_goal_close',
      title: 'Almost There!',
      messageTemplate: 'Only {remaining} steps to reach your daily goal! A short walk can get you there.',
      category: ReminderCategory.activity,
      priority: ReminderPriority.high,
      triggers: ['steps_near_goal'],
      actionData: {'screen': 'activity', 'tab': 1},
      actionType: 'open_activity',
      pointsReward: 10,
    ),

    // Sleep reminders
    SmartReminderTemplate(
      id: 'sleep_bedtime',
      title: 'Bedtime Reminder',
      messageTemplate: 'Based on your wake time of {wakeTime}, you should aim to sleep in {hoursUntilBed} hours for optimal rest.',
      category: ReminderCategory.sleep,
      priority: ReminderPriority.high,
      triggers: ['time_bedtime'],
      actionData: {'screen': 'activity', 'tab': 2},
      actionType: 'log_sleep',
    ),
    SmartReminderTemplate(
      id: 'sleep_consistency',
      title: 'Sleep Consistency',
      messageTemplate: 'You\'ve been consistent with your sleep schedule! Your average bedtime is {avgBedtime}. Keep it up!',
      category: ReminderCategory.sleep,
      priority: ReminderPriority.medium,
      triggers: ['sleep_consistent'],
      actionData: {'screen': 'activity', 'tab': 2},
      pointsReward: 15,
    ),
    SmartReminderTemplate(
      id: 'sleep_quality_tip',
      title: 'Sleep Quality Tip',
      messageTemplate: 'Try {tip} to improve your sleep quality tonight.',
      category: ReminderCategory.sleep,
      priority: ReminderPriority.medium,
      triggers: ['sleep_quality_check'],
      actionData: {'screen': 'activity', 'tab': 2},
    ),

    // Nutrition reminders
    SmartReminderTemplate(
      id: 'nutrition_meal_skip',
      title: 'Missed Meal',
      messageTemplate: "We noticed you haven't logged {mealType} yet. Regular meals help maintain energy and metabolism.",
      category: ReminderCategory.nutrition,
      priority: ReminderPriority.medium,
      triggers: ['missed_meal'],
      actionData: {'screen': 'activity', 'tab': 0},
      actionType: 'log_meal',
    ),
    SmartReminderTemplate(
      id: 'nutrition_calorie_status',
      title: 'Calorie Check',
      messageTemplate: "You've consumed {calories} calories today. Based on your BMR of {bmr}, you're {status}.",
      category: ReminderCategory.nutrition,
      priority: ReminderPriority.medium,
      triggers: ['calorie_check'],
      actionData: {'screen': 'activity', 'tab': 0},
      actionType: 'log_meal',
    ),
    SmartReminderTemplate(
      id: 'nutrition_protein',
      title: 'Protein Intake',
      messageTemplate: 'Your protein intake is at {protein}g ({percentage}% of recommended). {message}',
      category: ReminderCategory.nutrition,
      priority: ReminderPriority.medium,
      triggers: ['protein_check'],
      actionData: {'screen': 'activity', 'tab': 0},
      actionType: 'log_meal',
    ),

    // Mindfulness reminders
    SmartReminderTemplate(
      id: 'mindfulness_stress',
      title: 'Stress Relief',
      messageTemplate: 'Take {minutes} minutes for mindfulness. Deep breathing can reduce stress by {percentage}%.',
      category: ReminderCategory.mindfulness,
      priority: ReminderPriority.medium,
      triggers: ['stress_indicator'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'meditate',
    ),
    SmartReminderTemplate(
      id: 'mindfulness_midday',
      title: 'Midday Reset',
      messageTemplate: 'A quick {minutes}-minute meditation can recharge your focus for the afternoon.',
      category: ReminderCategory.mindfulness,
      priority: ReminderPriority.low,
      triggers: ['time_afternoon'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'meditate',
    ),

    // Goal reminders
    SmartReminderTemplate(
      id: 'goal_weekly_review',
      title: 'Weekly Goal Review',
      messageTemplate: 'This week, you\'ve completed {completed}/{total} goals. {message}',
      category: ReminderCategory.goal,
      priority: ReminderPriority.high,
      triggers: ['weekly_review'],
      actionData: {'screen': 'gamification', 'tab': 1},
      actionType: 'open_goals',
    ),
    SmartReminderTemplate(
      id: 'goal_new_suggestion',
      title: 'New Goal Suggestion',
      messageTemplate: 'Based on your activity, try setting a {goalType} goal of {target} {unit}.',
      category: ReminderCategory.goal,
      priority: ReminderPriority.medium,
      triggers: ['goal_suggestion'],
      actionData: {'screen': 'gamification', 'tab': 1},
      actionType: 'create_goal',
    ),

    // Streak reminders
    SmartReminderTemplate(
      id: 'streak_milestone',
      title: 'Streak Milestone!',
      messageTemplate: 'Congratulations! You\'ve reached a {days}-day streak! Keep up the amazing work!',
      category: ReminderCategory.streak,
      priority: ReminderPriority.high,
      triggers: ['streak_milestone'],
      actionData: {'screen': 'gamification', 'tab': 0},
      pointsReward: 50,
    ),
    SmartReminderTemplate(
      id: 'streak_warning',
      title: 'Don\'t Break Your Streak!',
      messageTemplate: 'You\'re {hours} hours away from breaking your {days}-day streak. Log an activity to keep it alive!',
      category: ReminderCategory.streak,
      priority: ReminderPriority.critical,
      triggers: ['streak_warning'],
      actionData: {'screen': 'activity'},
      pointsReward: 5,
    ),

    // Achievement reminders
    SmartReminderTemplate(
      id: 'achievement_unlock',
      title: 'Achievement Unlocked!',
      messageTemplate: 'You\'ve earned the "{badgeName}" badge! +{points} points',
      category: ReminderCategory.achievement,
      priority: ReminderPriority.high,
      triggers: ['badge_earned'],
      actionData: {'screen': 'gamification', 'tab': 0},
      pointsReward: 0, // Points already included in badge
    ),

    // Medication reminders
    SmartReminderTemplate(
      id: 'medication_time',
      title: 'Medication Time',
      messageTemplate: 'Time to take {medicationName} ({dosage}). {instruction}',
      category: ReminderCategory.medication,
      priority: ReminderPriority.critical,
      triggers: ['medication_schedule'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'take_medication',
    ),

    // BMR-based reminders
    SmartReminderTemplate(
      id: 'bmr_maintenance',
      title: 'Calorie Maintenance',
      messageTemplate: 'Your BMR is {bmr} calories/day. To maintain weight, aim for {maintenance} calories with your activity level.',
      category: ReminderCategory.nutrition,
      priority: ReminderPriority.medium,
      triggers: ['bmr_calculated'],
      actionData: {'screen': 'profile'},
    ),
    SmartReminderTemplate(
      id: 'bmr_deficit',
      title: 'Weight Loss Progress',
      messageTemplate: 'With a {deficit} calorie deficit, you could lose {weightLoss}kg per week. You\'re on track!',
      category: ReminderCategory.nutrition,
      priority: ReminderPriority.medium,
      triggers: ['weight_loss_goal'],
      actionData: {'screen': 'profile'},
    ),
  ];

  // Generate smart reminders based on user data
  Future<List<SmartReminder>> generateReminders() async {
    // Don't generate too frequently
    if (DateTime.now().difference(_lastGenerationTime).inMinutes < 30) {
      return _generatedReminders;
    }

    try {
      List<SmartReminder> newReminders = [];

      // Get user data
      final healthProfile = await _getHealthProfile();
      final goals = await _getGoals();
      final todayStats = await _getTodayStats();
      final streakData = await _getStreakData();
      final bmr = await _calculateBMR(healthProfile);

      // Check current time
      final now = DateTime.now();
      final hour = now.hour;

      // Time-based triggers
      if (hour >= 5 && hour <= 8) {
        // Morning
        newReminders.addAll(await _handleMorningTriggers(healthProfile, todayStats, bmr));
      } else if (hour >= 11 && hour <= 13) {
        // Midday
        newReminders.addAll(await _handleMiddayTriggers(healthProfile, todayStats));
      } else if (hour >= 15 && hour <= 17) {
        // Afternoon
        newReminders.addAll(await _handleAfternoonTriggers(todayStats));
      } else if (hour >= 20 && hour <= 23) {
        // Evening
        newReminders.addAll(await _handleEveningTriggers(healthProfile, todayStats));
      }

      // Check hydration status
      newReminders.addAll(await _checkHydrationStatus(todayStats));

      // Check steps progress
      newReminders.addAll(await _checkStepsProgress(todayStats));

      // Check meal logging
      newReminders.addAll(await _checkMealLogging());

      // Check sleep consistency
      newReminders.addAll(await _checkSleepConsistency());

      // Check goal progress
      newReminders.addAll(await _checkGoalProgress(goals));

      // Check streaks
      newReminders.addAll(await _checkStreaks(streakData));

      // Check medication schedule
      newReminders.addAll(await _checkMedicationSchedule());

      // BMR-based reminders
      newReminders.addAll(await _generateBMRReminders(healthProfile, bmr, todayStats));

      // Limit to 10 most relevant reminders
      if (newReminders.length > 10) {
        newReminders.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        newReminders = newReminders.take(10).toList();
      }

      _generatedReminders = newReminders;
      _lastGenerationTime = DateTime.now();

      return newReminders;
    } catch (e) {
      debugPrint('Error generating smart reminders: $e');
      return [];
    }
  }

  // Get cached reminders (don't regenerate every time)
  List<SmartReminder> getCachedReminders() {
    return _generatedReminders;
  }

  // Mark reminder as read
  void markAsRead(String id) {
    final index = _generatedReminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _generatedReminders[index] = SmartReminder(
        id: _generatedReminders[index].id,
        title: _generatedReminders[index].title,
        message: _generatedReminders[index].message,
        category: _generatedReminders[index].category,
        priority: _generatedReminders[index].priority,
        timestamp: _generatedReminders[index].timestamp,
        isRead: true,
        actionData: _generatedReminders[index].actionData,
        actionType: _generatedReminders[index].actionType,
        expiresAt: _generatedReminders[index].expiresAt,
        pointsReward: _generatedReminders[index].pointsReward,
      );
    }
  }

  // Clear all reminders
  void clearReminders() {
    _generatedReminders.clear();
  }

  // ===== HELPER METHODS =====

  Future<HealthProfileModel?> _getHealthProfile() async {
    try {
      final result = await HealthService.getHealthProfile();
      if (result['success'] && result['profile'] != null) {
        return HealthProfileModel.fromJson(result['profile']);
      }
    } catch (e) {
      debugPrint('Error getting health profile: $e');
    }
    return null;
  }

  Future<List<Goal>> _getGoals() async {
    try {
      final result = await GoalService.getGoals();
      if (result['success']) {
        return result['goals'] ?? [];
      }
    } catch (e) {
      debugPrint('Error getting goals: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> _getTodayStats() async {
    Map<String, dynamic> stats = {};

    try {
      // Steps
      final stepsResult = await GoalService.getStepsProgress();
      if (stepsResult['success']) {
        stats['steps'] = _toInt(stepsResult['data']['walked_today']);
        stats['stepsGoal'] = _toInt(stepsResult['data']['daily_target']);
      }

      // Water
      final waterLogs = await GoalService.getWaterLogs(limit: 20);
      if (waterLogs['success']) {
        int waterToday = 0;
        final today = DateTime.now();
        for (var log in waterLogs['data'] ?? []) {
          if (log is Map) {
            try {
              final logDate = DateTime.parse(log['log_date']);
              if (logDate.year == today.year && 
                  logDate.month == today.month && 
                  logDate.day == today.day) {
                waterToday += _toInt(log['glasses']);
              }
            } catch (e) {}
          }
        }
        stats['water'] = waterToday;
      }

      // Sleep
      final sleepResult = await GoalService.getSleepLogs(limit: 1);
      if (sleepResult['success'] && sleepResult['data'] is List && sleepResult['data'].isNotEmpty) {
        final lastSleep = sleepResult['data'][0];
        stats['lastSleep'] = lastSleep;
      }

      // Calories
      final caloriesLogs = await GoalService.getCalorieLogs(limit: 20);
      if (caloriesLogs['success']) {
        int caloriesToday = 0;
        final today = DateTime.now();
        for (var log in caloriesLogs['data'] ?? []) {
          if (log is Map) {
            try {
              final logDate = DateTime.parse(log['log_date']);
              if (logDate.year == today.year && 
                  logDate.month == today.month && 
                  logDate.day == today.day) {
                caloriesToday += _toInt(log['calories']);
              }
            } catch (e) {}
          }
        }
        stats['calories'] = caloriesToday;
      }

    } catch (e) {
      debugPrint('Error getting today stats: $e');
    }

    return stats;
  }

  Future<Map<String, dynamic>> _getStreakData() async {
    // This would come from your gamification provider
    return {
      'currentStreak': 0,
      'longestStreak': 0,
    };
  }

  Future<int> _calculateBMR(HealthProfileModel? profile) async {
    if (profile == null || 
        profile.age == null || 
        profile.weight == null || 
        profile.height == null || 
        profile.gender == null) {
      return 2000; // Default
    }

    double bmr;
    if (profile.gender!.toLowerCase() == 'male') {
      bmr = (10 * profile.weight!) + (6.25 * profile.height!) - (5 * profile.age!) + 5;
    } else {
      bmr = (10 * profile.weight!) + (6.25 * profile.height!) - (5 * profile.age!) - 161;
    }

    // Apply activity factor
    if (profile.activityLevel != null) {
      double factor = 1.2; // Sedentary default
      switch (profile.activityLevel!.toLowerCase()) {
        case 'sedentary':
          factor = 1.2;
          break;
        case 'lightly active':
          factor = 1.375;
          break;
        case 'moderate':
          factor = 1.55;
          break;
        case 'very active':
          factor = 1.725;
          break;
        case 'extremely active':
          factor = 1.9;
          break;
      }
      bmr *= factor;
    }

    return bmr.round();
  }

  // ===== TRIGGER HANDLERS =====

  Future<List<SmartReminder>> _handleMorningTriggers(HealthProfileModel? profile, Map<String, dynamic> todayStats, int bmr) async {
    List<SmartReminder> reminders = [];

    // Morning hydration
    final hydrationTemplate = _templates.firstWhere((t) => t.id == 'hydration_morning');
    reminders.add(hydrationTemplate.createReminder(replacements: {
      'boost': (5 + Random().nextInt(10)).toString(),
    }));

    // BMR reminder (once a day)
    if (bmr > 0 && profile != null) {
      final bmrTemplate = _templates.firstWhere((t) => t.id == 'bmr_maintenance');
      int maintenance = bmr;
      if (profile.healthGoal != null) {
        if (profile.healthGoal!.toLowerCase().contains('lose')) {
          maintenance = (bmr * 0.85).round();
        } else if (profile.healthGoal!.toLowerCase().contains('gain')) {
          maintenance = (bmr * 1.1).round();
        }
      }
      reminders.add(bmrTemplate.createReminder(replacements: {
        'bmr': bmr.toString(),
        'maintenance': maintenance.toString(),
      }));
    }

    return reminders;
  }

  Future<List<SmartReminder>> _handleMiddayTriggers(HealthProfileModel? profile, Map<String, dynamic> todayStats) async {
    List<SmartReminder> reminders = [];

    // Check if breakfast was logged
    final calories = _toInt(todayStats['calories']);
    if (calories < 300) {
      final mealTemplate = _templates.firstWhere((t) => t.id == 'nutrition_meal_skip');
      reminders.add(mealTemplate.createReminder(replacements: {
        'mealType': 'breakfast',
      }));
    }

    return reminders;
  }

  Future<List<SmartReminder>> _handleAfternoonTriggers(Map<String, dynamic> todayStats) async {
    List<SmartReminder> reminders = [];

    // Check steps progress
    final steps = _toInt(todayStats['steps']);
    final stepsGoal = _toInt(todayStats['stepsGoal']);
    final percentage = stepsGoal > 0 ? (steps / stepsGoal * 100).round() : 0;

    if (percentage < 30) {
      final activityTemplate = _templates.firstWhere((t) => t.id == 'activity_sedentary');
      reminders.add(activityTemplate.createReminder(replacements: {
        'hours': '3-4',
        'minutes': '10',
      }));
    } else if (percentage > 70 && percentage < 90) {
      final closeTemplate = _templates.firstWhere((t) => t.id == 'activity_goal_close');
      reminders.add(closeTemplate.createReminder(replacements: {
        'remaining': (stepsGoal - steps).toString(),
      }));
    }

    // Midday mindfulness
    final mindfulnessTemplate = _templates.firstWhere((t) => t.id == 'mindfulness_midday');
    reminders.add(mindfulnessTemplate.createReminder(replacements: {
      'minutes': '5',
    }));

    return reminders;
  }

  Future<List<SmartReminder>> _handleEveningTriggers(HealthProfileModel? profile, Map<String, dynamic> todayStats) async {
    List<SmartReminder> reminders = [];

    // Check if dinner was logged
    final calories = _toInt(todayStats['calories']);
    if (calories < 1500) {
      final mealTemplate = _templates.firstWhere((t) => t.id == 'nutrition_meal_skip');
      reminders.add(mealTemplate.createReminder(replacements: {
        'mealType': 'dinner',
      }));
    }

    // Bedtime reminder
    if (profile != null && profile.age != null) {
      final bedtimeTemplate = _templates.firstWhere((t) => t.id == 'sleep_bedtime');
      final wakeHour = 6 + Random().nextInt(2); // Assume wake time between 6-8 AM
      final hoursUntilBed = (wakeHour + 8 - DateTime.now().hour).clamp(1, 5);
      reminders.add(bedtimeTemplate.createReminder(replacements: {
        'wakeTime': '$wakeHour:00 AM',
        'hoursUntilBed': hoursUntilBed.toString(),
      }));
    }

    return reminders;
  }

  Future<List<SmartReminder>> _checkHydrationStatus(Map<String, dynamic> todayStats) async {
    List<SmartReminder> reminders = [];
    final water = _toInt(todayStats['water']);

    if (water == 0) {
      final template = _templates.firstWhere((t) => t.id == 'hydration_morning');
      reminders.add(template.createReminder(replacements: {
        'boost': '10',
      }));
    } else if (water < 4) {
      final template = _templates.firstWhere((t) => t.id == 'hydration_progress');
      reminders.add(template.createReminder(replacements: {
        'glasses': water.toString(),
        'message': 'Try to reach 8 glasses by evening.',
      }));
    }

    return reminders;
  }

  Future<List<SmartReminder>> _checkStepsProgress(Map<String, dynamic> todayStats) async {
    List<SmartReminder> reminders = [];
    final steps = _toInt(todayStats['steps']);
    final stepsGoal = _toInt(todayStats['stepsGoal']);

    if (steps > 0 && steps < stepsGoal) {
      final template = _templates.firstWhere((t) => t.id == 'activity_steps_progress');
      final percentage = stepsGoal > 0 ? (steps / stepsGoal * 100).round() : 0;
      String message = '';
      if (percentage < 30) {
        message = 'Time to get moving!';
      } else if (percentage < 60) {
        message = 'You\'re making progress!';
      } else if (percentage < 90) {
        message = 'Almost there!';
      }
      reminders.add(template.createReminder(replacements: {
        'steps': steps.toString(),
        'percentage': percentage.toString(),
        'message': message,
      }));
    }

    return reminders;
  }

  Future<List<SmartReminder>> _checkMealLogging() async {
    // This would check if meals are logged at appropriate times
    // For now, return empty list
    return [];
  }

  Future<List<SmartReminder>> _checkSleepConsistency() async {
    // This would check sleep patterns
    // For now, return empty list
    return [];
  }

  Future<List<SmartReminder>> _checkGoalProgress(List<Goal> goals) async {
    List<SmartReminder> reminders = [];

    for (var goal in goals) {
      if (goal.status == GoalStatus.active && goal.progress >= 0.8 && goal.progress < 1.0) {
        // Goal close to completion
        final template = _templates.firstWhere((t) => t.id == 'activity_goal_close');
        final remaining = (goal.targetValue - goal.currentValue).round();
        reminders.add(template.createReminder(replacements: {
          'remaining': remaining.toString(),
        }));
      }
    }

    return reminders;
  }

  Future<List<SmartReminder>> _checkStreaks(Map<String, dynamic> streakData) async {
    List<SmartReminder> reminders = [];
    final currentStreak = _toInt(streakData['currentStreak']);

    if (currentStreak > 0 && currentStreak % 7 == 0) {
      // Weekly milestone
      final template = _templates.firstWhere((t) => t.id == 'streak_milestone');
      reminders.add(template.createReminder(replacements: {
        'days': currentStreak.toString(),
      }));
    }

    return reminders;
  }

  Future<List<SmartReminder>> _checkMedicationSchedule() async {
    // This would check medication schedules
    // For now, return empty list
    return [];
  }

  Future<List<SmartReminder>> _generateBMRReminders(HealthProfileModel? profile, int bmr, Map<String, dynamic> todayStats) async {
    List<SmartReminder> reminders = [];

    if (profile != null && profile.healthGoal != null) {
      if (profile.healthGoal!.toLowerCase().contains('lose')) {
        final template = _templates.firstWhere((t) => t.id == 'bmr_deficit');
        final deficit = (bmr * 0.15).round();
        final weightLoss = (deficit * 7 / 7700).toStringAsFixed(2); // 7700 calories per kg
        reminders.add(template.createReminder(replacements: {
          'deficit': deficit.toString(),
          'weightLoss': weightLoss,
        }));
      }
    }

    return reminders;
  }

  // Get reminder by ID
  SmartReminder? getReminderById(String id) {
    try {
      return _generatedReminders.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get unread count
  int getUnreadCount() {
    return _generatedReminders.where((r) => !r.isRead).length;
  }

  // Get reminders by category
  List<SmartReminder> getRemindersByCategory(ReminderCategory category) {
    return _generatedReminders.where((r) => r.category == category).toList();
  }

  // Get high priority reminders
  List<SmartReminder> getHighPriorityReminders() {
    return _generatedReminders
        .where((r) => r.priority == ReminderPriority.high || r.priority == ReminderPriority.critical)
        .where((r) => !r.isRead)
        .toList();
  }
}