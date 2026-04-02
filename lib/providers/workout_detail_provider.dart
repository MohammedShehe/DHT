// lib/providers/workout_detail_provider.dart
import 'package:flutter/material.dart';
import '../models/workout_detail_models.dart';
import '../services/workout_detail_service.dart';

class WorkoutDetailProvider extends ChangeNotifier {
  List<WorkoutType> _workoutTypes = [];
  List<WorkoutDetail> _workouts = [];
  WorkoutStats? _dailyStats;
  List<WeeklyWorkoutStats> _weeklyStats = [];
  List<IntensityDistribution> _intensityDistribution = [];
  List<WorkoutTypeStats> _workoutTypeStats = [];
  
  bool _isLoading = false;
  bool _isLoadingWorkouts = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  // Getters
  List<WorkoutType> get workoutTypes => _workoutTypes;
  List<WorkoutDetail> get workouts => _workouts;
  WorkoutStats? get dailyStats => _dailyStats;
  List<WeeklyWorkoutStats> get weeklyStats => _weeklyStats;
  List<IntensityDistribution> get intensityDistribution => _intensityDistribution;
  List<WorkoutTypeStats> get workoutTypeStats => _workoutTypeStats;
  bool get isLoading => _isLoading;
  bool get isLoadingWorkouts => _isLoadingWorkouts;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  int get totalDuration => _workouts.fold(0, (sum, w) => sum + w.durationMinutes);
  int get totalCalories => _workouts.fold(0, (sum, w) => sum + (w.caloriesBurned ?? 0));
  double get totalDistance => _workouts.fold(0.0, (sum, w) => sum + (w.distance ?? 0));
  int get workoutCount => _workouts.length;

  void setSelectedDate(DateTime date) {
    if (_selectedDate.year == date.year && 
        _selectedDate.month == date.month && 
        _selectedDate.day == date.day) {
      return;
    }
    
    _selectedDate = date;
    _workouts = [];
    loadWorkoutsForDate(date);
    loadDailyStats(date);
    notifyListeners();
  }

  // Load all data
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.wait([
        loadWorkoutTypes(),
        loadWorkoutsForDate(_selectedDate),
        loadDailyStats(_selectedDate),
        loadWeeklyStats(),
        loadIntensityDistribution(),
        loadWorkoutTypeStats(),
      ]);
    } catch (e) {
      debugPrint('Error loading all data: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load workout types
  Future<void> loadWorkoutTypes() async {
    final result = await WorkoutDetailService.getWorkoutTypes();
    
    if (result['success']) {
      _workoutTypes = result['types'];
    } else {
      _error = result['message'];
    }
    notifyListeners();
  }

  // Load workouts for specific date
  Future<void> loadWorkoutsForDate(DateTime date) async {
    _isLoadingWorkouts = true;
    notifyListeners();

    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final result = await WorkoutDetailService.getWorkouts(
      startDate: startDate,
      endDate: endDate,
    );

    _isLoadingWorkouts = false;
    if (result['success']) {
      _workouts = result['workouts'];
      _error = null;
    } else {
      _error = result['message'];
    }
    notifyListeners();
  }

  // Load daily stats
  Future<void> loadDailyStats(DateTime date) async {
    final result = await WorkoutDetailService.getDailyStats(date);
    
    if (result['success']) {
      _dailyStats = result['stats'];
    } else {
      // Don't set error for stats, just log
      debugPrint('Failed to load daily stats: ${result['message']}');
    }
    notifyListeners();
  }

  // Load weekly stats
  Future<void> loadWeeklyStats({DateTime? startDate}) async {
    final date = startDate ?? DateTime.now().subtract(const Duration(days: 6));
    final result = await WorkoutDetailService.getWeeklyStats(date);
    
    if (result['success']) {
      _weeklyStats = result['stats'];
    } else {
      debugPrint('Failed to load weekly stats: ${result['message']}');
      _weeklyStats = [];
    }
    notifyListeners();
  }

  // Load intensity distribution
  Future<void> loadIntensityDistribution({DateTime? startDate, DateTime? endDate}) async {
    final result = await WorkoutDetailService.getIntensityDistribution(
      startDate: startDate,
      endDate: endDate,
    );
    
    if (result['success']) {
      _intensityDistribution = result['distribution'];
    } else {
      debugPrint('Failed to load intensity distribution: ${result['message']}');
      _intensityDistribution = [];
    }
    notifyListeners();
  }

  // Load workout type stats
  Future<void> loadWorkoutTypeStats({DateTime? startDate, DateTime? endDate}) async {
    final result = await WorkoutDetailService.getWorkoutTypeStats(
      startDate: startDate,
      endDate: endDate,
    );
    
    if (result['success']) {
      _workoutTypeStats = result['stats'];
    } else {
      debugPrint('Failed to load workout type stats: ${result['message']}');
      _workoutTypeStats = [];
    }
    notifyListeners();
  }

  // Create custom workout type
  Future<Map<String, dynamic>> createWorkoutType(String name) async {
    _isLoading = true;
    notifyListeners();

    final result = await WorkoutDetailService.createWorkoutType(name);

    _isLoading = false;
    if (result['success']) {
      if (result['workout_type'] != null) {
        _workoutTypes.add(result['workout_type']);
      } else {
        await loadWorkoutTypes();
      }
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // Delete custom workout type
  Future<Map<String, dynamic>> deleteWorkoutType(int typeId) async {
    _isLoading = true;
    notifyListeners();

    final result = await WorkoutDetailService.deleteWorkoutType(typeId);

    _isLoading = false;
    if (result['success']) {
      _workoutTypes.removeWhere((t) => t.id == typeId);
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // Log a workout
  Future<Map<String, dynamic>> logWorkout(CreateWorkoutRequest request) async {
    _isLoading = true;
    notifyListeners();

    final result = await WorkoutDetailService.logWorkout(request);

    _isLoading = false;
    if (result['success']) {
      if (result['workout'] != null) {
        _workouts.insert(0, result['workout']);
      } else {
        await loadWorkoutsForDate(_selectedDate);
      }
      await loadDailyStats(_selectedDate);
      await loadWeeklyStats();
      await loadIntensityDistribution();
      await loadWorkoutTypeStats();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // Update workout
  Future<Map<String, dynamic>> updateWorkout(int id, UpdateWorkoutRequest request) async {
    _isLoading = true;
    notifyListeners();

    final result = await WorkoutDetailService.updateWorkout(id, request);

    _isLoading = false;
    if (result['success']) {
      await loadWorkoutsForDate(_selectedDate);
      await loadDailyStats(_selectedDate);
      await loadWeeklyStats();
      await loadIntensityDistribution();
      await loadWorkoutTypeStats();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // Delete workout
  Future<Map<String, dynamic>> deleteWorkout(int id) async {
    _isLoading = true;
    notifyListeners();

    final result = await WorkoutDetailService.deleteWorkout(id);

    _isLoading = false;
    if (result['success']) {
      _workouts.removeWhere((w) => w.id == id);
      await loadDailyStats(_selectedDate);
      await loadWeeklyStats();
      await loadIntensityDistribution();
      await loadWorkoutTypeStats();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // Get workout by ID
  Future<WorkoutDetail?> getWorkoutById(int id) async {
    final result = await WorkoutDetailService.getWorkoutById(id);
    return result['success'] ? result['workout'] : null;
  }

  // Refresh current date
  Future<void> refreshCurrentDate() async {
    await Future.wait([
      loadWorkoutsForDate(_selectedDate),
      loadDailyStats(_selectedDate),
    ]);
  }

  // Helper method to show messages
  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  // Clean up
  void disposeCallbacks() {
    onShowMessage = null;
  }

  // Get workouts for chart data - with safe empty handling
  List<double> getWeeklyDurationData() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final result = List<double>.filled(7, 0.0);
    
    // If no weekly stats data, return zeros
    if (_weeklyStats.isEmpty) {
      return result;
    }
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      try {
        final dayStats = _weeklyStats.firstWhere(
          (s) => s.date.year == date.year && s.date.month == date.month && s.date.day == date.day,
          orElse: () => WeeklyWorkoutStats(
            date: date,
            workoutCount: 0,
            totalDuration: 0,
            totalCalories: 0,
            totalDistance: 0,
          ),
        );
        result[i] = dayStats.totalDuration.toDouble();
      } catch (e) {
        debugPrint('Error getting weekly duration data at index $i: $e');
        result[i] = 0.0;
      }
    }
    return result;
  }

  List<double> getWeeklyCaloriesData() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final result = List<double>.filled(7, 0.0);
    
    // If no weekly stats data, return zeros
    if (_weeklyStats.isEmpty) {
      return result;
    }
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      try {
        final dayStats = _weeklyStats.firstWhere(
          (s) => s.date.year == date.year && s.date.month == date.month && s.date.day == date.day,
          orElse: () => WeeklyWorkoutStats(
            date: date,
            workoutCount: 0,
            totalDuration: 0,
            totalCalories: 0,
            totalDistance: 0,
          ),
        );
        result[i] = dayStats.totalCalories.toDouble();
      } catch (e) {
        debugPrint('Error getting weekly calories data at index $i: $e');
        result[i] = 0.0;
      }
    }
    return result;
  }

  // Get weekly workout count data (for charts)
  List<double> getWeeklyWorkoutCountData() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final result = List<double>.filled(7, 0.0);
    
    if (_weeklyStats.isEmpty) {
      return result;
    }
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      try {
        final dayStats = _weeklyStats.firstWhere(
          (s) => s.date.year == date.year && s.date.month == date.month && s.date.day == date.day,
          orElse: () => WeeklyWorkoutStats(
            date: date,
            workoutCount: 0,
            totalDuration: 0,
            totalCalories: 0,
            totalDistance: 0,
          ),
        );
        result[i] = dayStats.workoutCount.toDouble();
      } catch (e) {
        debugPrint('Error getting weekly workout count at index $i: $e');
        result[i] = 0.0;
      }
    }
    return result;
  }

  List<Map<String, dynamic>> getIntensityChartData() {
    if (_intensityDistribution.isEmpty) {
      return [];
    }
    return _intensityDistribution.map((d) {
      return {
        'label': d.intensity,
        'value': d.count.toDouble(),
        'color': _getIntensityColor(d.intensity),
      };
    }).toList();
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'very_high':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Reset all data (useful for logout)
  void reset() {
    _workoutTypes = [];
    _workouts = [];
    _dailyStats = null;
    _weeklyStats = [];
    _intensityDistribution = [];
    _workoutTypeStats = [];
    _isLoading = false;
    _isLoadingWorkouts = false;
    _error = null;
    _selectedDate = DateTime.now();
    notifyListeners();
  }
}