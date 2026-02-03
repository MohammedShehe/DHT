import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_service.dart';
import '../utils/api_config.dart';

class ProfileService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Check network connectivity - UPDATED for web compatibility
  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) {
        // For web, we'll assume connectivity is present
        return true;
      } else {
        final connectivityResult = await Connectivity().checkConnectivity();
        return connectivityResult != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'profile': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Update user name
  static Future<Map<String, dynamic>> updateName(String fullName) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/profile/name'),
        headers: headers,
        body: json.encode({
          'full_name': fullName,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update name',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Request email change (send OTP to new email)
  static Future<Map<String, dynamic>> requestEmailChange(String newEmail) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/email/request'),
        headers: headers,
        body: json.encode({
          'new_email': newEmail,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to request email change',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Confirm email change with OTP
  static Future<Map<String, dynamic>> confirmEmailChange(String otp) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/email/confirm'),
        headers: headers,
        body: json.encode({
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to confirm email change',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Upload profile picture - UPDATED VERSION (works for both web and mobile)
  static Future<Map<String, dynamic>> uploadProfilePic({
    required File imageFile,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      // Get auth headers with proper Authorization header
      final headers = await AuthService.getAuthHeaders();
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/profile-pic'),
      );

      // Copy the Authorization header from headers
      request.headers['Authorization'] = headers['Authorization']!;
      
      // Get file extension
      String extension = 'jpg';
      final fileNameLower = fileName.toLowerCase();
      if (fileNameLower.endsWith('.png')) {
        extension = 'png';
      } else if (fileNameLower.endsWith('.jpeg')) {
        extension = 'jpeg';
      } else if (fileNameLower.endsWith('.jpg')) {
        extension = 'jpg';
      }
      
      // Create multipart file from bytes
      final multipartFile = http.MultipartFile.fromBytes(
        'image', // This matches your multer configuration (upload.single('image'))
        bytes,
        filename: 'profile_pic_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = response.body;
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return {
          'success': true,
          'message': data['message'] ?? 'Profile picture updated',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Invalid image file. Please select a valid image (JPEG, PNG).',
        };
      } else {
        try {
          final data = json.decode(responseBody);
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to upload profile picture',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload failed: ${e.toString()}',
      };
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/profile/password'),
        headers: headers,
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}