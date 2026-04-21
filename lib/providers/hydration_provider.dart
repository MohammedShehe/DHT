import 'package:flutter/material.dart';
import '../models/hydration_models.dart';
import '../services/hydration_service.dart';

class HydrationProvider extends ChangeNotifier {
  // State variables
  List<HydrationLog> _logs = [];
  List<DrinkType> _drinkTypes = [];
  List<PresetAmount> _presetAmounts = [];
  HydrationGoal? _goal;
  DailyHydrationStats? _dailyStats;
  List<WeeklyHydrationStats> _weeklyStats = [];
  List<DrinkTypeDistribution> _drinkTypeDistribution = [];
  List<HydrationTrend> _trends = [];
  
  bool _isLoading = false;
  bool _isLoadingLogs = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  
  int _weeklyTotalMl = 0;
  int _weeklyAverageMl = 0;
  int _weeklyAchievement = 0;

  Function(String message, {bool isError})? onShowMessage;

  // Getters
  List<HydrationLog> get logs => _logs;
  List<DrinkType> get drinkTypes => _drinkTypes;
  List<PresetAmount> get presetAmounts => _presetAmounts;
  HydrationGoal? get goal => _goal;
  DailyHydrationStats? get dailyStats => _dailyStats;
  List<WeeklyHydrationStats> get weeklyStats => _weeklyStats;
  List<DrinkTypeDistribution> get drinkTypeDistribution => _drinkTypeDistribution;
  List<HydrationTrend> get trends => _trends;
  bool get isLoading => _isLoading;
  bool get isLoadingLogs => _isLoadingLogs;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  
  int get weeklyTotalMl => _weeklyTotalMl;
  int get weeklyAverageMl => _weeklyAverageMl;
  int get weeklyAchievement => _weeklyAchievement;

  int get todayTotalMl => _dailyStats?.totalMl ?? 0;
  int get todayGoal => _dailyStats?.dailyTargetMl ?? _goal?.dailyTargetMl ?? 2500;
  
  double get todayPercentage {
    final percentage = _dailyStats?.percentage ?? 0;
    return percentage.toDouble();
  }
  
  int get todayRemaining => _dailyStats?.remainingMl ?? (todayGoal - todayTotalMl).clamp(0, todayGoal);
  bool get todayCompleted => _dailyStats?.completed ?? false;

  Future<void> initialize() async {
    await loadInitialData();
    await loadLogsForDate(_selectedDate);
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadDrinkTypes(),
        loadPresetAmounts(),
        loadGoal(),
        loadDailyStats(_selectedDate),
        loadWeeklyStats(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_selectedDate.year == normalizedDate.year &&
        _selectedDate.month == normalizedDate.month &&
        _selectedDate.day == normalizedDate.day) {
      return;
    }
    _selectedDate = normalizedDate;
    loadLogsForDate(normalizedDate);
    loadDailyStats(normalizedDate);
    notifyListeners();
  }

  Future<void> loadDrinkTypes() async {
    final result = await HydrationService.getDrinkTypes();
    if (result['success']) {
      _drinkTypes = result['drink_types'];
      notifyListeners();
    }
  }

  Future<void> loadPresetAmounts() async {
    final result = await HydrationService.getPresetAmounts();
    if (result['success']) {
      _presetAmounts = result['preset_amounts'];
      notifyListeners();
    }
  }

  // ===== GOAL MANAGEMENT =====

  Future<void> loadGoal() async {
    final result = await HydrationService.getGoal();
    if (result['success']) {
      _goal = result['goal'];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> setGoal(int dailyTargetMl) async {
    _isLoading = true;
    notifyListeners();

    final result = await HydrationService.setGoal(dailyTargetMl);
    
    _isLoading = false;
    if (result['success']) {
      await loadGoal();
      await loadDailyStats(_selectedDate);
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteGoal() async {
    _isLoading = true;
    notifyListeners();

    final result = await HydrationService.deleteGoal();
    
    _isLoading = false;
    if (result['success']) {
      _goal = null;
      await loadDailyStats(_selectedDate);
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // ===== HYDRATION LOGGING =====

  Future<Map<String, dynamic>> logHydration({
    required int amountMl,
    required String drinkType,
    String? customDrinkName,
    required TimeOfDay consumptionTime,
    required DateTime logDate,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await HydrationService.logHydration(
      amountMl: amountMl,
      drinkType: drinkType,
      customDrinkName: customDrinkName,
      consumptionTime: consumptionTime,
      logDate: logDate,
      notes: notes,
    );

    _isLoading = false;
    if (result['success']) {
      await loadLogsForDate(logDate);
      if (logDate.year == _selectedDate.year &&
          logDate.month == _selectedDate.month &&
          logDate.day == _selectedDate.day) {
        await loadDailyStats(logDate);
      }
      await loadWeeklyStats();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<void> loadLogsForDate(DateTime date) async {
    _isLoadingLogs = true;
    notifyListeners();

    final result = await HydrationService.getHydrationLogsByDate(date);
    
    _isLoadingLogs = false;
    if (result['success']) {
      _logs = result['logs'];
      _logs.sort((a, b) => a.consumptionTime.hour.compareTo(b.consumptionTime.hour));
    } else {
      _error = result['message'];
      _logs = [];
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateHydrationLog({
    required int id,
    int? amountMl,
    String? drinkType,
    String? customDrinkName,
    TimeOfDay? consumptionTime,
    DateTime? logDate,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    print('🟡 Updating log in provider: id=$id, amount=$amountMl');

    final result = await HydrationService.updateHydrationLog(
      id: id,
      amountMl: amountMl,
      drinkType: drinkType,
      customDrinkName: customDrinkName,
      consumptionTime: consumptionTime,
      logDate: logDate,
      notes: notes,
    );

    _isLoading = false;
    if (result['success']) {
      await loadLogsForDate(logDate ?? _selectedDate);
      await loadDailyStats(logDate ?? _selectedDate);
      await loadWeeklyStats();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteHydrationLog(int id) async {
    _isLoading = true;
    notifyListeners();

    print('🟡 Deleting log in provider: id=$id');

    final result = await HydrationService.deleteHydrationLog(id);
    
    _isLoading = false;
    if (result['success']) {
      await loadLogsForDate(_selectedDate);
      await loadDailyStats(_selectedDate);
      await loadWeeklyStats();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    notifyListeners();
    return result;
  }

  // ===== STATISTICS & ANALYTICS =====

  Future<void> loadDailyStats(DateTime date) async {
    final result = await HydrationService.getDailyStats(date);
    if (result['success']) {
      _dailyStats = result['stats'];
      notifyListeners();
    }
  }

  Future<void> loadWeeklyStats({DateTime? startDate}) async {
    final start = startDate ?? _getStartOfWeek(DateTime.now());
    final result = await HydrationService.getWeeklyStats(start);
    
    if (result['success']) {
      _weeklyStats = result['stats'];
      _weeklyTotalMl = result['weekly_total_ml'] ?? 0;
      _weeklyAverageMl = result['weekly_average_ml'] ?? 0;
      _weeklyAchievement = result['weekly_achievement'] ?? 0;
      notifyListeners();
    }
  }

  Future<void> loadDrinkTypeDistribution({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await HydrationService.getDrinkTypeDistribution(
      startDate: startDate,
      endDate: endDate,
    );
    
    if (result['success']) {
      _drinkTypeDistribution = result['distribution'];
      notifyListeners();
    }
  }

  Future<void> loadTrends({int weeks = 12}) async {
    final result = await HydrationService.getTrends(weeks: weeks);
    
    if (result['success']) {
      _trends = result['trends'];
      notifyListeners();
    }
  }

  // ===== HELPER METHODS =====

  DateTime _getStartOfWeek(DateTime date) {
    final startOfWeek = DateTime(date.year, date.month, date.day);
    return startOfWeek.subtract(Duration(days: startOfWeek.weekday - 1));
  }

  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }

  List<Map<String, dynamic>> getWeeklyChartData() {
    return _weeklyStats.map((stat) {
      return {
        'day': stat.dayName,
        'total_ml': stat.totalMl,
        'target': stat.dailyTarget,
        'percentage': stat.percentage,
      };
    }).toList();
  }

  List<double> getWeeklyHydrationData() {
    return _weeklyStats.map((stat) => stat.totalMl.toDouble()).toList();
  }

  List<String> getWeekLabels() {
    return _weeklyStats.map((stat) => stat.dayName).toList();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadInitialData(),
      loadLogsForDate(_selectedDate),
    ]);
  }

  void reset() {
    _logs = [];
    _drinkTypes = [];
    _presetAmounts = [];
    _goal = null;
    _dailyStats = null;
    _weeklyStats = [];
    _drinkTypeDistribution = [];
    _trends = [];
    _isLoading = false;
    _isLoadingLogs = false;
    _error = null;
    _selectedDate = DateTime.now();
    notifyListeners();
  }
}