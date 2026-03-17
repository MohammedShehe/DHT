import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/google_fit_models.dart';
import '../models/activity_models.dart';
import 'auth_service.dart';

class GoogleFitService {
  static final GoogleFitService _instance = GoogleFitService._internal();
  factory GoogleFitService() => _instance;
  GoogleFitService._internal();

  static const String FITNESS_API_BASE = 'https://www.googleapis.com/fitness/v1/users/me';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.activity.write',
      'https://www.googleapis.com/auth/fitness.heart_rate.read',
      'https://www.googleapis.com/auth/fitness.heart_rate.write',
      'https://www.googleapis.com/auth/fitness.body.read',
      'https://www.googleapis.com/auth/fitness.body.write',
      'https://www.googleapis.com/auth/fitness.sleep.read',
      'https://www.googleapis.com/auth/fitness.sleep.write',
    ],
  );
  
  GoogleSignInAccount? _currentUser;
  String? _accessToken;
  bool _isConnected = false;
  
  final Map<String, List<FitnessDataPoint>> _stepsCache = {};
  final Map<String, List<FitnessDataPoint>> _caloriesCache = {};
  final Map<String, List<FitnessDataPoint>> _heartRateCache = {};
  final Map<String, List<FitnessActivity>> _activitiesCache = {};
  final Map<String, List<SleepSession>> _sleepCache = {};
  
  bool get isConnected => _isConnected;
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<bool> connect() async {
    try {
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) return false;
      
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;
      
      final GoogleSignInAuthentication auth = 
          await _currentUser!.authentication;
      _accessToken = auth.accessToken;
      _isConnected = true;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> silentConnect() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      
      if (_currentUser != null) {
        final GoogleSignInAuthentication auth = 
            await _currentUser!.authentication;
        _accessToken = auth.accessToken;
        _isConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      if (await Permission.activityRecognition.isDenied) {
        await Permission.activityRecognition.request();
      }
      if (await Permission.sensors.isDenied) {
        await Permission.sensors.request();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      
      _currentUser = null;
      _accessToken = null;
      _isConnected = false;
      
      _stepsCache.clear();
      _caloriesCache.clear();
      _heartRateCache.clear();
      _activitiesCache.clear();
      _sleepCache.clear();
    } catch (e) {}
  }

  Future<bool> isAvailable() async {
    return true;
  }

  Future<http.Response> _authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$FITNESS_API_BASE$endpoint');
    
    final requestHeaders = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
      ...?headers,
    };

    late http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? json.encode(body) : null,
        );
        break;
      default:
        throw Exception('Unsupported method: $method');
    }

    if (response.statusCode == 401) {
      await _refreshToken();
      return _authenticatedRequest(method, endpoint, headers: headers, body: body);
    }

    return response;
  }

  Future<void> _refreshToken() async {
    try {
      final auth = await _currentUser?.authentication;
      _accessToken = auth?.accessToken;
    } catch (e) {
      throw Exception('Failed to refresh token');
    }
  }

  int _parseNanos(dynamic nanosValue) {
    if (nanosValue == null) return 0;
    
    if (nanosValue is int) {
      return nanosValue;
    } else if (nanosValue is String) {
      return int.tryParse(nanosValue) ?? 0;
    }
    
    return 0;
  }

  Future<List<FitnessDataPoint>> getSteps(DateTime date) async {
    final dateKey = _getDateKey(date);
    
    if (_stepsCache.containsKey(dateKey)) {
      return _stepsCache[dateKey]!;
    }
    
    if (!_isConnected) {
      bool connected = await silentConnect();
      if (!connected) {
        return [];
      }
    }
    
    try {
      final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': 'com.google.step_count.delta',
          }
        ],
        'bucketByTime': {'durationMillis': 86400000},
        'startTimeMillis': startTime.millisecondsSinceEpoch,
        'endTimeMillis': endTime.millisecondsSinceEpoch,
      };

      final response = await _authenticatedRequest(
        'POST',
        '/dataset:aggregate',
        body: requestBody,
      );

      List<FitnessDataPoint> steps = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['bucket'] != null && data['bucket'].isNotEmpty) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null) {
                  for (var point in dataset['point']) {
                    if (point['value'] != null && point['value'].isNotEmpty) {
                      final value = point['value'][0]['intVal'] ?? 
                                   point['value'][0]['fpVal'] ?? 
                                   0;
                      
                      int startTimeNanos = _parseNanos(point['startTimeNanos']);
                      int endTimeNanos = _parseNanos(point['endTimeNanos']);
                      
                      steps.add(FitnessDataPoint(
                        startTime: DateTime.fromMillisecondsSinceEpoch(
                          startTimeNanos ~/ 1000000,
                        ),
                        endTime: DateTime.fromMillisecondsSinceEpoch(
                          endTimeNanos ~/ 1000000,
                        ),
                        value: value.toDouble(),
                        unit: 'steps',
                        type: FitnessDataType.steps,
                        source: FitnessDataSource.googleFit,
                      ));
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      _stepsCache[dateKey] = steps;
      return steps;
      
    } catch (e) {
      return [];
    }
  }

  Future<int> getTotalSteps(DateTime date) async {
    final steps = await getSteps(date);
    double total = 0;
    for (var point in steps) {
      total += point.value;
    }
    return total.toInt();
  }

  Future<List<FitnessDataPoint>> getCalories(DateTime date) async {
    final dateKey = _getDateKey(date);
    
    if (_caloriesCache.containsKey(dateKey)) {
      return _caloriesCache[dateKey]!;
    }
    
    if (!_isConnected) {
      bool connected = await silentConnect();
      if (!connected) {
        return [];
      }
    }
    
    try {
      final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': 'com.google.calories.expended',
          }
        ],
        'bucketByTime': {'durationMillis': 86400000},
        'startTimeMillis': startTime.millisecondsSinceEpoch,
        'endTimeMillis': endTime.millisecondsSinceEpoch,
      };

      final response = await _authenticatedRequest(
        'POST',
        '/dataset:aggregate',
        body: requestBody,
      );

      List<FitnessDataPoint> calories = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['bucket'] != null && data['bucket'].isNotEmpty) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null) {
                  for (var point in dataset['point']) {
                    if (point['value'] != null && point['value'].isNotEmpty) {
                      final value = point['value'][0]['fpVal'] ?? 0;
                      
                      int startTimeNanos = _parseNanos(point['startTimeNanos']);
                      int endTimeNanos = _parseNanos(point['endTimeNanos']);
                      
                      calories.add(FitnessDataPoint(
                        startTime: DateTime.fromMillisecondsSinceEpoch(
                          startTimeNanos ~/ 1000000,
                        ),
                        endTime: DateTime.fromMillisecondsSinceEpoch(
                          endTimeNanos ~/ 1000000,
                        ),
                        value: value.toDouble(),
                        unit: 'kcal',
                        type: FitnessDataType.calories,
                        source: FitnessDataSource.googleFit,
                      ));
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      _caloriesCache[dateKey] = calories;
      return calories;
      
    } catch (e) {
      return [];
    }
  }

  Future<int> getTotalCalories(DateTime date) async {
    final calories = await getCalories(date);
    double total = 0;
    for (var point in calories) {
      total += point.value;
    }
    return total.toInt();
  }

  Future<List<FitnessDataPoint>> getHeartRate(DateTime date) async {
    final dateKey = _getDateKey(date);
    
    if (_heartRateCache.containsKey(dateKey)) {
      return _heartRateCache[dateKey]!;
    }
    
    if (!_isConnected) {
      bool connected = await silentConnect();
      if (!connected) {
        return [];
      }
    }
    
    try {
      final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': 'com.google.heart_rate.bpm',
          }
        ],
        'bucketByTime': {'durationMillis': 3600000},
        'startTimeMillis': startTime.millisecondsSinceEpoch,
        'endTimeMillis': endTime.millisecondsSinceEpoch,
      };

      final response = await _authenticatedRequest(
        'POST',
        '/dataset:aggregate',
        body: requestBody,
      );

      List<FitnessDataPoint> heartRates = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['bucket'] != null) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null) {
                  for (var point in dataset['point']) {
                    if (point['value'] != null && point['value'].isNotEmpty) {
                      final value = point['value'][0]['fpVal'] ?? 0;
                      
                      int startTimeNanos = _parseNanos(point['startTimeNanos']);
                      int endTimeNanos = _parseNanos(point['endTimeNanos']);
                      
                      heartRates.add(FitnessDataPoint(
                        startTime: DateTime.fromMillisecondsSinceEpoch(
                          startTimeNanos ~/ 1000000,
                        ),
                        endTime: DateTime.fromMillisecondsSinceEpoch(
                          endTimeNanos ~/ 1000000,
                        ),
                        value: value.toDouble(),
                        unit: 'bpm',
                        type: FitnessDataType.heartRate,
                        source: FitnessDataSource.googleFit,
                      ));
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      _heartRateCache[dateKey] = heartRates;
      return heartRates;
      
    } catch (e) {
      return [];
    }
  }

  Future<double> getAverageHeartRate(DateTime date) async {
    final heartRates = await getHeartRate(date);
    if (heartRates.isEmpty) return 0;
    double sum = 0;
    for (var point in heartRates) {
      sum += point.value;
    }
    return sum / heartRates.length;
  }

  Future<List<FitnessActivity>> getActivities(DateTime startDate, DateTime endDate) async {
    final dateRangeKey = '${_getDateKey(startDate)}_${_getDateKey(endDate)}';
    
    if (_activitiesCache.containsKey(dateRangeKey)) {
      return _activitiesCache[dateRangeKey]!;
    }
    
    if (!_isConnected) {
      bool connected = await silentConnect();
      if (!connected) {
        return [];
      }
    }
    
    try {
      final response = await _authenticatedRequest(
        'GET',
        '/sessions?startTime=${startDate.millisecondsSinceEpoch}&endTime=${endDate.millisecondsSinceEpoch}',
      );

      List<FitnessActivity> activities = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['session'] != null) {
          for (var session in data['session']) {
            int calories = 0;
            int steps = 0;
            double distance = 0;
            
            if (session.containsKey('activityType')) {
              activities.add(FitnessActivity(
                id: session['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: session['name'] ?? 'Activity',
                activityType: session['activityType'] ?? 0,
                startTime: DateTime.fromMillisecondsSinceEpoch(
                  int.parse(session['startTimeMillis']),
                ),
                endTime: DateTime.fromMillisecondsSinceEpoch(
                  int.parse(session['endTimeMillis']),
                ),
                duration: (int.parse(session['endTimeMillis']) - 
                          int.parse(session['startTimeMillis'])) / 60000.0,
                calories: calories,
                steps: steps,
                distance: distance,
              ));
            }
          }
        }
      }
      
      _activitiesCache[dateRangeKey] = activities;
      return activities;
      
    } catch (e) {
      return [];
    }
  }

  Future<List<FitnessActivity>> getTodayActivities() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return await getActivities(startOfDay, endOfDay);
  }

  Future<List<SleepSession>> getSleep(DateTime date) async {
    final dateKey = _getDateKey(date);
    
    if (_sleepCache.containsKey(dateKey)) {
      return _sleepCache[dateKey]!;
    }
    
    if (!_isConnected) {
      bool connected = await silentConnect();
      if (!connected) {
        return [];
      }
    }
    
    try {
      final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': 'com.google.sleep.segment',
          }
        ],
        'startTimeMillis': startTime.millisecondsSinceEpoch,
        'endTimeMillis': endTime.millisecondsSinceEpoch,
      };

      final response = await _authenticatedRequest(
        'POST',
        '/dataset:aggregate',
        body: requestBody,
      );

      List<SleepSession> sleepSessions = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['bucket'] != null) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null) {
                  List<SleepSegment> segments = [];
                  
                  for (var point in dataset['point']) {
                    if (point['value'] != null && point['value'].isNotEmpty) {
                      final sleepType = point['value'][0]['intVal'] ?? 0;
                      
                      int startTimeNanos = _parseNanos(point['startTimeNanos']);
                      int endTimeNanos = _parseNanos(point['endTimeNanos']);
                      
                      segments.add(SleepSegment(
                        startTime: DateTime.fromMillisecondsSinceEpoch(
                          startTimeNanos ~/ 1000000,
                        ),
                        endTime: DateTime.fromMillisecondsSinceEpoch(
                          endTimeNanos ~/ 1000000,
                        ),
                        sleepType: sleepType,
                      ));
                    }
                  }
                  
                  if (segments.isNotEmpty) {
                    double deepSleep = 0, lightSleep = 0, remSleep = 0, awake = 0;
                    
                    for (var segment in segments) {
                      double duration = segment.endTime.difference(segment.startTime).inMinutes / 60.0;
                      if (segment.sleepType == 3) deepSleep += duration;
                      else if (segment.sleepType == 4) remSleep += duration;
                      else if (segment.sleepType == 2) lightSleep += duration;
                      else if (segment.sleepType == 1) awake += duration;
                    }
                    
                    sleepSessions.add(SleepSession(
                      startTime: segments.first.startTime,
                      endTime: segments.last.endTime,
                      duration: segments.last.endTime.difference(segments.first.startTime).inMinutes / 60.0,
                      sleepType: 1,
                      deepSleepDuration: deepSleep,
                      lightSleepDuration: lightSleep,
                      remSleepDuration: remSleep,
                      awakeDuration: awake.toInt(),
                      segments: segments,
                    ));
                  }
                }
              }
            }
          }
        }
      }
      
      _sleepCache[dateKey] = sleepSessions;
      return sleepSessions;
      
    } catch (e) {
      return [];
    }
  }

  Future<DailyFitnessSummary> getDailySummary(DateTime date) async {
    final steps = await getTotalSteps(date);
    final calories = await getTotalCalories(date);
    final heartRate = await getAverageHeartRate(date);
    final activities = await getActivities(date, date);
    
    double activeMinutes = 0;
    double totalDistance = 0;
    
    for (var activity in activities) {
      activeMinutes += activity.duration;
      totalDistance += activity.distance;
    }
    
    Map<int, int> activityBreakdown = {};
    for (var activity in activities) {
      activityBreakdown[activity.activityType] = 
          (activityBreakdown[activity.activityType] ?? 0) + 1;
    }
    
    return DailyFitnessSummary(
      date: date,
      totalSteps: steps,
      totalCalories: calories,
      totalDistance: totalDistance,
      totalActiveMinutes: activeMinutes,
      averageHeartRate: heartRate,
      totalActivities: activities.length,
      activityBreakdown: activityBreakdown,
    );
  }

  Future<List<DailyFitnessSummary>> getWeeklySummary(DateTime startDate) async {
    List<DailyFitnessSummary> summaries = [];
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final summary = await getDailySummary(date);
      summaries.add(summary);
    }
    
    return summaries;
  }

  Future<List<Workout>> syncActivitiesToWorkouts(DateTime date) async {
    try {
      final activities = await getActivities(date, date);
      List<Workout> workouts = [];
      
      for (var activity in activities) {
        if (activity.duration >= 5) {
          workouts.add(Workout(
            id: activity.id,
            type: activity.name,
            duration: activity.duration.toInt(),
            calories: activity.calories,
            time: DateFormat.jm().format(activity.startTime),
            intensity: _getIntensityFromDuration(activity.duration),
            notes: 'Synced from Google Fit',
          ));
        }
      }
      
      return workouts;
    } catch (e) {
      return [];
    }
  }

  String _getIntensityFromDuration(double duration) {
    if (duration > 60) return 'High';
    if (duration > 30) return 'Moderate';
    return 'Low';
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void clearCaches() {
    _stepsCache.clear();
    _caloriesCache.clear();
    _heartRateCache.clear();
    _activitiesCache.clear();
    _sleepCache.clear();
  }
}