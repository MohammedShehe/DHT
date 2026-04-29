import 'package:flutter/material.dart';
import '../models/smart_reminder_model.dart';
import '../services/smart_reminder_service.dart';

class SmartReminderProvider extends ChangeNotifier {
  List<SmartReminder> _reminders = [];
  List<SmartReminder> _medicationReminders = [];
  bool _isLoading = false;
  bool _isLoadingMedications = false;
  String? _error;

  // Getters
  List<SmartReminder> get reminders => _reminders;
  List<SmartReminder> get medicationReminders => _medicationReminders;
  List<SmartReminder> get unreadReminders => _reminders.where((r) => !r.isRead).toList();
  List<SmartReminder> get unreadMedicationReminders => _medicationReminders.where((r) => !r.isRead).toList();
  List<SmartReminder> get highPriorityReminders => 
      _reminders.where((r) => r.priority == ReminderPriority.high || r.priority == ReminderPriority.critical).toList();
  bool get isLoading => _isLoading;
  bool get isLoadingMedications => _isLoadingMedications;
  String? get error => _error;
  int get unreadCount => _reminders.where((r) => !r.isRead).length;
  int get unreadMedicationCount => _medicationReminders.where((r) => !r.isRead).length;
  bool get hasCriticalMedicationReminders => 
      _medicationReminders.where((r) => r.priority == ReminderPriority.critical && !r.isRead).isNotEmpty;

  // Service instance
  final SmartReminderService _service = SmartReminderService();

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  SmartReminderProvider() {
    loadReminders();
    loadMedicationReminders();
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
        _medicationReminders = _service.getMedicationReminders();
        _isLoading = false;
        notifyListeners();
        
        // Generate new in background
        _generateRemindersInBackground();
      } else {
        // Generate new reminders
        final newReminders = await _service.generateReminders();
        _reminders = newReminders;
        _medicationReminders = _service.getMedicationReminders();
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

  // Load medication reminders specifically (can be called more frequently)
  Future<void> loadMedicationReminders({bool forceRefresh = false}) async {
    if (!forceRefresh && _medicationReminders.isNotEmpty && _medicationReminders.length < 10) {
      return;
    }

    _isLoadingMedications = true;
    notifyListeners();

    try {
      final newMedicationReminders = await _service.generateMedicationReminders();
      _medicationReminders = newMedicationReminders;
      
      // Update main reminders list as well
      final nonMedicationReminders = _reminders
          .where((r) => r.category != ReminderCategory.medication)
          .toList();
      _reminders = [...nonMedicationReminders, ..._medicationReminders];
      _reminders.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      
      _isLoadingMedications = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingMedications = false;
      notifyListeners();
      debugPrint('Error loading medication reminders: $e');
    }
  }

  // Generate reminders in background
  Future<void> _generateRemindersInBackground() async {
    final newReminders = await _service.generateReminders();
    if (newReminders.isNotEmpty) {
      _reminders = newReminders;
      _medicationReminders = _service.getMedicationReminders();
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
    
    // Check medication list too
    final medIndex = _medicationReminders.indexWhere((r) => r.id == id);
    if (medIndex >= 0) {
      _medicationReminders[medIndex] = _reminders[index];
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

  // Mark all medication reminders as read
  void markAllMedicationRemindersAsRead() {
    for (int i = 0; i < _medicationReminders.length; i++) {
      if (!_medicationReminders[i].isRead) {
        _service.markAsRead(_medicationReminders[i].id);
        _medicationReminders[i] = SmartReminder(
          id: _medicationReminders[i].id,
          title: _medicationReminders[i].title,
          message: _medicationReminders[i].message,
          category: _medicationReminders[i].category,
          priority: _medicationReminders[i].priority,
          timestamp: _medicationReminders[i].timestamp,
          isRead: true,
          actionData: _medicationReminders[i].actionData,
          actionType: _medicationReminders[i].actionType,
          expiresAt: _medicationReminders[i].expiresAt,
          pointsReward: _medicationReminders[i].pointsReward,
        );
      }
    }
    notifyListeners();
  }

  // Clear all reminders
  void clearReminders() {
    _service.clearReminders();
    _reminders.clear();
    _medicationReminders.clear();
    notifyListeners();
  }

  // Clear medication reminders only
  void clearMedicationReminders() {
    _service.clearMedicationReminders();
    _medicationReminders.clear();
    _reminders = _reminders
        .where((r) => r.category != ReminderCategory.medication)
        .toList();
    notifyListeners();
  }

  // Remove a specific reminder
  void removeReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    _medicationReminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Get reminders by category
  List<SmartReminder> getRemindersByCategory(ReminderCategory category) {
    return _reminders.where((r) => r.category == category).toList();
  }

  // Get medication reminders by priority
  List<SmartReminder> getMedicationRemindersByPriority(ReminderPriority priority) {
    return _medicationReminders.where((r) => r.priority == priority && !r.isRead).toList();
  }

  // Execute reminder action
  void executeAction(SmartReminder reminder, BuildContext context) {
    markAsRead(reminder.id);

    if (reminder.actionData == null) return;

    final screen = reminder.actionData!['screen'];
    final tab = reminder.actionData!['tab'];

    switch (screen) {
      case 'activity':
        _navigateToActivityTab(context, tab);
        break;
      case 'gamification':
        _navigateToGamificationTab(context, tab);
        break;
      case 'profile':
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
    debugPrint('Navigate to activity tab: $tab');
    // In a real implementation, you would use a navigation key or global state
    // to change the bottom navigation bar index
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

  // Refresh all data
  Future<void> refreshAll() async {
    await loadReminders(forceRefresh: true);
    await loadMedicationReminders(forceRefresh: true);
  }
}