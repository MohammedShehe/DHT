import 'dart:convert';
import 'dart:math';
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
  
  // Google Fit uses epoch of January 1, 1980
  static final DateTime _googleFitEpoch = DateTime(1980, 1, 1);
  
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
      debugPrint('🔌 Connecting to Google Fit...');
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        debugPrint('❌ Permissions not granted');
        return false;
      }
      
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        debugPrint('❌ User cancelled sign in');
        return false;
      }
      
      final GoogleSignInAuthentication auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;
      _isConnected = true;
      
      debugPrint('✅ Connected to Google Fit as: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      return false;
    }
  }

  Future<bool> silentConnect() async {
    try {
      debugPrint('🔌 Attempting silent connect...');
      _currentUser = await _googleSignIn.signInSilently();
      
      if (_currentUser != null) {
        final GoogleSignInAuthentication auth = await _currentUser!.authentication;
        _accessToken = auth.accessToken;
        _isConnected = true;
        debugPrint('✅ Silent connect successful: ${_currentUser!.email}');
        return true;
      }
      debugPrint('⚠️ No user signed in silently');
      return false;
    } catch (e) {
      debugPrint('❌ Silent connect error: $e');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      if (await Permission.activityRecognition.isDenied) {
        debugPrint('📱 Requesting activity recognition permission...');
        await Permission.activityRecognition.request();
      }
      if (await Permission.sensors.isDenied) {
        debugPrint('📱 Requesting sensors permission...');
        await Permission.sensors.request();
      }
      
      final activityGranted = await Permission.activityRecognition.isGranted;
      final sensorsGranted = await Permission.sensors.isGranted;
      
      debugPrint('📱 Permissions - Activity: $activityGranted, Sensors: $sensorsGranted');
      return true;
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      debugPrint('🔌 Disconnecting from Google Fit...');
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
      
      debugPrint('✅ Disconnected from Google Fit');
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    }
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
      debugPrint('❌ No access token available');
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$FITNESS_API_BASE$endpoint');
    
    final requestHeaders = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
      ...?headers,
    };

    debugPrint('📡 Making $method request to: $endpoint');
    
    late http.Response response;
    
    try {
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

      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        debugPrint('📡 Response body preview: ${response.body.substring(0, min(200, response.body.length))}...');
      } else if (response.statusCode != 200) {
        debugPrint('📡 Error response: ${response.body}');
      }

      if (response.statusCode == 401) {
        debugPrint('🔄 Token expired, refreshing...');
        await _refreshToken();
        return _authenticatedRequest(method, endpoint, headers: headers, body: body);
      }

      return response;
    } catch (e) {
      debugPrint('❌ Request error: $e');
      rethrow;
    }
  }

  Future<void> _refreshToken() async {
    try {
      debugPrint('🔄 Refreshing token...');
      final auth = await _currentUser?.authentication;
      _accessToken = auth?.accessToken;
      debugPrint('✅ Token refreshed');
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
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

  // Convert DateTime to Google Fit nanoseconds (since Jan 1, 1980)
  int _toGoogleFitNanos(DateTime date) {
    return (date.millisecondsSinceEpoch - _googleFitEpoch.millisecondsSinceEpoch) * 1000000;
  }

  // Convert Google Fit nanoseconds back to DateTime
  DateTime _fromGoogleFitNanos(int nanos) {
    return DateTime.fromMillisecondsSinceEpoch((nanos ~/ 1000000) + _googleFitEpoch.millisecondsSinceEpoch);
  }

  Future<List<FitnessDataPoint>> getSteps(DateTime date) async {
    final dateKey = _getDateKey(date);
    debugPrint('👣 Getting steps for date: $dateKey');
    
    if (_stepsCache.containsKey(dateKey)) {
      debugPrint('📦 Returning ${_stepsCache[dateKey]!.length} steps from cache');
      return _stepsCache[dateKey]!;
    }
    
    if (!_isConnected) {
      debugPrint('⚠️ Not connected, trying silent connect...');
      bool connected = await silentConnect();
      if (!connected) {
        debugPrint('❌ Failed to connect');
        return [];
      }
    }
    
    try {
      final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      debugPrint('📅 Steps time range: ${startTime.toIso8601String()} to ${endTime.toIso8601String()}');
      
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
        debugPrint('📊 Steps response keys: ${data.keys}');
        
        if (data['bucket'] != null && data['bucket'].isNotEmpty) {
          debugPrint('📊 Found ${data['bucket'].length} buckets');
          
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null) {
                  debugPrint('📊 Found ${dataset['point'].length} points');
                  
                  for (var point in dataset['point']) {
                    if (point['value'] != null && point['value'].isNotEmpty) {
                      final value = point['value'][0]['intVal'] ?? 
                                   point['value'][0]['fpVal'] ?? 
                                   0;
                      
                      int startTimeNanos = _parseNanos(point['startTimeNanos']);
                      int endTimeNanos = _parseNanos(point['endTimeNanos']);
                      
                      steps.add(FitnessDataPoint(
                        startTime: _fromGoogleFitNanos(startTimeNanos),
                        endTime: _fromGoogleFitNanos(endTimeNanos),
                        value: (value is num) ? value.toDouble() : 0.0,
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
        } else {
          debugPrint('⚠️ No buckets found in steps response');
        }
      }
      
      debugPrint('✅ Found ${steps.length} step entries');
      _stepsCache[dateKey] = steps;
      return steps;
      
    } catch (e) {
      debugPrint('❌ Error getting steps: $e');
      return [];
    }
  }

  Future<int> getTotalSteps(DateTime date) async {
    final steps = await getSteps(date);
    double total = 0;
    for (var point in steps) {
      total += point.value;
    }
    debugPrint('📊 Total steps for ${_getDateKey(date)}: $total');
    return total.toInt();
  }

  Future<List<FitnessDataPoint>> getCalories(DateTime date) async {
    final dateKey = _getDateKey(date);
    debugPrint('🔥 Getting calories for date: $dateKey');
    
    if (_caloriesCache.containsKey(dateKey)) {
      debugPrint('📦 Returning ${_caloriesCache[dateKey]!.length} calories from cache');
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
                        startTime: _fromGoogleFitNanos(startTimeNanos),
                        endTime: _fromGoogleFitNanos(endTimeNanos),
                        value: (value is num) ? value.toDouble() : 0.0,
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
      
      debugPrint('✅ Found ${calories.length} calorie entries');
      _caloriesCache[dateKey] = calories;
      return calories;
      
    } catch (e) {
      debugPrint('❌ Error getting calories: $e');
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
    debugPrint('❤️ Getting heart rate for date: $dateKey');
    
    if (_heartRateCache.containsKey(dateKey)) {
      debugPrint('📦 Returning ${_heartRateCache[dateKey]!.length} heart rate entries from cache');
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
                        startTime: _fromGoogleFitNanos(startTimeNanos),
                        endTime: _fromGoogleFitNanos(endTimeNanos),
                        value: (value is num) ? value.toDouble() : 0.0,
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
      
      debugPrint('✅ Found ${heartRates.length} heart rate entries');
      _heartRateCache[dateKey] = heartRates;
      return heartRates;
      
    } catch (e) {
      debugPrint('❌ Error getting heart rate: $e');
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

  // FIXED: Google Fit API /sessions expects timestamps in NANOSECONDS since Jan 1, 1980
  Future<List<FitnessActivity>> getActivities(DateTime startDate, DateTime endDate) async {
    final dateRangeKey = '${_getDateKey(startDate)}_${_getDateKey(endDate)}';
    
    debugPrint('🔍 Getting activities from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    
    if (_activitiesCache.containsKey(dateRangeKey)) {
      debugPrint('📦 Returning ${_activitiesCache[dateRangeKey]!.length} activities from cache');
      return _activitiesCache[dateRangeKey]!;
    }
    
    if (!_isConnected) {
      debugPrint('⚠️ Not connected, trying silent connect...');
      bool connected = await silentConnect();
      if (!connected) {
        debugPrint('❌ Failed to connect');
        return [];
      }
    }
    
    try {
      // CRITICAL FIX: Convert to NANOSECONDS since Google Fit epoch (Jan 1, 1980)
      final startNanos = _toGoogleFitNanos(startDate);
      final endNanos = _toGoogleFitNanos(endDate);
      
      // If start and end are the same, add 1 day in nanoseconds
      final actualEndNanos = (startNanos == endNanos) 
          ? startNanos + Duration(days: 1).inMilliseconds * 1000000
          : endNanos;
      
      debugPrint('📅 Time range in ns (Google Fit epoch): $startNanos to $actualEndNanos');
      
      final response = await _authenticatedRequest(
        'GET',
        '/sessions?startTime=$startNanos&endTime=$actualEndNanos',
      );

      List<FitnessActivity> activities = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('📊 Activities response keys: ${data.keys}');
        
        if (data['session'] != null) {
          debugPrint('📊 Found ${data['session'].length} sessions');
          
          for (var session in data['session']) {
            debugPrint('📊 Session: ${session['name']}, type: ${session['activityType']}, start: ${session['startTimeMillis']}');
            
            int calories = 0;
            int steps = 0;
            double distance = 0.0;
            
            try {
              // Parse times from milliseconds (still in milliseconds in session data)
              final startTimeMillis = int.parse(session['startTimeMillis'].toString());
              final endTimeMillis = int.parse(session['endTimeMillis'].toString());
              
              final activityStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
              final activityEndTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
              
              // Get steps during this activity
              final stepsData = await getStepsForTimeRange(activityStartTime, activityEndTime);
              steps = stepsData;
              
              // Get calories during this activity
              final caloriesData = await getCaloriesForTimeRange(activityStartTime, activityEndTime);
              calories = caloriesData;
              
              if (session.containsKey('distance')) {
                final distanceValue = session['distance'];
                if (distanceValue is int) {
                  distance = distanceValue.toDouble();
                } else if (distanceValue is double) {
                  distance = distanceValue;
                } else if (distanceValue is String) {
                  distance = double.tryParse(distanceValue) ?? 0.0;
                }
              }
            } catch (e) {
              debugPrint('⚠️ Error getting additional activity data: $e');
            }
            
            final startTimeMillis = int.parse(session['startTimeMillis'].toString());
            final endTimeMillis = int.parse(session['endTimeMillis'].toString());
            
            final activity = FitnessActivity(
              id: session['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: session['name']?.toString() ?? 'Activity',
              activityType: session['activityType'] is int 
                  ? session['activityType'] 
                  : (session['activityType']?.toInt() ?? 0),
              startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMillis),
              endTime: DateTime.fromMillisecondsSinceEpoch(endTimeMillis),
              duration: (endTimeMillis - startTimeMillis) / 60000.0,
              calories: calories,
              steps: steps,
              distance: distance,
            );
            
            activities.add(activity);
            debugPrint('✅ Added activity: ${activity.name}, duration: ${activity.duration}min, calories: $calories, steps: $steps');
          }
        } else {
          debugPrint('⚠️ No sessions found in response');
        }
      } else {
        debugPrint('❌ Failed to get activities: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
      
      debugPrint('✅ Found ${activities.length} activities total');
      _activitiesCache[dateRangeKey] = activities;
      return activities;
      
    } catch (e) {
      debugPrint('❌ Exception in getActivities: $e');
      return [];
    }
  }

  Future<int> getStepsForTimeRange(DateTime startTime, DateTime endTime) async {
    try {
      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': 'com.google.step_count.delta',
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

      int totalSteps = 0;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['bucket'] != null) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null) {
                  for (var point in dataset['point']) {
                    if (point['value'] != null && point['value'].isNotEmpty) {
                      final value = point['value'][0]['intVal'] ?? 
                                   point['value'][0]['fpVal'] ?? 
                                   0;
                      if (value is num) {
                        totalSteps += value.toInt();
                      } else if (value is int) {
                        totalSteps += value;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      return totalSteps;
    } catch (e) {
      debugPrint('❌ Error getting steps for time range: $e');
      return 0;
    }
  }

  Future<int> getCaloriesForTimeRange(DateTime startTime, DateTime endTime) async {
    try {
      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': 'com.google.calories.expended',
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

      int totalCalories = 0;

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
                      if (value is num) {
                        totalCalories += value.toInt();
                      } else if (value is int) {
                        totalCalories += value;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      return totalCalories;
    } catch (e) {
      debugPrint('❌ Error getting calories for time range: $e');
      return 0;
    }
  }

  Future<List<FitnessActivity>> getTodayActivities() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    debugPrint('📅 Getting today\'s activities from ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');
    
    return await getActivities(startOfDay, endOfDay);
  }

  Future<List<SleepSession>> getSleep(DateTime date) async {
    final dateKey = _getDateKey(date);
    debugPrint('😴 Getting sleep for date: $dateKey');
    
    if (_sleepCache.containsKey(dateKey)) {
      debugPrint('📦 Returning ${_sleepCache[dateKey]!.length} sleep sessions from cache');
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
                        startTime: _fromGoogleFitNanos(startTimeNanos),
                        endTime: _fromGoogleFitNanos(endTimeNanos),
                        sleepType: sleepType is int ? sleepType : 0,
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
      
      debugPrint('✅ Found ${sleepSessions.length} sleep sessions');
      _sleepCache[dateKey] = sleepSessions;
      return sleepSessions;
      
    } catch (e) {
      debugPrint('❌ Error getting sleep: $e');
      return [];
    }
  }

  Future<DailyFitnessSummary> getDailySummary(DateTime date) async {
    debugPrint('📊 Getting daily summary for ${_getDateKey(date)}');
    
    final steps = await getTotalSteps(date);
    final calories = await getTotalCalories(date);
    final heartRate = await getAverageHeartRate(date);
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final activities = await getActivities(startOfDay, endOfDay);
    
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
    
    final summary = DailyFitnessSummary(
      date: date,
      totalSteps: steps,
      totalCalories: calories,
      totalDistance: totalDistance,
      totalActiveMinutes: activeMinutes,
      averageHeartRate: heartRate,
      totalActivities: activities.length,
      activityBreakdown: activityBreakdown,
    );
    
    debugPrint('📊 Daily summary: Steps=$steps, Calories=$calories, Activities=${activities.length}');
    return summary;
  }

  Future<List<DailyFitnessSummary>> getWeeklySummary(DateTime startDate) async {
    debugPrint('📊 Getting weekly summary starting from ${_getDateKey(startDate)}');
    
    List<DailyFitnessSummary> summaries = [];
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final summary = await getDailySummary(date);
      summaries.add(summary);
    }
    
    debugPrint('✅ Got weekly summary for ${summaries.length} days');
    return summaries;
  }

  Future<List<Workout>> syncActivitiesToWorkouts(DateTime date) async {
    debugPrint('🔄 Syncing activities to workouts for date: ${_getDateKey(date)}');
    
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final activities = await getActivities(startOfDay, endOfDay);
      debugPrint('📊 Found ${activities.length} activities from Google Fit');
      
      List<Workout> workouts = [];
      
      for (var activity in activities) {
        debugPrint('📊 Processing activity: ${activity.name}, duration: ${activity.duration}min, calories: ${activity.calories}');
        
        if (activity.duration >= 5) {
          final workout = Workout(
            id: activity.id,
            type: activity.name,
            duration: activity.duration.toInt(),
            calories: activity.calories,
            time: DateFormat.jm().format(activity.startTime),
            intensity: _getIntensityFromDuration(activity.duration),
            notes: 'Synced from Google Fit',
          );
          workouts.add(workout);
          debugPrint('✅ Added workout: ${workout.type} (${workout.duration}min)');
        } else {
          debugPrint('⏭️ Skipping activity (too short): ${activity.duration}min');
        }
      }
      
      debugPrint('✅ Created ${workouts.length} workouts to sync');
      return workouts;
    } catch (e) {
      debugPrint('❌ Error syncing activities to workouts: $e');
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
    debugPrint('🧹 Clearing all caches');
    _stepsCache.clear();
    _caloriesCache.clear();
    _heartRateCache.clear();
    _activitiesCache.clear();
    _sleepCache.clear();
  }

  Future<Map<String, dynamic>> testConnection() async {
    debugPrint('🧪 Testing Google Fit connection...');
    
    try {
      if (!_isConnected) {
        final connected = await silentConnect();
        if (!connected) {
          return {'success': false, 'message': 'Not connected'};
        }
      }
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final activities = await getActivities(startOfDay, endOfDay);
      final steps = await getSteps(today);
      
      return {
        'success': true,
        'message': 'Connected successfully',
        'activities': activities.length,
        'steps': steps.length,
        'user': _currentUser?.email,
      };
    } catch (e) {
      return {'success': false, 'message': 'Test failed: $e'};
    }
  }
}