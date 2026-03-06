import 'package:flutter/material.dart';
import '../models/smart_reminder_model.dart';
import '../services/smart_reminder_service.dart';

class SmartReminderProvider extends ChangeNotifier {
  List<SmartReminder> _reminders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SmartReminder> get reminders => _reminders;
  List<SmartReminder> get unreadReminders => _reminders.where((r) => !r.isRead).toList();
  List<SmartReminder> get highPriorityReminders => 
      _reminders.where((r) => r.priority == ReminderPriority.high || r.priority == ReminderPriority.critical).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _reminders.where((r) => !r.isRead).length;

  // Service instance
  final SmartReminderService _service = SmartReminderService();

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  SmartReminderProvider() {
    loadReminders();
  }

  // Load reminders (use cached first, then generate in background)
  Future<void> loadReminders({bool forceRefresh = false}) async {
    if (!forceRefresh && _reminders.isNotEmpty) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // First, get cached reminders
      final cached = _service.getCachedReminders();
      if (cached.isNotEmpty && !forceRefresh) {
        _reminders = cached;
        _isLoading = false;
        notifyListeners();
        
        // Generate new in background
        _generateRemindersInBackground();
      } else {
        // Generate new reminders
        final newReminders = await _service.generateReminders();
        _reminders = newReminders;
        _error = null;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading reminders: $e');
    }
  }

  // Generate reminders in background
  Future<void> _generateRemindersInBackground() async {
    final newReminders = await _service.generateReminders();
    if (newReminders.isNotEmpty) {
      _reminders = newReminders;
      notifyListeners();
    }
  }

  // Mark reminder as read
  void markAsRead(String id) {
    _service.markAsRead(id);
    
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _reminders[index] = SmartReminder(
        id: _reminders[index].id,
        title: _reminders[index].title,
        message: _reminders[index].message,
        category: _reminders[index].category,
        priority: _reminders[index].priority,
        timestamp: _reminders[index].timestamp,
        isRead: true,
        actionData: _reminders[index].actionData,
        actionType: _reminders[index].actionType,
        expiresAt: _reminders[index].expiresAt,
        pointsReward: _reminders[index].pointsReward,
      );
      notifyListeners();
    }
  }

  // Mark all as read
  void markAllAsRead() {
    for (int i = 0; i < _reminders.length; i++) {
      if (!_reminders[i].isRead) {
        _service.markAsRead(_reminders[i].id);
        _reminders[i] = SmartReminder(
          id: _reminders[i].id,
          title: _reminders[i].title,
          message: _reminders[i].message,
          category: _reminders[i].category,
          priority: _reminders[i].priority,
          timestamp: _reminders[i].timestamp,
          isRead: true,
          actionData: _reminders[i].actionData,
          actionType: _reminders[i].actionType,
          expiresAt: _reminders[i].expiresAt,
          pointsReward: _reminders[i].pointsReward,
        );
      }
    }
    notifyListeners();
  }

  // Clear all reminders
  void clearReminders() {
    _service.clearReminders();
    _reminders.clear();
    notifyListeners();
  }

  // Remove a specific reminder
  void removeReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Get reminders by category
  List<SmartReminder> getRemindersByCategory(ReminderCategory category) {
    return _reminders.where((r) => r.category == category).toList();
  }

  // Execute reminder action
  void executeAction(SmartReminder reminder, BuildContext context) {
    markAsRead(reminder.id);

    if (reminder.actionData == null) return;

    final screen = reminder.actionData!['screen'];
    final tab = reminder.actionData!['tab'];

    switch (screen) {
      case 'activity':
        // Navigate to activity tab with specific tab
        _navigateToActivityTab(context, tab);
        break;
      case 'gamification':
        // Navigate to gamification tab with specific tab
        _navigateToGamificationTab(context, tab);
        break;
      case 'profile':
        // Navigate to profile
        _navigateToProfile(context);
        break;
    }

    // Show points earned if applicable
    if (reminder.pointsReward != null && reminder.pointsReward! > 0) {
      if (onShowMessage != null) {
        onShowMessage!('+${reminder.pointsReward} points earned!');
      }
    }
  }

  void _navigateToActivityTab(BuildContext context, dynamic tab) {
    // This would need to be implemented based on your navigation structure
    // For now, we'll just show a message
    debugPrint('Navigate to activity tab: $tab');
  }

  void _navigateToGamificationTab(BuildContext context, dynamic tab) {
    debugPrint('Navigate to gamification tab: $tab');
  }

  void _navigateToProfile(BuildContext context) {
    debugPrint('Navigate to profile');
  }

  // Dispose callbacks
  void disposeCallbacks() {
    onShowMessage = null;
  }
}