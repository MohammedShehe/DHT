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
  
  // Check network connectivity
  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) {
        // For web, assume connectivity is present
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

  // Upload profile picture - FIXED VERSION
  static Future<Map<String, dynamic>> uploadProfilePic({
    File? imageFile,
    String? fileName,
    Uint8List? bytes,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      // Get auth headers for multipart request
      final token = await AuthService.getStoredToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/profile-pic'),
      );

      // Set authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Determine the bytes and filename
      Uint8List fileBytes;
      String actualFileName;
      
      if (kIsWeb) {
        // For web, use the bytes directly
        if (bytes == null) {
          return {
            'success': false,
            'message': 'No image data provided',
          };
        }
        fileBytes = bytes;
        actualFileName = fileName ?? 'profile_pic_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        // For mobile, read from file
        if (imageFile == null) {
          return {
            'success': false,
            'message': 'No image file provided',
          };
        }
        fileBytes = await imageFile.readAsBytes();
        actualFileName = fileName ?? imageFile.path.split('/').last;
      }
      
      // Validate file size (max 5MB)
      if (fileBytes.length > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Image file is too large. Maximum size is 5MB.',
        };
      }
      
      // Get file extension
      String extension = 'jpg';
      final fileNameLower = actualFileName.toLowerCase();
      if (fileNameLower.endsWith('.png')) {
        extension = 'png';
      } else if (fileNameLower.endsWith('.jpeg')) {
        extension = 'jpeg';
      } else if (fileNameLower.endsWith('.jpg')) {
        extension = 'jpg';
      }
      
      // Get MIME type
      String mimeType;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else {
        mimeType = 'image/jpeg';
      }
      
      // Create multipart file from bytes - FIXED: Use content-type string directly
      final multipartFile = http.MultipartFile.fromBytes(
        'image', // This matches multer configuration (upload.single('image'))
        fileBytes,
        filename: 'profile_pic_${DateTime.now().millisecondsSinceEpoch}.$extension',
        contentType: http.MediaType.parse(mimeType), // FIXED: Use http.MediaType.parse
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
      } else if (response.statusCode == 413) {
        return {
          'success': false,
          'message': 'Image file is too large. Please select a smaller image.',
        };
      } else if (response.statusCode == 415) {
        return {
          'success': false,
          'message': 'Unsupported image format. Please use JPEG or PNG.',
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
            'message': 'Server error: ${response.statusCode} ${response.reasonPhrase}',
          };
        }
      }
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
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
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}