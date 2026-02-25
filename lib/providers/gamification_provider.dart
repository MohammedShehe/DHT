import 'package:flutter/material.dart';
import '../models/gamification_models.dart' as gamification;
import '../services/goal_service.dart';

class GamificationProvider extends ChangeNotifier {
  // User Stats
  gamification.UserStats? _userStats;
  List<gamification.Badge> _badges = [];
  List<gamification.LeaderboardEntry> _leaderboard = [];
  List<gamification.Goal> _goals = [];
  List<gamification.Reminder> _reminders = [];
  
  bool _isLoading = false;
  bool _isLoadingGoals = false;
  String? _error;

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  // Getters
  gamification.UserStats? get userStats => _userStats;
  List<gamification.Badge> get badges => _badges;
  List<gamification.Badge> get earnedBadges => _badges.where((b) => b.isEarned).toList();
  List<gamification.Badge> get unearnedBadges => _badges.where((b) => !b.isEarned).toList();
  List<gamification.LeaderboardEntry> get leaderboard => _leaderboard;
  List<gamification.Goal> get goals => _goals;
  List<gamification.Goal> get activeGoals => _goals.where((g) => g.status == gamification.GoalStatus.active).toList();
  List<gamification.Goal> get completedGoals => _goals.where((g) => g.status == gamification.GoalStatus.completed).toList();
  List<gamification.Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  bool get isLoadingGoals => _isLoadingGoals;
  String? get error => _error;

  // Leaderboard filters
  List<gamification.LeaderboardEntry> get topThree => _leaderboard.take(3).toList();
  gamification.LeaderboardEntry? get currentUserEntry {
    try {
      return _leaderboard.firstWhere((e) => e.isCurrentUser);
    } catch (e) {
      return _leaderboard.isNotEmpty ? _leaderboard.first : null;
    }
  }

  GamificationProvider() {
    _initializeMockData();
    loadGoals(); // Load goals from backend
  }

  void _initializeMockData() {
    _isLoading = true;
    notifyListeners();

    // Mock user stats
    _userStats = gamification.UserStats(
      currentStreak: 12,
      longestStreak: 21,
      totalPoints: 2450,
      level: 5,
      pointsToNextLevel: 150,
      levelProgress: 0.65,
      categoryPoints: {
        'activity': 850,
        'nutrition': 620,
        'sleep': 480,
        'hydration': 500,
      },
      badgesEarned: 8,
      totalBadges: 24,
    );

    // Mock badges
    _badges = [
      gamification.Badge(
        id: '1',
        name: 'Early Bird',
        description: 'Log activity before 8 AM for 7 days straight',
        iconPath: Icons.wb_sunny.toString(),
        rarity: gamification.BadgeRarity.rare,
        category: gamification.BadgeCategory.consistency,
        pointsValue: 50,
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      gamification.Badge(
        id: '2',
        name: 'Hydration Hero',
        description: 'Reach water goal for 30 days',
        iconPath: Icons.local_drink.toString(),
        rarity: gamification.BadgeRarity.epic,
        category: gamification.BadgeCategory.hydration,
        pointsValue: 100,
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      gamification.Badge(
        id: '3',
        name: 'Marathon Runner',
        description: 'Run a total of 100 km',
        iconPath: Icons.directions_run.toString(),
        rarity: gamification.BadgeRarity.legendary,
        category: gamification.BadgeCategory.activity,
        pointsValue: 200,
        isEarned: false,
      ),
      gamification.Badge(
        id: '4',
        name: 'Sleep Master',
        description: 'Get 8+ hours of sleep for 14 consecutive days',
        iconPath: Icons.bedtime.toString(),
        rarity: gamification.BadgeRarity.epic,
        category: gamification.BadgeCategory.sleep,
        pointsValue: 150,
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      gamification.Badge(
        id: '5',
        name: 'Perfect Week',
        description: 'Complete all daily goals for an entire week',
        iconPath: Icons.calendar_today.toString(),
        rarity: gamification.BadgeRarity.rare,
        category: gamification.BadgeCategory.consistency,
        pointsValue: 75,
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 12)),
      ),
      gamification.Badge(
        id: '6',
        name: 'Salad Lover',
        description: 'Log 50 healthy meals',
        iconPath: Icons.eco.toString(),
        rarity: gamification.BadgeRarity.common,
        category: gamification.BadgeCategory.nutrition,
        pointsValue: 25,
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
      gamification.Badge(
        id: '7',
        name: 'Century Club',
        description: 'Complete 100 workouts',
        iconPath: Icons.fitness_center.toString(),
        rarity: gamification.BadgeRarity.legendary,
        category: gamification.BadgeCategory.activity,
        pointsValue: 250,
        isEarned: false,
      ),
      gamification.Badge(
        id: '8',
        name: 'Mindfulness Guru',
        description: 'Meditate for 30 consecutive days',
        iconPath: Icons.self_improvement.toString(),
        rarity: gamification.BadgeRarity.epic,
        category: gamification.BadgeCategory.activity,
        pointsValue: 175,
        isEarned: false,
      ),
    ];

    // Mock leaderboard
    _leaderboard = [
      gamification.LeaderboardEntry(
        userId: '101',
        userName: 'Sarah Johnson',
        points: 3840,
        streak: 45,
        rank: 1,
      ),
      gamification.LeaderboardEntry(
        userId: '102',
        userName: 'Mike Chen',
        points: 3620,
        streak: 38,
        rank: 2,
      ),
      gamification.LeaderboardEntry(
        userId: '103',
        userName: 'Emma Davis',
        points: 3410,
        streak: 31,
        rank: 3,
      ),
      gamification.LeaderboardEntry(
        userId: '104',
        userName: 'Alex Rodriguez',
        points: 3250,
        streak: 28,
        rank: 4,
      ),
      gamification.LeaderboardEntry(
        userId: 'current',
        userName: 'You',
        points: 2980,
        streak: 21,
        rank: 5,
        isCurrentUser: true,
      ),
      gamification.LeaderboardEntry(
        userId: '105',
        userName: 'Lisa Wang',
        points: 2840,
        streak: 19,
        rank: 6,
      ),
      gamification.LeaderboardEntry(
        userId: '106',
        userName: 'Tom Harris',
        points: 2670,
        streak: 15,
        rank: 7,
      ),
      gamification.LeaderboardEntry(
        userId: '107',
        userName: 'Nina Patel',
        points: 2510,
        streak: 12,
        rank: 8,
      ),
    ];

    // Mock reminders
    _reminders = [
      gamification.Reminder(
        id: 'r1',
        title: 'Morning Workout',
        description: 'Time for your daily exercise',
        time: const TimeOfDay(hour: 7, minute: 0),
        repeatDays: [1, 2, 3, 4, 5],
        isEnabled: true,
        action: 'open_activity',
      ),
      gamification.Reminder(
        id: 'r2',
        title: 'Drink Water',
        description: 'Stay hydrated!',
        time: const TimeOfDay(hour: 10, minute: 30),
        repeatDays: [0, 1, 2, 3, 4, 5, 6],
        isEnabled: true,
        action: 'open_hydration',
      ),
      gamification.Reminder(
        id: 'r3',
        title: 'Lunch Time',
        description: 'Time to log your meal',
        time: const TimeOfDay(hour: 12, minute: 0),
        repeatDays: [1, 2, 3, 4, 5],
        isEnabled: true,
        action: 'open_meal',
      ),
      gamification.Reminder(
        id: 'r4',
        title: 'Evening Meditation',
        description: '10 minutes of mindfulness',
        time: const TimeOfDay(hour: 20, minute: 0),
        repeatDays: [0, 1, 2, 3, 4, 5, 6],
        isEnabled: false,
        action: 'open_meditation',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Load goals from backend
  Future<void> loadGoals() async {
    _isLoadingGoals = true;
    notifyListeners();
    
    try {
      final result = await GoalService.getGoals();
      
      if (result['success']) {
        _goals = result['goals'] ?? [];
        _error = null;
      } else {
        _error = result['message'];
        _showMessage('Error loading goals: ${result['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error loading goals: $e', isError: true);
    } finally {
      _isLoadingGoals = false;
      notifyListeners();
    }
  }

  // Create new goal
  Future<void> addGoal(gamification.Goal goal) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await GoalService.createGoal(
        type: goal.type,
        targetValue: goal.targetValue,
        period: goal.period,
      );

      if (result['success']) {
        if (result['goal'] != null) {
          _goals.add(result['goal']);
          _showMessage('Goal created successfully');
          notifyListeners(); // Notify immediately
        } else {
          // If no goal returned, refresh to get it
          await loadGoals();
        }
      } else {
        _error = result['message'];
        _showMessage('Error creating goal: ${result['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error creating goal: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update goal progress by logging activity
  Future<void> logActivityProgress({
    required gamification.GoalType type,
    required double value,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> result;
      
      // Call the appropriate log method based on goal type
      switch (type) {
        case gamification.GoalType.steps:
          result = await GoalService.logSteps(value.toInt());
          break;
        case gamification.GoalType.water:
          result = await GoalService.logWater(value.toInt());
          break;
        case gamification.GoalType.sleep:
          result = await GoalService.logSleep(value);
          break;
        case gamification.GoalType.meditation:
          result = await GoalService.logMeditation(value.toInt());
          break;
        case gamification.GoalType.workouts:
          result = await GoalService.logWorkouts(value.toInt());
          break;
        case gamification.GoalType.calories:
          result = await GoalService.logCalories(value.toInt());
          break;
      }

      if (result['success']) {
        // Check if goal was completed with this log
        if (result['completed'] == true) {
          // Award points for completing goal (mock for now)
          final pointsEarned = _calculatePointsForGoal(type);
          _updateUserStatsWithPoints(pointsEarned);
          _showMessage('🎉 Goal completed! +$pointsEarned points');
        } else {
          _showMessage(result['message'] ?? 'Progress logged successfully');
        }
        
        // Refresh goals to get updated progress
        await loadGoals();
      } else {
        _showMessage(result['message'] ?? 'Failed to log progress', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error logging progress: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete goal
  Future<void> deleteGoal(gamification.Goal goal) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await GoalService.deleteGoal(goal.type);
      
      if (result['success']) {
        _goals.removeWhere((g) => g.id == goal.id);
        _showMessage('Goal deleted successfully');
        notifyListeners();
      } else {
        _showMessage('Error deleting goal: ${result['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error deleting goal: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing goal (delete and recreate)
  Future<void> updateGoal(gamification.Goal oldGoal, gamification.Goal newGoal) async {
    _isLoading = true;
    notifyListeners();

    try {
      // First delete the old goal
      final deleteResult = await GoalService.deleteGoal(oldGoal.type);
      
      if (!deleteResult['success']) {
        _showMessage('Failed to update goal: ${deleteResult['message']}', isError: true);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Then create the new goal
      final createResult = await GoalService.createGoal(
        type: newGoal.type,
        targetValue: newGoal.targetValue,
        period: newGoal.period,
      );

      if (createResult['success']) {
        if (createResult['goal'] != null) {
          // Replace the old goal with the new one
          final index = _goals.indexWhere((g) => g.id == oldGoal.id);
          if (index >= 0) {
            _goals[index] = createResult['goal'];
          } else {
            _goals.add(createResult['goal']);
          }
          _showMessage('Goal updated successfully');
          notifyListeners();
        } else {
          await loadGoals();
        }
      } else {
        _showMessage('Error updating goal: ${createResult['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error updating goal: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to calculate points for completing a goal
  int _calculatePointsForGoal(gamification.GoalType type) {
    // Mock points calculation - you can customize this based on your gamification system
    switch (type) {
      case gamification.GoalType.steps:
        return 10;
      case gamification.GoalType.water:
        return 8;
      case gamification.GoalType.sleep:
        return 12;
      case gamification.GoalType.meditation:
        return 15;
      case gamification.GoalType.workouts:
        return 20;
      case gamification.GoalType.calories:
        return 10;
    }
  }

  // Reminder methods (unchanged)
  Future<void> addReminder(gamification.Reminder reminder) async {
    try {
      _reminders.add(reminder);
      _showMessage('Reminder set successfully');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _showMessage('Error setting reminder: $e', isError: true);
      notifyListeners();
    }
  }

  Future<void> updateReminder(gamification.Reminder reminder) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index >= 0) {
        _reminders[index] = reminder;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error updating reminder: $e', isError: true);
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      _reminders.removeWhere((r) => r.id == reminderId);
      _showMessage('Reminder deleted');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _showMessage('Error deleting reminder: $e', isError: true);
      notifyListeners();
    }
  }

  Future<void> toggleReminder(String reminderId) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index >= 0) {
        final oldReminder = _reminders[index];
        
        final updatedReminder = gamification.Reminder(
          id: oldReminder.id,
          title: oldReminder.title,
          description: oldReminder.description,
          time: oldReminder.time,
          repeatDays: oldReminder.repeatDays,
          isEnabled: !oldReminder.isEnabled,
          action: oldReminder.action,
          actionData: oldReminder.actionData,
        );
        
        _reminders[index] = updatedReminder;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error toggling reminder: $e', isError: true);
      notifyListeners();
    }
  }

  // Helper method to update user stats
  void _updateUserStatsWithPoints(int points) {
    if (_userStats != null) {
      final oldStats = _userStats!;
      
      final newTotalPoints = oldStats.totalPoints + points;
      int newLevel = oldStats.level;
      
      // Check for level up (simple formula: level * 100 points needed)
      while (newTotalPoints >= (newLevel * 100)) {
        newLevel++;
      }
      
      final pointsForCurrentLevel = (newLevel - 1) * 100;
      final progress = (newTotalPoints - pointsForCurrentLevel) / 100;
      
      _userStats = gamification.UserStats(
        currentStreak: oldStats.currentStreak,
        longestStreak: oldStats.longestStreak,
        totalPoints: newTotalPoints,
        level: newLevel,
        pointsToNextLevel: (newLevel * 100) - newTotalPoints,
        levelProgress: progress.clamp(0.0, 1.0),
        categoryPoints: oldStats.categoryPoints,
        badgesEarned: oldStats.badgesEarned,
        totalBadges: oldStats.totalBadges,
      );
      
      if (newLevel > oldStats.level) {
        _showMessage('🎉 Level Up! You are now level $newLevel');
      }
    }
  }

  // Method to add points (called from other providers)
  void addPoints(int points, {String? reason}) {
    _updateUserStatsWithPoints(points);
    notifyListeners();
  }

  // Helper methods
  List<gamification.Badge> getBadgesByCategory(gamification.BadgeCategory category) {
    return _badges.where((b) => b.category == category).toList();
  }

  List<gamification.Badge> getRecentEarnedBadges({int limit = 5}) {
    final earned = _badges
        .where((b) => b.isEarned && b.earnedDate != null)
        .toList();
    
    earned.sort((a, b) => b.earnedDate!.compareTo(a.earnedDate!));
    
    if (earned.length > limit) {
      return earned.sublist(0, limit);
    }
    return earned;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }

  void setState(void Function() fn) {
    fn();
  }
}