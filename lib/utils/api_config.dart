// lib/utils/api_config.dart
class ApiConfig {
  static const bool isEmulator = false; // Change this based on your environment
  static const bool isPhysicalDevice = true;
  
  static String get baseUrl {
    if (isEmulator) {
      return 'http://10.0.2.2:5000/api'; // Android emulator
    } else if (isPhysicalDevice) {
      return 'http://192.168.1.42:5000/api'; // Your PC's IP address
    } else {
      return 'http://localhost:5000/api'; // For web
    }
  }
}