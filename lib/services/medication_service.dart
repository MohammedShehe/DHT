// lib/services/medication_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../utils/api_config.dart';
import '../models/medication_models.dart';

class MedicationService {
  static String get baseUrl => '${ApiConfig.baseUrl}/medications';

  static Future<bool> _checkNetwork() async {
    try {
      if (kIsWeb) return true;
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // ===== REFERENCE DATA =====

  static Future<Map<String, dynamic>> getUnits() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'units': [],
        'units_with_labels': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/units'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'units': data['units'] ?? [],
          'units_with_labels': data['units_with_labels'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch units',
          'units': [],
          'units_with_labels': [],
        };
      }
    } catch (e) {
      debugPrint('Get units error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'units': [],
        'units_with_labels': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getStatuses() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'statuses': [],
        'statuses_with_labels': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/statuses'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'statuses': data['statuses'] ?? [],
          'statuses_with_labels': data['statuses_with_labels'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch statuses',
          'statuses': [],
          'statuses_with_labels': [],
        };
      }
    } catch (e) {
      debugPrint('Get statuses error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'statuses': [],
        'statuses_with_labels': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getColorPresets() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'colors': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/colors'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'colors': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch color presets',
          'colors': [],
        };
      }
    } catch (e) {
      debugPrint('Get color presets error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'colors': [],
      };
    }
  }

  // ===== MEDICATION CRUD =====

  static Future<Map<String, dynamic>> createMedication(Map<String, dynamic> data) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      
      debugPrint('Creating medication: ${json.encode(data)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(data),
      );

      final responseBody = response.body;
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Medication created successfully',
          'medication': responseData['medication'] != null 
              ? Medication.fromJson(responseData['medication'])
              : null,
        };
      } else {
        final errorData = responseBody.isNotEmpty ? json.decode(responseBody) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create medication',
        };
      }
    } catch (e) {
      debugPrint('Create medication error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMedications({String filter = 'active'}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'medications': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl?filter=$filter'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Medication> medications = [];
        if (data is List) {
          medications = data.map((m) => Medication.fromJson(m)).toList();
        }
        return {
          'success': true,
          'medications': medications,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch medications',
          'medications': [],
        };
      }
    } catch (e) {
      debugPrint('Get medications error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'medications': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getMedicationById(int id) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'medication': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'medication': Medication.fromJson(data),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Medication not found',
          'medication': null,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch medication',
          'medication': null,
        };
      }
    } catch (e) {
      debugPrint('Get medication by ID error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'medication': null,
      };
    }
  }

  static Future<Map<String, dynamic>> updateMedication(int id, Map<String, dynamic> data) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Medication updated successfully',
          'medication': responseData['medication'] != null 
              ? Medication.fromJson(responseData['medication'])
              : null,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update medication',
        };
      }
    } catch (e) {
      debugPrint('Update medication error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteMedication(int id) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Medication deleted successfully',
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete medication',
        };
      }
    } catch (e) {
      debugPrint('Delete medication error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== SCHEDULE MANAGEMENT =====

  static Future<Map<String, dynamic>> addSchedule(int medicationId, Map<String, dynamic> scheduleData) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$medicationId/schedules'),
        headers: headers,
        body: json.encode(scheduleData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Schedule added successfully',
          'medication': responseData['medication'] != null 
              ? Medication.fromJson(responseData['medication'])
              : null,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add schedule',
        };
      }
    } catch (e) {
      debugPrint('Add schedule error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteSchedule(int medicationId, int scheduleId) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$medicationId/schedules/$scheduleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Schedule deleted successfully',
          'medication': responseData['medication'] != null 
              ? Medication.fromJson(responseData['medication'])
              : null,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete schedule',
        };
      }
    } catch (e) {
      debugPrint('Delete schedule error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ===== ADHERENCE LOGGING =====

  static Future<Map<String, dynamic>> logIntake(Map<String, dynamic> data) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/logs'),
        headers: headers,
        body: json.encode(data),
      );

      final responseBody = response.body;
      debugPrint('Log intake response: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Medication intake logged successfully',
          'logId': responseData['id'],
        };
      } else {
        final errorData = responseBody.isNotEmpty ? json.decode(responseBody) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to log intake',
        };
      }
    } catch (e) {
      debugPrint('Log intake error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateLogStatus(int logId, String status, {TimeOfDay? actualTime}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final body = {
        'status': status,
      };
      if (actualTime != null) {
        body['actual_time'] = '${actualTime.hour.toString().padLeft(2, '0')}:${actualTime.minute.toString().padLeft(2, '0')}:00';
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/logs/$logId'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Log status updated',
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update log status',
        };
      }
    } catch (e) {
      debugPrint('Update log status error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getLogsByDate(DateTime date) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'logs': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/logs/date/$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<MedicationAdherenceLog> logs = [];
        if (data is List) {
          logs = data.map((l) => MedicationAdherenceLog.fromJson(l)).toList();
        }
        return {
          'success': true,
          'logs': logs,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch logs',
          'logs': [],
        };
      }
    } catch (e) {
      debugPrint('Get logs by date error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'logs': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? medicationId,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'logs': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final startFormatted = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endFormatted = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      
      String url = '$baseUrl/logs/range?start_date=$startFormatted&end_date=$endFormatted';
      if (medicationId != null) {
        url += '&medication_id=$medicationId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<MedicationAdherenceLog> logs = [];
        if (data['logs'] != null && data['logs'] is List) {
          logs = (data['logs'] as List)
              .map((l) => MedicationAdherenceLog.fromJson(l))
              .toList();
        }
        return {
          'success': true,
          'logs': logs,
          'total': data['total'] ?? logs.length,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch logs',
          'logs': [],
        };
      }
    } catch (e) {
      debugPrint('Get logs by range error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'logs': [],
      };
    }
  }

  // ===== STATISTICS & ANALYTICS =====

  static Future<Map<String, dynamic>> getAdherenceRate({
    required int medicationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'adherence': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final startFormatted = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endFormatted = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/$medicationId/adherence?start_date=$startFormatted&end_date=$endFormatted'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'adherence': MedicationAdherenceRate.fromJson(data),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Medication not found',
          'adherence': null,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch adherence rate',
          'adherence': null,
        };
      }
    } catch (e) {
      debugPrint('Get adherence rate error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'adherence': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getAllAdherenceRates({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'overall_adherence': 0,
        'medications': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final startFormatted = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endFormatted = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/adherence/all?start_date=$startFormatted&end_date=$endFormatted'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<MedicationAdherenceRate> medications = [];
        if (data['medications'] != null && data['medications'] is List) {
          medications = (data['medications'] as List)
              .map((m) => MedicationAdherenceRate.fromJson(m))
              .toList();
        }
        return {
          'success': true,
          'overall_adherence': data['overall_adherence'] as int? ?? 0,
          'medications': medications,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch adherence rates',
          'overall_adherence': 0,
          'medications': [],
        };
      }
    } catch (e) {
      debugPrint('Get all adherence rates error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'overall_adherence': 0,
        'medications': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getDailySummary({DateTime? date}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'summary': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      String url = '$baseUrl/summary/daily';
      if (date != null) {
        final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '?date=$formattedDate';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'summary': DailyMedicationSummary.fromJson(data),
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch daily summary',
          'summary': null,
        };
      }
    } catch (e) {
      debugPrint('Get daily summary error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'summary': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getMissedDoses({DateTime? date}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'missed': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      String url = '$baseUrl/missed';
      if (date != null) {
        final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '?date=$formattedDate';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<MedicationAdherenceLog> missed = [];
        if (data is List) {
          missed = data.map((m) => MedicationAdherenceLog.fromJson(m)).toList();
        }
        return {
          'success': true,
          'missed': missed,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch missed doses',
          'missed': [],
        };
      }
    } catch (e) {
      debugPrint('Get missed doses error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'missed': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getUpcomingDoses() async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'doses': [],
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/upcoming'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<UpcomingDose> doses = [];
        if (data is List) {
          doses = data.map((d) => UpcomingDose.fromJson(d)).toList();
        }
        return {
          'success': true,
          'doses': doses,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch upcoming doses',
          'doses': [],
        };
      }
    } catch (e) {
      debugPrint('Get upcoming doses error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'doses': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getMedicationStats(int medicationId, {String period = 'week'}) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'stats': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$medicationId/stats?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'stats': MedicationStats.fromJson(data),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Medication not found',
          'stats': null,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch medication stats',
          'stats': null,
        };
      }
    } catch (e) {
      debugPrint('Get medication stats error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'stats': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getMedicationDetailsForDate(int medicationId, DateTime date) async {
    if (!await _checkNetwork()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'details': null,
      };
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/$medicationId/date/$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'details': data,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Medication not found',
          'details': null,
        };
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch medication details',
          'details': null,
        };
      }
    } catch (e) {
      debugPrint('Get medication details error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'details': null,
      };
    }
  }
}