import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationPreference> _preferences = [];
  List<FCMToken> _tokens = [];
  List<NotificationHistory> _history = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationPreference> get preferences => _preferences;
  List<NotificationPreference> get enabledPreferences => 
      _preferences.where((p) => p.isEnabled).toList();
  List<FCMToken> get tokens => _tokens;
  List<NotificationHistory> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Callback for showing messages
  Function(String message, {bool isError})? onShowMessage;

  NotificationProvider() {
    _initialize();
  }

  // Initialize provider
  Future<void> _initialize() async {
    await Future.wait([
      loadPreferences(),
      loadTokens(),
      loadHistory(),
    ]);
  }

  // ===== NOTIFICATION PREFERENCES =====

  // Load all notification preferences
  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await NotificationService.getPreferences();
      
      if (result['success']) {
        _preferences = result['preferences'] ?? [];
      } else {
        _error = result['message'];
        _showMessage('Error loading notifications: ${result['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error loading notifications: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new notification preference
  Future<void> createPreference(NotificationPreference preference) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await NotificationService.savePreference(preference);
      
      if (result['success']) {
        if (result['preference'] != null) {
          _preferences.add(result['preference']);
        } else {
          await loadPreferences(); // Refresh if no preference returned
        }
        _showMessage(result['message'] ?? 'Notification created successfully');
      } else {
        _error = result['message'];
        _showMessage('Error creating notification: ${result['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error creating notification: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing notification preference
  Future<void> updatePreference(NotificationPreference preference) async {
    if (preference.id == null) {
      _showMessage('Cannot update notification without ID', isError: true);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await NotificationService.savePreference(preference);
      
      if (result['success']) {
        final index = _preferences.indexWhere((p) => p.id == preference.id);
        if (index >= 0) {
          _preferences[index] = result['preference'] ?? preference;
        }
        _showMessage(result['message'] ?? 'Notification updated successfully');
      } else {
        _error = result['message'];
        _showMessage('Error updating notification: ${result['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error updating notification: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle notification enabled/disabled
  Future<void> togglePreference(int id, bool isEnabled) async {
    try {
      final result = await NotificationService.togglePreference(id, isEnabled);
      
      if (result['success']) {
        final index = _preferences.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _preferences[index] = NotificationPreference(
            id: _preferences[index].id,
            notificationType: _preferences[index].notificationType,
            isEnabled: result['is_enabled'] ?? isEnabled,
            title: _preferences[index].title,
            message: _preferences[index].message,
            time: _preferences[index].time,
            repeatDays: _preferences[index].repeatDays,
            actionType: _preferences[index].actionType,
            actionData: _preferences[index].actionData,
            isPredefined: _preferences[index].isPredefined,
            createdAt: _preferences[index].createdAt,
            updatedAt: _preferences[index].updatedAt,
          );
          notifyListeners();
        }
        _showMessage(result['message'] ?? 'Notification ${isEnabled ? 'enabled' : 'disabled'}');
      } else {
        _showMessage('Error toggling notification: ${result['message']}', isError: true);
      }
    } catch (e) {
      _showMessage('Error toggling notification: $e', isError: true);
    }
  }

  // Delete notification preference
  Future<void> deletePreference(int id) async {
    try {
      final result = await NotificationService.deletePreference(id);
      
      if (result['success']) {
        _preferences.removeWhere((p) => p.id == id);
        _showMessage(result['message'] ?? 'Notification deleted successfully');
        notifyListeners();
      } else {
        _showMessage('Error deleting notification: ${result['message']}', isError: true);
      }
    } catch (e) {
      _showMessage('Error deleting notification: $e', isError: true);
    }
  }

  // Reset to default notifications
  Future<void> resetToDefaults() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await NotificationService.resetToDefaults();
      
      if (result['success']) {
        await loadPreferences(); // Reload all preferences
        _showMessage(result['message'] ?? 'Notifications reset to defaults');
      } else {
        _error = result['message'];
        _showMessage('Error resetting notifications: ${result['message']}', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error resetting notifications: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== FCM TOKEN MANAGEMENT =====

  // Register device token after login
  Future<void> registerDeviceTokenAfterLogin() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      
      if (token == null) {
        debugPrint('❌ Failed to get FCM token');
        return;
      }
      
      debugPrint('📱 Registering token with backend: $token');
      
      // Get device info
      String deviceType = _getDeviceType();
      String deviceName = _getDeviceName();
      
      final result = await NotificationService.registerToken(
        fcmToken: token,
        deviceType: deviceType,
        deviceName: deviceName,
      );
      
      if (result['success']) {
        debugPrint('✅ Token registered with backend');
        await loadTokens();
      } else {
        debugPrint('❌ Backend registration failed: ${result['message']}');
        _showMessage('Failed to register device: ${result['message']}', isError: true);
      }
    } catch (e) {
      debugPrint('❌ Token registration error: $e');
      _showMessage('Error registering device: $e', isError: true);
    }
  }

  // Register FCM token (manual)
  Future<void> registerToken(String fcmToken, {String? deviceType, String? deviceName}) async {
    try {
      final result = await NotificationService.registerToken(
        fcmToken: fcmToken,
        deviceType: deviceType ?? _getDeviceType(),
        deviceName: deviceName ?? _getDeviceName(),
      );
      
      if (result['success']) {
        _showMessage(result['message'] ?? 'Device registered for notifications');
        await loadTokens(); // Refresh token list
      } else {
        _showMessage('Error registering device: ${result['message']}', isError: true);
      }
    } catch (e) {
      _showMessage('Error registering device: $e', isError: true);
    }
  }

  // Remove FCM token
  Future<void> removeToken(String fcmToken) async {
    try {
      final result = await NotificationService.removeToken(fcmToken);
      
      if (result['success']) {
        _tokens.removeWhere((t) => t.fcmToken == fcmToken);
        _showMessage(result['message'] ?? 'Device unregistered');
        notifyListeners();
      } else {
        _showMessage('Error removing device: ${result['message']}', isError: true);
      }
    } catch (e) {
      _showMessage('Error removing device: $e', isError: true);
    }
  }

  // Load FCM tokens
  Future<void> loadTokens() async {
    try {
      final result = await NotificationService.getTokens();
      
      if (result['success']) {
        _tokens = result['tokens'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading tokens: $e');
    }
  }

  // ===== NOTIFICATION HISTORY =====

  // Load notification history
  Future<void> loadHistory({int page = 1, int limit = 20}) async {
    try {
      final result = await NotificationService.getHistory(page: page, limit: limit);
      
      if (result['success']) {
        _history = result['history'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  // ===== HELPER METHODS =====

  // Get notification by ID
  NotificationPreference? getPreferenceById(int id) {
    try {
      return _preferences.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications by time
  List<NotificationPreference> getNotificationsAtTime(TimeOfDay time) {
    return _preferences.where((p) {
      return p.isEnabled && 
             p.time.hour == time.hour && 
             p.time.minute == time.minute;
    }).toList();
  }

  // Get today's notifications (based on repeat days)
  List<NotificationPreference> getTodaysNotifications() {
    final today = DateTime.now().weekday % 7; // Convert to 0-6 (Sun-Sat)
    
    return _preferences.where((p) {
      if (!p.isEnabled) return false;
      
      final days = p.dayIndices;
      return days.contains(today);
    }).toList();
  }

  // Helper method to show messages
  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  // Get device type
  String _getDeviceType() {
    // This is a simplified version
    // For production, use device_info_plus package
    if (ThemeData.fallback().platform == TargetPlatform.iOS) {
      return 'ios';
    } else if (ThemeData.fallback().platform == TargetPlatform.android) {
      return 'android';
    }
    return 'unknown';
  }

  // Get device name
  String _getDeviceName() {
    // This is a simplified version
    // For production, use device_info_plus package
    return 'Flutter Device';
  }

  // Clean up
  void disposeCallbacks() {
    onShowMessage = null;
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadPreferences(),
      loadTokens(),
      loadHistory(),
    ]);
  }
}