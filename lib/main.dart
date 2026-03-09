import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // NEW
import 'screens/loading_page.dart';
import 'services/auth_service.dart';
import 'services/notification_permission_service.dart'; // NEW
import 'providers/activity_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/smart_reminder_provider.dart';

// Add this for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  
  // Show local notification for background messages
  await NotificationPermissionService.showLocalNotification(
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? '',
    payload: message.data.toString(),
  );
}

void main() async {
  WidgetsBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('🔥 Firebase initialized successfully');
    
    // Initialize local notifications
    await NotificationPermissionService.initializeLocalNotifications();
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _setupNotifications();
    
  } catch (e, stack) {
    print('❌ Firebase initialization error: $e');
    print('Stack: $stack');
  }
  
  // Initialize AuthService before app starts
  await AuthService.initializeToken();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

Future<void> _setupNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;
    
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('📱 Permission status: ${settings.authorizationStatus}');
    
    final token = await messaging.getToken();
    if (token != null) {
      print('✅ FCM Token: ${token.substring(0, 20)}...');
    } else {
      print('❌ No FCM token received');
    }
    
    messaging.onTokenRefresh.listen((newToken) {
      print('🔄 Token refreshed: $newToken');
    });
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        
        // Show local notification for foreground messages
        NotificationPermissionService.showLocalNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });
    
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state: ${initialMessage.messageId}');
    }
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background: ${message.messageId}');
    });
    
  } catch (e, stack) {
    print('❌ Error setting up notifications: $e');
    print('Stack: $stack');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SmartReminderProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HealthTracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00C853),
            primary: const Color(0xFF00C853),
            secondary: const Color(0xFF00E676),
            tertiary: const Color(0xFF69F0AE),
            background: const Color(0xFFF8FDF9),
            surface: Colors.white,
          ),
          fontFamily: 'Inter',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1A1A1A),
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C853), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
        home: const LoadingPage(),
      ),
    );
  }
}