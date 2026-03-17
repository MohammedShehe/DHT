import 'package:flutter/material.dart';
import '../services/google_fit_service.dart';
import '../models/google_fit_models.dart';
import '../models/activity_models.dart';
import 'activity_provider.dart';

class GoogleFitProvider extends ChangeNotifier {
  final GoogleFitService _fitService = GoogleFitService();
  
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isSyncing = false;
  String? _error;
  String? _connectedAccount;
  
  DailyFitnessSummary? _todaySummary;
  List<DailyFitnessSummary> _weeklySummaries = [];
  List<FitnessActivity> _todayActivities = [];
  List<FitnessDataPoint> _heartRateData = [];
  SleepSession? _lastNightSleep;
  
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get connectedAccount => _connectedAccount;
  DailyFitnessSummary? get todaySummary => _todaySummary;
  List<DailyFitnessSummary> get weeklySummaries => _weeklySummaries;
  List<FitnessActivity> get todayActivities => _todayActivities;
  List<FitnessDataPoint> get heartRateData => _heartRateData;
  SleepSession? get lastNightSleep => _lastNightSleep;
  
  Function(String message, {bool isError})? onShowMessage;

  // Remove initialize method - GoogleFitService doesn't need initialization
  // Just check if available

  Future<bool> connect() async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      final available = await _fitService.isAvailable();
      if (!available) {
        _error = 'Google Fit is not available on this device';
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      final connected = await _fitService.connect();
      
      if (connected) {
        _isConnected = true;
        _connectedAccount = 'Connected to Google Fit';
        await loadTodayData();
        _showMessage('Connected to Google Fit successfully');
      } else {
        _error = 'Failed to connect to Google Fit';
      }
      
      _isConnecting = false;
      notifyListeners();
      
      return connected;
    } catch (e) {
      _error = e.toString();
      _isConnecting = false;
      notifyListeners();
      _showMessage('Error connecting to Google Fit', isError: true);
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _fitService.disconnect();
      _isConnected = false;
      _connectedAccount = null;
      _todaySummary = null;
      _weeklySummaries = [];
      _todayActivities = [];
      _heartRateData = [];
      _lastNightSleep = null;
      notifyListeners();
      _showMessage('Disconnected from Google Fit');
    } catch (e) {
      _showMessage('Error disconnecting', isError: true);
    }
  }

  Future<void> loadTodayData() async {
    if (!_isConnected) {
      final connected = await _fitService.silentConnect();
      if (!connected) {
        _showMessage('Please connect to Google Fit first', isError: true);
        return;
      }
      _isConnected = true;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      _todaySummary = await _fitService.getDailySummary(today);
      _todayActivities = await _fitService.getTodayActivities();
      _heartRateData = await _fitService.getHeartRate(today);
      
      final sleepData = await _fitService.getSleep(today);
      if (sleepData.isNotEmpty) {
        _lastNightSleep = sleepData.first;
      }
      
      notifyListeners();
    } catch (e) {
      _showMessage('Error loading Google Fit data', isError: true);
    }
  }

  Future<void> loadWeeklySummary() async {
    if (!_isConnected) return;

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      _weeklySummaries = await _fitService.getWeeklySummary(startOfWeek);
      notifyListeners();
    } catch (e) {}
  }

  Future<Map<String, dynamic>> syncToActivityProvider(
    ActivityProvider activityProvider, {
    DateTime? date,
  }) async {
    if (!_isConnected) {
      return {'success': false, 'message': 'Not connected to Google Fit'};
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final targetDate = date ?? DateTime.now();
      
      final steps = await _fitService.getTotalSteps(targetDate);
      final workouts = await _fitService.syncActivitiesToWorkouts(targetDate);
      
      for (var workout in workouts) {
        await activityProvider.addWorkout(workout);
      }
      
      _isSyncing = false;
      notifyListeners();
      
      return {
        'success': true,
        'message': 'Synced ${workouts.length} activities',
        'steps': steps,
        'activities': workouts.length,
      };
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return {'success': false, 'message': 'Sync failed'};
    }
  }

  List<Map<String, dynamic>> getHeartRateChartData() {
    return _heartRateData.map((point) {
      return {
        'time': point.startTime.hour,
        'value': point.value,
      };
    }).toList();
  }

  Map<String, int> getActivityBreakdown() {
    Map<String, int> breakdown = {};
    for (var activity in _todayActivities) {
      breakdown[activity.name] = (breakdown[activity.name] ?? 0) + 1;
    }
    return breakdown;
  }

  double getTodayActiveMinutes() {
    return _todayActivities.fold(
      0, (sum, activity) => sum + activity.duration,
    );
  }

  bool get hasData {
    return _todaySummary != null ||
           _todayActivities.isNotEmpty ||
           _heartRateData.isNotEmpty;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }
}