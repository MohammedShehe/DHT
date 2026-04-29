import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/smart_reminder_model.dart';
import '../models/health_profile_model.dart';
import '../models/gamification_models.dart';
import '../models/activity_models.dart';
import '../services/goal_service.dart';
import '../services/health_service.dart';
import '../services/auth_service.dart';
import '../services/activity_service.dart';

class SmartReminderService {
  static final SmartReminderService _instance = SmartReminderService._internal();
  factory SmartReminderService() => _instance;
  SmartReminderService._internal();

  List<SmartReminder> _generatedReminders = [];
  List<SmartReminder> _medicationReminders = [];
  DateTime _lastGenerationTime = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _lastMedicationCheckTime = DateTime.now().subtract(const Duration(minutes: 30));

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

    // MEDICATION REMINDERS - NEW TEMPLATES
    SmartReminderTemplate(
      id: 'medication_upcoming',
      title: 'Upcoming Medication',
      messageTemplate: '{medicationName} ({dosage}) is due in {minutes} minutes. Remember to take it {instructions}.',
      category: ReminderCategory.medication,
      priority: ReminderPriority.high,
      triggers: ['medication_upcoming'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'take_medication',
    ),
    SmartReminderTemplate(
      id: 'medication_time',
      title: 'Time for Medication',
      messageTemplate: 'Time to take {medicationName} ({dosage}) now. {instructions}',
      category: ReminderCategory.medication,
      priority: ReminderPriority.critical,
      triggers: ['medication_due'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'take_medication',
      pointsReward: 10,
    ),
    SmartReminderTemplate(
      id: 'medication_late',
      title: 'Medication Late',
      messageTemplate: 'Your {medicationName} is due! Please take it as soon as possible. {instructions}',
      category: ReminderCategory.medication,
      priority: ReminderPriority.critical,
      triggers: ['medication_late'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'take_medication',
    ),
    SmartReminderTemplate(
      id: 'medication_missed',
      title: 'Missed Medication',
      messageTemplate: 'You missed your {medicationName} scheduled for {scheduledTime}. Please take it now if still appropriate.',
      category: ReminderCategory.medication,
      priority: ReminderPriority.critical,
      triggers: ['medication_missed'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'take_medication',
    ),
    SmartReminderTemplate(
      id: 'medication_refill',
      title: 'Refill Reminder',
      messageTemplate: 'You have {daysLeft} days left of {medicationName}. Time to request a refill!',
      category: ReminderCategory.medication,
      priority: ReminderPriority.medium,
      triggers: ['medication_low_supply'],
      actionData: {'screen': 'activity', 'tab': 4},
      actionType: 'medication_refill',
    ),
    SmartReminderTemplate(
      id: 'medication_adherence',
      title: 'Adherence Milestone',
      messageTemplate: 'Great job! You\'ve taken your medications on time for {days} days in a row!',
      category: ReminderCategory.medication,
      priority: ReminderPriority.high,
      triggers: ['medication_adherence_milestone'],
      actionData: {'screen': 'activity', 'tab': 4},
      pointsReward: 25,
    ),
    SmartReminderTemplate(
      id: 'medication_instruction',
      title: 'Medication Instruction',
      messageTemplate: 'Remember to {instruction} with your {medicationName} for best results.',
      category: ReminderCategory.medication,
      priority: ReminderPriority.low,
      triggers: ['medication_general'],
      actionData: {'screen': 'activity', 'tab': 4},
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
      
      // MEDICATION DATA
      final medications = await _getMedications();
      final upcomingDoses = await _getUpcomingMedicationDoses();
      final missedDoses = await _getMissedMedicationDoses();

      // Check current time
      final now = DateTime.now();
      final hour = now.hour;

      // Time-based triggers
      if (hour >= 5 && hour <= 8) {
        newReminders.addAll(await _handleMorningTriggers(healthProfile, todayStats, bmr));
      } else if (hour >= 11 && hour <= 13) {
        newReminders.addAll(await _handleMiddayTriggers(healthProfile, todayStats));
      } else if (hour >= 15 && hour <= 17) {
        newReminders.addAll(await _handleAfternoonTriggers(todayStats));
      } else if (hour >= 20 && hour <= 23) {
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

      // ===== ADD MEDICATION REMINDERS =====
      newReminders.addAll(await _checkMedicationSchedule(medications, upcomingDoses, missedDoses));

      // BMR-based reminders
      newReminders.addAll(await _generateBMRReminders(healthProfile, bmr, todayStats));

      // Store medication reminders separately for tracking
      _medicationReminders = newReminders
          .where((r) => r.category == ReminderCategory.medication)
          .toList();

      // Limit to 15 most relevant reminders (increased for medications)
      if (newReminders.length > 15) {
        newReminders.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        newReminders = newReminders.take(15).toList();
      }

      _generatedReminders = newReminders;
      _lastGenerationTime = DateTime.now();

      return newReminders;
    } catch (e) {
      debugPrint('Error generating smart reminders: $e');
      return [];
    }
  }

  // Get all medication-specific reminders
  List<SmartReminder> getMedicationReminders() {
    return _medicationReminders;
  }

  // Get pending medication reminders (not taken yet)
  List<SmartReminder> getPendingMedicationReminders() {
    return _medicationReminders.where((r) => !r.isRead).toList();
  }

  // Get high priority medication reminders
  List<SmartReminder> getCriticalMedicationReminders() {
    return _medicationReminders
        .where((r) => r.priority == ReminderPriority.critical && !r.isRead)
        .toList();
  }

  // Generate medication reminders only (can be called more frequently)
  Future<List<SmartReminder>> generateMedicationReminders() async {
    if (DateTime.now().difference(_lastMedicationCheckTime).inMinutes < 15) {
      return _medicationReminders;
    }

    try {
      final upcomingDoses = await _getUpcomingMedicationDoses();
      final missedDoses = await _getMissedMedicationDoses();
      final medications = await _getMedications();

      final newMedicationReminders = await _checkMedicationSchedule(
        medications, 
        upcomingDoses, 
        missedDoses
      );

      // Merge with existing reminders (keep unread ones)
      final existingUnread = _medicationReminders.where((r) => !r.isRead).toList();
      final allReminders = [...existingUnread, ...newMedicationReminders];
      
      // Remove duplicates based on ID
      final uniqueReminders = <String, SmartReminder>{};
      for (var r in allReminders) {
        uniqueReminders[r.id] = r;
      }
      
      _medicationReminders = uniqueReminders.values.toList();
      _lastMedicationCheckTime = DateTime.now();

      // Also update main reminders list
      final nonMedicationReminders = _generatedReminders
          .where((r) => r.category != ReminderCategory.medication)
          .toList();
      _generatedReminders = [...nonMedicationReminders, ..._medicationReminders];
      _generatedReminders.sort((a, b) => b.priority.index.compareTo(a.priority.index));

      return _medicationReminders;
    } catch (e) {
      debugPrint('Error generating medication reminders: $e');
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
    
    // Also mark in medication list if applicable
    final medIndex = _medicationReminders.indexWhere((r) => r.id == id);
    if (medIndex >= 0) {
      _medicationReminders[medIndex] = _generatedReminders[index];
    }
  }

  // Clear all reminders
  void clearReminders() {
    _generatedReminders.clear();
    _medicationReminders.clear();
  }

  // Clear medication reminders only
  void clearMedicationReminders() {
    _medicationReminders.clear();
    _generatedReminders = _generatedReminders
        .where((r) => r.category != ReminderCategory.medication)
        .toList();
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

  // ===== MEDICATION-SPECIFIC METHODS =====

  Future<List<Medication>> _getMedications() async {
    try {
      return await ActivityService.getMedications();
    } catch (e) {
      debugPrint('Error getting medications: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUpcomingMedicationDoses() async {
    try {
      final doses = await ActivityService.getUpcomingMedicationDoses();
      return doses;
    } catch (e) {
      debugPrint('Error getting upcoming doses: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getMissedMedicationDoses() async {
    try {
      final missed = await ActivityService.getMissedMedicationDoses(DateTime.now());
      return missed;
    } catch (e) {
      debugPrint('Error getting missed doses: $e');
      return [];
    }
  }

  Future<void> _logMedicationIntake(int medicationId, int scheduleId) async {
    try {
      final now = DateTime.now();
      final logDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final logTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
      
      await ActivityService.logMedicationIntake(
        medicationId: medicationId,
        scheduleId: scheduleId,
        logDate: logDate,
        logTime: logTime,
        status: 'taken',
        actualTime: logTime,
      );
    } catch (e) {
      debugPrint('Error logging medication intake: $e');
    }
  }

  Future<int> _getMedicationAdherenceStreak(int medicationId) async {
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      final result = await ActivityService.getMedicationAdherenceRate(
        medicationId, 
        startDate, 
        endDate
      );
      
      if (result['success'] && result['adherence'] != null) {
        // Calculate streak from adherence data
        final adherence = result['adherence'];
        return _toInt(adherence['current_streak']);
      }
    } catch (e) {
      debugPrint('Error getting adherence streak: $e');
    }
    return 0;
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

  // ===== COMPREHENSIVE MEDICATION SCHEDULE CHECK =====
  Future<List<SmartReminder>> _checkMedicationSchedule(
    List<Medication> medications,
    List<Map<String, dynamic>> upcomingDoses,
    List<Map<String, dynamic>> missedDoses,
  ) async {
    List<SmartReminder> reminders = [];
    final now = DateTime.now();
    final currentMinute = now.hour * 60 + now.minute;

    // Process upcoming doses (15-30 minutes before scheduled time)
    for (var dose in upcomingDoses) {
      final scheduledTime = _parseDateTime(dose['scheduled_time']);
      if (scheduledTime == null) continue;
      
      final minutesUntil = scheduledTime.difference(now).inMinutes;
      final medicationName = dose['medication_name']?.toString() ?? 'Your medication';
      final dosage = dose['actual_dosage']?.toString() ?? '';
      final unit = dose['unit']?.toString() ?? 'mg';
      final instructions = dose['instructions']?.toString() ?? '';
      final medicationId = _toInt(dose['medication_id']);
      final scheduleId = _toInt(dose['schedule_id']);

      // Create different reminders based on how close the dose is
      if (minutesUntil <= 5 && minutesUntil >= 0) {
        // Due now
        final template = _templates.firstWhere((t) => t.id == 'medication_time');
        reminders.add(template.createReminder(replacements: {
          'medicationName': medicationName,
          'dosage': '$dosage $unit',
          'instructions': instructions.isNotEmpty ? instructions : 'Take as prescribed',
        }));
      } else if (minutesUntil <= 15 && minutesUntil > 5) {
        // Upcoming in 5-15 minutes
        final template = _templates.firstWhere((t) => t.id == 'medication_upcoming');
        reminders.add(template.createReminder(replacements: {
          'medicationName': medicationName,
          'dosage': '$dosage $unit',
          'minutes': minutesUntil.toString(),
          'instructions': instructions.isNotEmpty ? instructions : '',
        }));
      } else if (minutesUntil < 0 && minutesUntil > -60) {
        // Late but less than 1 hour late
        final template = _templates.firstWhere((t) => t.id == 'medication_late');
        reminders.add(template.createReminder(replacements: {
          'medicationName': medicationName,
          'dosage': '$dosage $unit',
          'instructions': instructions.isNotEmpty ? instructions : 'Take it now',
        }));
      }
    }

    // Process missed doses (more than 1 hour late)
    for (var dose in missedDoses) {
      final scheduledTime = _parseDateTime(dose['scheduled_time']);
      if (scheduledTime == null) continue;
      
      final minutesLate = now.difference(scheduledTime).inMinutes;
      final medicationName = dose['medication_name']?.toString() ?? 'Your medication';
      final dosage = dose['actual_dosage']?.toString() ?? '';
      final unit = dose['unit']?.toString() ?? 'mg';
      final instructions = dose['instructions']?.toString() ?? '';

      if (minutesLate > 60) {
        final template = _templates.firstWhere((t) => t.id == 'medication_missed');
        reminders.add(template.createReminder(replacements: {
          'medicationName': medicationName,
          'dosage': '$dosage $unit',
          'scheduledTime': _formatTime(scheduledTime),
        }));
      }
    }

    // Check for low supply/refill reminders
    for (var medication in medications) {
      if (medication.endDate != null) {
        final daysLeft = medication.endDate!.difference(now).inDays;
        if (daysLeft <= 7 && daysLeft > 0) {
          final template = _templates.firstWhere((t) => t.id == 'medication_refill');
          reminders.add(template.createReminder(replacements: {
            'daysLeft': daysLeft.toString(),
            'medicationName': medication.name,
          }));
        }
      }
      
      // Adherence streak milestone
      final adherenceStreak = await _getMedicationAdherenceStreak(medication.id);
      if (adherenceStreak == 7 || adherenceStreak == 14 || adherenceStreak == 30) {
        final template = _templates.firstWhere((t) => t.id == 'medication_adherence');
        reminders.add(template.createReminder(replacements: {
          'days': adherenceStreak.toString(),
        }));
      }
      
      // General instruction reminder (once per medication per day)
      if (medication.instructions != null && medication.instructions!.isNotEmpty) {
        // Check if we already sent an instruction reminder today for this medication
        final lastReminderKey = 'med_instruction_${medication.id}_${now.day}';
        if (await _shouldSendReminder(lastReminderKey, 24)) {
          final template = _templates.firstWhere((t) => t.id == 'medication_instruction');
          reminders.add(template.createReminder(replacements: {
            'instruction': medication.instructions!,
            'medicationName': medication.name,
          }));
          await _markReminderSent(lastReminderKey);
        }
      }
    }

    // Set expiration times for medication reminders (1 hour for due, 2 hours for missed)
    final updatedReminders = <SmartReminder>[];
    for (var reminder in reminders) {
      DateTime? expiresAt;
      if (reminder.id.contains('medication_time') || reminder.id.contains('medication_upcoming')) {
        expiresAt = DateTime.now().add(const Duration(hours: 1));
      } else if (reminder.id.contains('medication_missed')) {
        expiresAt = DateTime.now().add(const Duration(hours: 2));
      } else if (reminder.id.contains('medication_late')) {
        expiresAt = DateTime.now().add(const Duration(hours: 1));
      }
      
      updatedReminders.add(SmartReminder(
        id: reminder.id,
        title: reminder.title,
        message: reminder.message,
        category: reminder.category,
        priority: reminder.priority,
        timestamp: reminder.timestamp,
        isRead: reminder.isRead,
        actionData: reminder.actionData,
        actionType: reminder.actionType,
        expiresAt: expiresAt,
        pointsReward: reminder.pointsReward,
      ));
    }

    return updatedReminders;
  }

  // ===== HELPER METHODS FOR MEDICATION REMINDERS =====

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<bool> _shouldSendReminder(String key, int hoursInterval) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSent = prefs.getInt(key);
      if (lastSent == null) return true;
      
      final lastSentTime = DateTime.fromMillisecondsSinceEpoch(lastSent);
      return DateTime.now().difference(lastSentTime).inHours >= hoursInterval;
    } catch (e) {
      return true;
    }
  }

  Future<void> _markReminderSent(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error marking reminder sent: $e');
    }
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

  // Get unread medication count
  int getUnreadMedicationCount() {
    return _medicationReminders.where((r) => !r.isRead).length;
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
