import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_models.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardSummary? _summary;
  List<ActivitySummary> _recentActivities = [];
  List<HealthTip> _healthTips = [];
  Map<String, dynamic>? _weeklySummary;
  bool _isLoading = false;
  String? _error;

  // Getters
  DashboardSummary? get summary => _summary;
  List<ActivitySummary> get recentActivities => _recentActivities;
  List<HealthTip> get healthTips => _healthTips;
  Map<String, dynamic>? get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  DashboardProvider() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all dashboard data in parallel
      final results = await Future.wait([
        DashboardService.getDashboardSummary(),
        DashboardService.getRecentActivities(),
        DashboardService.getHealthTips(),
        DashboardService.getWeeklySummary(),
      ], eagerError: false);

      // Process summary
      if (results[0]['success']) {
        _summary = results[0]['data'];
      } else {
        _error = results[0]['message'];
      }

      // Process recent activities
      if (results[1]['success']) {
        _recentActivities = results[1]['data'] ?? [];
      }

      // Process health tips
      if (results[2]['success']) {
        _healthTips = results[2]['data'] ?? [];
      }

      // Process weekly summary
      if (results[3]['success']) {
        _weeklySummary = results[3]['data'];
      }

    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh specific parts of dashboard
  Future<void> refreshSummary() async {
    final result = await DashboardService.getDashboardSummary();
    if (result['success']) {
      _summary = result['data'];
      notifyListeners();
    }
  }

  Future<void> refreshActivities() async {
    final result = await DashboardService.getRecentActivities();
    if (result['success']) {
      _recentActivities = result['data'] ?? [];
      notifyListeners();
    }
  }

  Future<void> refreshWeeklySummary() async {
    final result = await DashboardService.getWeeklySummary();
    if (result['success']) {
      _weeklySummary = result['data'];
      notifyListeners();
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }
}