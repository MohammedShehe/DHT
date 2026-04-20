import 'package:flutter/material.dart';
import '../models/sleep_activity_models.dart';
import '../services/sleep_activity_service.dart';

class SleepActivityProvider extends ChangeNotifier {
  SleepLog? _currentSleepLog;
  List<SleepLog> _sleepLogs = [];
  List<WeeklySleepStat> _weeklyStats = [];
  List<SleepQualityType> _qualityTypes = [];
  SleepSummary? _summary;
  SleepComparison? _comparison;
  SleepConsistency? _consistency;
  List<SleepTrend> _trends = [];
  Map<String, dynamic>? _chartData;
  
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  // Getters
  SleepLog? get currentSleepLog => _currentSleepLog;
  List<SleepLog> get sleepLogs => _sleepLogs;
  List<WeeklySleepStat> get weeklyStats => _weeklyStats;
  List<SleepQualityType> get qualityTypes => _qualityTypes;
  SleepSummary? get summary => _summary;
  SleepComparison? get comparison => _comparison;
  SleepConsistency? get consistency => _consistency;
  List<SleepTrend> get trends => _trends;
  Map<String, dynamic>? get chartData => _chartData;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    if (_selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day) {
      return;
    }
    _selectedDate = date;
    loadSleepLogForDate(date);
    notifyListeners();
  }

  // Load sleep log for a specific date
  Future<void> loadSleepLogForDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await SleepActivityService.getSleepLog(date);
      
      if (result['success']) {
        _currentSleepLog = result['sleep_log'];
        _error = null;
      } else {
        _currentSleepLog = null;
        if (result['message'] != 'No sleep log found') {
          _error = result['message'];
        }
      }
    } catch (e) {
      _error = e.toString();
      _currentSleepLog = null;
      debugPrint('Error loading sleep log: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Log sleep (create or update)
  Future<Map<String, dynamic>> logSleep({
    required DateTime sleepDate,
    required TimeOfDay bedtime,
    required TimeOfDay wakeTime,
    required int interruptions,
    required String sleepQuality,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final bedtimeStr = '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}:00';
    final wakeTimeStr = '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}:00';

    final result = await SleepActivityService.logSleep(
      sleepDate: sleepDate,
      bedtime: bedtimeStr,
      wakeTime: wakeTimeStr,
      interruptions: interruptions,
      sleepQuality: sleepQuality,
      notes: notes,
    );

    _isLoading = false;
    
    if (result['success']) {
      // Refresh the log for the selected date
      await loadSleepLogForDate(sleepDate);
      await loadWeeklyStats();
      await loadChartData();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    
    notifyListeners();
    return result;
  }

  // Delete sleep log for current selected date
  Future<Map<String, dynamic>> deleteCurrentSleepLog() async {
    _isLoading = true;
    notifyListeners();

    final result = await SleepActivityService.deleteSleepLog(_selectedDate);

    _isLoading = false;
    
    if (result['success']) {
      _currentSleepLog = null;
      await loadWeeklyStats();
      await loadChartData();
      _showMessage(result['message']);
    } else {
      _error = result['message'];
      _showMessage(result['message'], isError: true);
    }
    
    notifyListeners();
    return result;
  }

  // Load sleep logs for date range
  Future<void> loadSleepLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    int? offset,
  }) async {
    _isLoadingHistory = true;
    notifyListeners();

    final result = await SleepActivityService.getSleepLogsByDateRange(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );

    _isLoadingHistory = false;
    
    if (result['success']) {
      _sleepLogs = result['logs'];
    } else {
      _error = result['message'];
    }
    
    notifyListeners();
  }

  // Load weekly stats
  Future<void> loadWeeklyStats({DateTime? startDate, DateTime? endDate}) async {
    final start = startDate ?? _getStartOfWeek(_selectedDate);
    final end = endDate ?? _getEndOfWeek(_selectedDate);

    final result = await SleepActivityService.getWeeklyStatsByDay(
      startDate: start,
      endDate: end,
    );

    if (result['success']) {
      _weeklyStats = result['stats'];
    } else {
      _weeklyStats = [];
      debugPrint('Error loading weekly stats: ${result['message']}');
    }
    notifyListeners();
  }

  // Load chart data
  Future<void> loadChartData({int days = 30}) async {
    final result = await SleepActivityService.getDailyChartData(days: days);

    if (result['success']) {
      _chartData = result['chart_data'];
    } else {
      _chartData = null;
      debugPrint('Error loading chart data: ${result['message']}');
    }
    notifyListeners();
  }

  // Load summary stats
  Future<void> loadSummary({String period = 'month'}) async {
    final result = await SleepActivityService.getSummaryStats(period: period);

    if (result['success'] && result['summary'] != null) {
      _summary = SleepSummary.fromJson(result['summary']);
    } else {
      _summary = null;
    }
    notifyListeners();
  }

  // Load weekly comparison
  Future<void> loadWeeklyComparison() async {
    final result = await SleepActivityService.getWeeklyComparison();

    if (result['success'] && result['comparison'] != null) {
      _comparison = SleepComparison.fromJson(result['comparison']);
    } else {
      _comparison = null;
    }
    notifyListeners();
  }

  // Load consistency
  Future<void> loadConsistency({int days = 30}) async {
    final result = await SleepActivityService.getConsistency(days: days);

    if (result['success'] && result['consistency'] != null) {
      _consistency = SleepConsistency.fromJson(result['consistency']);
    } else {
      _consistency = null;
    }
    notifyListeners();
  }

  // Load trends
  Future<void> loadTrends({int weeks = 12}) async {
    final result = await SleepActivityService.getTrendData(weeks: weeks);

    if (result['success']) {
      _trends = (result['trends'] as List)
          .map((t) => SleepTrend.fromJson(t))
          .toList();
    } else {
      _trends = [];
    }
    notifyListeners();
  }

  // Load quality types
  Future<void> loadQualityTypes() async {
    final result = await SleepActivityService.getQualityTypes();

    if (result['success']) {
      _qualityTypes = (result['quality_types'] as List)
          .map((q) => SleepQualityType.fromJson(q))
          .toList();
    } else {
      _qualityTypes = [];
    }
    notifyListeners();
  }

  // Load all stats
  Future<void> loadAllStats() async {
    await Future.wait([
      loadWeeklyStats(),
      loadChartData(),
      loadSummary(),
      loadWeeklyComparison(),
      loadConsistency(),
      loadTrends(),
    ]);
  }

  // Helper methods
  DateTime _getStartOfWeek(DateTime date) {
    final startOfWeek = DateTime(date.year, date.month, date.day);
    return startOfWeek.subtract(Duration(days: startOfWeek.weekday - 1));
  }

  DateTime _getEndOfWeek(DateTime date) {
    final startOfWeek = _getStartOfWeek(date);
    return startOfWeek.add(const Duration(days: 6));
  }

  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }

  // Get chart data for display
  List<Map<String, dynamic>> getChartDataForDisplay() {
    if (_chartData == null) return [];
    
    final labels = _chartData!['labels'] as List? ?? [];
    final hoursData = _chartData!['datasets']?['hours'] as List? ?? [];
    final interruptionsData = _chartData!['datasets']?['interruptions'] as List? ?? [];
    
    return List.generate(labels.length, (index) {
      return {
        'date': labels[index],
        'hours': hoursData.length > index ? hoursData[index] : 0.0,
        'interruptions': interruptionsData.length > index ? interruptionsData[index] : 0,
      };
    });
  }

  // Get weekly duration data for bar chart
  List<double> getWeeklyDurationData() {
    if (_weeklyStats.isEmpty) return List.filled(7, 0.0);
    
    final result = List.filled(7, 0.0);
    for (var stat in _weeklyStats) {
      // Convert dayOfWeek (1=Sunday, 2=Monday, etc.) to 0-based index (Monday first)
      int index = stat.dayOfWeek - 2;
      if (index < 0) index = 6; // Sunday becomes last
      if (index >= 0 && index < 7) {
        result[index] = stat.avgHours;
      }
    }
    return result;
  }

  // Get weekly interruption data for bar chart
  List<double> getWeeklyInterruptionData() {
    if (_weeklyStats.isEmpty) return List.filled(7, 0.0);
    
    final result = List.filled(7, 0.0);
    for (var stat in _weeklyStats) {
      int index = stat.dayOfWeek - 2;
      if (index < 0) index = 6;
      if (index >= 0 && index < 7) {
        result[index] = stat.avgInterruptions;
      }
    }
    return result;
  }

  // Get week labels (Monday to Sunday)
  List<String> getWeekLabels() {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }
}