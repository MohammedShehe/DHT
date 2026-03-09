import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPermissionService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Initialize local notifications for Android
  static Future<void> initializeLocalNotifications() async {
    if (kIsWeb) return; // Skip for web

    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  // Check if notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    try {
      if (kIsWeb) {
        // For web, check if notifications are supported
        return NotificationPermissionService._checkWebNotificationPermission();
      }

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      
      debugPrint('📱 Notification permission check: $isGranted');
      return isGranted;
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
      return false;
    }
  }

  // Check web notification permission
  static bool _checkWebNotificationPermission() {
    try {
      // This is a simplified check for web
      // In a real app, you'd use dart:html or package:js
      return true;
    } catch (e) {
      return false;
    }
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      if (kIsWeb) {
        // For web, request permission using Notification API
        return NotificationPermissionService._requestWebNotificationPermission();
      }

      // For mobile, request permission via Firebase
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      
      if (isGranted) {
        // Get FCM token after permission is granted
        final token = await _firebaseMessaging.getToken();
        debugPrint('✅ FCM Token obtained: ${token?.substring(0, 20)}...');
        
        // Subscribe to topics
        await _firebaseMessaging.subscribeToTopic('all_users');
        await _firebaseMessaging.subscribeToTopic('reminders');
      }

      debugPrint('📱 Notification permission requested: $isGranted');
      return isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  // Request web notification permission
  static Future<bool> _requestWebNotificationPermission() async {
    try {
      // This is a placeholder for web implementation
      // In a real app, you'd use the Notification API
      return true;
    } catch (e) {
      return false;
    }
  }

  // Show a local notification (for testing)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'health_reminders',
      'Health Reminders',
      channelDescription: 'Notifications for health reminders and alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      if (kIsWeb) return null;
      
      final token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Delete FCM token (for logout)
  static Future<void> deleteFCMToken() async {
    try {
      if (kIsWeb) return;
      
      await _firebaseMessaging.deleteToken();
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  // Open app settings (for manual permission management)
  static Future<void> openAppSettings() async {
    if (kIsWeb) {
      // For web, show instructions
      debugPrint('Please enable notifications in your browser settings');
      return;
    }

    // For mobile, open app settings
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Check if notifications are enabled on the device
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) return true;

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking if notifications are enabled: $e');
      return false;
    }
  }

  // Get detailed permission status
  static Future<Map<String, dynamic>> getPermissionDetails() async {
    try {
      if (kIsWeb) {
        return {
          'isGranted': true,
          'platform': 'web',
          'details': 'Web platform - permission assumed',
        };
      }

      final settings = await _firebaseMessaging.getNotificationSettings();
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      final token = await _firebaseMessaging.getToken();

      return {
        'isGranted': isGranted,
        'authorizationStatus': settings.authorizationStatus.toString(),
        'sound': settings.sound,
        'badge': settings.badge,
        'alert': settings.alert,
        'hasToken': token != null,
        'platform': 'mobile',
      };
    } catch (e) {
      return {
        'isGranted': false,
        'error': e.toString(),
      };
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      if (kIsWeb) return;
      
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (kIsWeb) return;
      
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }
}