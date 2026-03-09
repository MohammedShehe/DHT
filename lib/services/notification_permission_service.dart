import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationPermissionService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<bool> checkNotificationPermission() async {
    try {
      if (kIsWeb) return true;
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      if (kIsWeb) return true;
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      if (isGranted) {
        await _firebaseMessaging.subscribeToTopic('all_users');
        await _firebaseMessaging.subscribeToTopic('reminders');
      }
      return isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getFCMToken() async {
    try {
      if (kIsWeb) return null;
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteFCMToken() async {
    try {
      if (kIsWeb) return;
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}