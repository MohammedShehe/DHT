import 'package:flutter/material.dart';
import '../models/activity_models.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';
import '../services/activity_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ActivityProvider extends ChangeNotifier {
  List<Meal> _meals = [];
  List<Workout> _workouts = [];
  List<Sleep> _sleep = [];
  List<Hydration> _hydration = [];
  List<Medication> _medications = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  // Cache for different dates
  final Map<String, List<Meal>> _mealsCache = {};
  final Map<String, List<Workout>> _workoutsCache = {};
  final Map<String, List<Sleep>> _sleepCache = {};
  final Map<String, List<Hydration>> _hydrationCache = {};

  List<double> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyWorkoutMinutes = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklySleepHours = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyHydration = [0, 0, 0, 0, 0, 0, 0];

  Function(String message, {bool isError})? onShowMessage;

  List<Meal> get meals => _meals;
  List<Workout> get workouts => _workouts;
  List<Sleep> get sleep => _sleep;
  List<Hydration> get hydration => _hydration;
  List<Medication> get medications => _medications;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<double> get weeklyCalories => _weeklyCalories;
  List<double> get weeklyWorkoutMinutes => _weeklyWorkoutMinutes;
  List<double> get weeklySleepHours => _weeklySleepHours;
  List<double> get weeklyHydration => _weeklyHydration;

  int get totalCalories => _meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  double get totalProtein => _meals.fold(0, (sum, meal) => sum + meal.totalProtein);
  double get totalCarbs => _meals.fold(0, (sum, meal) => sum + meal.totalCarbs);
  double get totalFat => _meals.fold(0, (sum, meal) => sum + meal.totalFat);
  
  int get totalWorkoutMinutes => _workouts.fold(0, (sum, workout) => sum + workout.duration);
  int get totalCaloriesBurned => _workouts.fold(0, (sum, workout) => sum + workout.calories);
  
  double get totalSleepHours => _sleep.fold(0, (sum, sleep) => sum + sleep.duration);

  int get totalWaterIntake => _hydration.fold(0, (sum, entry) => sum + entry.amount);
  int get waterGlasses => (totalWaterIntake / 250).round();

  void setSelectedDate(DateTime date) {
    if (_selectedDate.year == date.year && 
        _selectedDate.month == date.month && 
        _selectedDate.day == date.day) {
      return;
    }
    
    _selectedDate = date;
    _meals = [];
    _workouts = [];
    _sleep = [];
    _hydration = [];
    loadActivityData();
    notifyListeners();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> loadActivityData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dateKey = _getDateKey(_selectedDate);
      
      if (_mealsCache.containsKey(dateKey)) {
        _meals = _mealsCache[dateKey] ?? [];
      } else {
        try {
          _meals = await ActivityService.getMeals(_selectedDate);
          _mealsCache[dateKey] = _meals;
        } catch (e) {
          _meals = [];
          debugPrint('Error loading meals for ${_selectedDate}: $e');
        }
      }
      
      if (_workoutsCache.containsKey(dateKey)) {
        _workouts = _workoutsCache[dateKey] ?? [];
      } else {
        try {
          _workouts = await ActivityService.getWorkouts(_selectedDate);
          _workoutsCache[dateKey] = _workouts;
        } catch (e) {
          _workouts = [];
          debugPrint('Error loading workouts for ${_selectedDate}: $e');
        }
      }
      
      if (_sleepCache.containsKey(dateKey)) {
        _sleep = _sleepCache[dateKey] ?? [];
      } else {
        try {
          _sleep = await ActivityService.getSleep(_selectedDate);
          _sleepCache[dateKey] = _sleep;
        } catch (e) {
          _sleep = [];
          debugPrint('Error loading sleep for ${_selectedDate}: $e');
        }
      }
      
      if (_hydrationCache.containsKey(dateKey)) {
        _hydration = _hydrationCache[dateKey] ?? [];
      } else {
        try {
          _hydration = await ActivityService.getHydration(_selectedDate);
          _hydrationCache[dateKey] = _hydration;
        } catch (e) {
          _hydration = [];
          debugPrint('Error loading hydration for ${_selectedDate}: $e');
        }
      }
      
      await loadMedications();

      await _loadWeeklySummary();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading activity data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedications() async {
    try {
      final loadedMedications = await ActivityService.getMedications();
      debugPrint('📊 ActivityProvider: Loaded ${loadedMedications.length} medications from service');
      _medications = loadedMedications;
    } catch (e) {
      debugPrint('Error loading medications: $e');
      _medications = [];
    }
  }

  Future<void> refreshCurrentDate() async {
    final dateKey = _getDateKey(_selectedDate);
    
    _mealsCache.remove(dateKey);
    _workoutsCache.remove(dateKey);
    _sleepCache.remove(dateKey);
    _hydrationCache.remove(dateKey);
    
    await loadActivityData();
    
    _showMessage('Data refreshed for ${_formatDate(_selectedDate)}');
  }

  Future<void> refreshAllData() async {
    _isLoading = true;
    notifyListeners();
    
    _mealsCache.clear();
    _workoutsCache.clear();
    _sleepCache.clear();
    _hydrationCache.clear();
    
    await loadActivityData();
    
    _showMessage('All data refreshed');
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _loadWeeklySummary() async {
    try {
      final startDate = _selectedDate.subtract(const Duration(days: 6));
      final summary = await ActivityService.getWeeklySummary(startDate);
      
      if (summary.isNotEmpty) {
        _weeklyCalories = List<double>.from(summary['calories'] ?? [0, 0, 0, 0, 0, 0, 0]);
        _weeklyWorkoutMinutes = List<double>.from(summary['workout_minutes'] ?? [0, 0, 0, 0, 0, 0, 0]);
        _weeklySleepHours = List<double>.from(summary['sleep_hours'] ?? [0, 0, 0, 0, 0, 0, 0]);
        _weeklyHydration = List<double>.from(summary['hydration'] ?? [0, 0, 0, 0, 0, 0, 0]);
      }
    } catch (e) {
      _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
      _weeklyWorkoutMinutes = [0, 0, 0, 0, 0, 0, 0];
      _weeklySleepHours = [0, 0, 0, 0, 0, 0, 0];
      _weeklyHydration = [0, 0, 0, 0, 0, 0, 0];
      debugPrint('Error loading weekly summary: $e');
    }
  }

  Future<void> addMeal(CreateMealRequest request) async {
    try {
      final result = await ActivityService.saveMeal(request);
      if (result['success']) {
        final mealDate = DateTime(
          request.mealTime.year,
          request.mealTime.month,
          request.mealTime.day
        );
        final dateKey = _getDateKey(mealDate);
        _mealsCache.remove(dateKey);
        
        if (mealDate.year == _selectedDate.year &&
            mealDate.month == _selectedDate.month &&
            mealDate.day == _selectedDate.day) {
          await loadActivityData();
        }
        
        _showMessage(result['message'] ?? 'Meal added successfully');
      } else {
        _showMessage(result['message'] ?? 'Error adding meal', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error adding meal: $e', isError: true);
    }
  }

  Future<void> updateMeal(int mealId, UpdateMealRequest request) async {
    try {
      final result = await ActivityService.updateMeal(mealId, request);
      if (result['success']) {
        _mealsCache.remove(_getDateKey(_selectedDate));
        await loadActivityData();
        _showMessage(result['message'] ?? 'Meal updated successfully');
      } else {
        _showMessage(result['message'] ?? 'Error updating meal', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error updating meal: $e', isError: true);
    }
  }

  Future<void> deleteMeal(int mealId) async {
    try {
      final result = await ActivityService.deleteMeal(mealId);
      if (result['success']) {
        _mealsCache.remove(_getDateKey(_selectedDate));
        await loadActivityData();
        _showMessage(result['message'] ?? 'Meal deleted successfully');
      } else {
        _showMessage(result['message'] ?? 'Error deleting meal', isError: true);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error deleting meal: $e', isError: true);
    }
  }

  Future<void> addWorkout(Workout workout) async {
    try {
      await ActivityService.saveWorkout(workout);
      
      final workoutDate = workout.time.isNotEmpty 
          ? DateTime.now()
          : _selectedDate;
      
      final dateKey = _getDateKey(workoutDate);
      _workoutsCache.remove(dateKey);
      
      if (workoutDate.year == _selectedDate.year &&
          workoutDate.month == _selectedDate.month &&
          workoutDate.day == _selectedDate.day) {
        await loadActivityData();
      }
      
      _showMessage('Workout added successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error adding workout: $e', isError: true);
    }
  }

  Future<void> updateWorkout(Workout workout) async {
    try {
      await ActivityService.updateWorkout(workout);
      _workoutsCache.remove(_getDateKey(_selectedDate));
      await loadActivityData();
      _showMessage('Workout updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error updating workout: $e', isError: true);
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await ActivityService.deleteWorkout(workoutId);
      _workoutsCache.remove(_getDateKey(_selectedDate));
      await loadActivityData();
      _showMessage('Workout deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error deleting workout: $e', isError: true);
    }
  }

  Future<void> addSleep(Sleep sleep) async {
    try {
      await ActivityService.saveSleep(sleep);
      _sleepCache.remove(_getDateKey(sleep.date));
      
      if (sleep.date.year == _selectedDate.year &&
          sleep.date.month == _selectedDate.month &&
          sleep.date.day == _selectedDate.day) {
        await loadActivityData();
      }
      
      _showMessage('Sleep logged successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error adding sleep: $e', isError: true);
    }
  }

  Future<void> updateSleep(Sleep sleep) async {
    try {
      await ActivityService.updateSleep(sleep);
      _sleepCache.remove(_getDateKey(_selectedDate));
      await loadActivityData();
      _showMessage('Sleep updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error updating sleep: $e', isError: true);
    }
  }

  Future<void> deleteSleep(String sleepId) async {
    try {
      await ActivityService.deleteSleep(sleepId);
      _sleepCache.remove(_getDateKey(_selectedDate));
      await loadActivityData();
      _showMessage('Sleep deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error deleting sleep: $e', isError: true);
    }
  }

  Future<void> addHydration(Hydration hydration) async {
    try {
      await ActivityService.saveHydration(hydration);
      
      final hydrationDate = DateTime(
        hydration.time.year,
        hydration.time.month,
        hydration.time.day
      );
      final dateKey = _getDateKey(hydrationDate);
      _hydrationCache.remove(dateKey);
      
      if (hydrationDate.year == _selectedDate.year &&
          hydrationDate.month == _selectedDate.month &&
          hydrationDate.day == _selectedDate.day) {
        await loadActivityData();
      }
      
      _showMessage('Hydration added successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error adding hydration: $e', isError: true);
    }
  }

  Future<void> updateHydration(Hydration hydration) async {
    try {
      await ActivityService.updateHydration(hydration);
      _hydrationCache.remove(_getDateKey(_selectedDate));
      await loadActivityData();
      _showMessage('Hydration updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error updating hydration: $e', isError: true);
    }
  }

  Future<void> deleteHydration(String hydrationId) async {
    try {
      await ActivityService.deleteHydration(hydrationId);
      _hydrationCache.remove(_getDateKey(_selectedDate));
      await loadActivityData();
      _showMessage('Hydration deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      _showMessage('Error deleting hydration: $e', isError: true);
    }
  }

  // ==================== MEDICATION METHODS ====================

  Future<void> addMedication(Map<String, dynamic> medicationData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ActivityService.createMedication(medicationData);
      
      if (result['success']) {
        await loadMedications();
        _showMessage(result['message']);
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error adding medication: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createMedication(Map<String, dynamic> medicationData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ActivityService.createMedication(medicationData);
      
      if (result['success']) {
        await loadMedications();
        _showMessage(result['message']);
        return result;
      } else {
        _showMessage(result['message'], isError: true);
        return result;
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error adding medication: $e', isError: true);
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateMedication(int medicationId, Map<String, dynamic> medicationData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ActivityService.updateMedication(medicationId, medicationData);
      
      if (result['success']) {
        await loadMedications();
        _showMessage(result['message']);
        return result;
      } else {
        _showMessage(result['message'], isError: true);
        return result;
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error updating medication: $e', isError: true);
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> deleteMedication(int medicationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ActivityService.deleteMedication(medicationId);
      
      if (result['success']) {
        await loadMedications();
        _showMessage(result['message']);
        return result;
      } else {
        _showMessage(result['message'], isError: true);
        return result;
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error deleting medication: $e', isError: true);
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ADD SCHEDULE METHOD
  Future<Map<String, dynamic>> addSchedule(int medicationId, Map<String, dynamic> scheduleData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await ActivityService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ActivityService.baseUrl}/medications/$medicationId/schedules'),
        headers: headers,
        body: json.encode(scheduleData),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadMedications();
        _showMessage(data['message'] ?? 'Schedule added successfully');
        return {'success': true, 'message': data['message'] ?? 'Schedule added successfully'};
      } else {
        _showMessage(data['message'] ?? 'Failed to add schedule', isError: true);
        return {'success': false, 'message': data['message'] ?? 'Failed to add schedule'};
      }
    } catch (e) {
      _showMessage('Error adding schedule: $e', isError: true);
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // DELETE SCHEDULE METHOD
  Future<Map<String, dynamic>> deleteSchedule(int medicationId, int scheduleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await ActivityService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${ActivityService.baseUrl}/medications/$medicationId/schedules/$scheduleId'),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        await loadMedications();
        _showMessage(data['message'] ?? 'Schedule deleted successfully');
        return {'success': true, 'message': data['message'] ?? 'Schedule deleted successfully'};
      } else {
        _showMessage(data['message'] ?? 'Failed to delete schedule', isError: true);
        return {'success': false, 'message': data['message'] ?? 'Failed to delete schedule'};
      }
    } catch (e) {
      _showMessage('Error deleting schedule: $e', isError: true);
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> logMedicationIntake({
    required int medicationId,
    int? scheduleId,
    required DateTime logDate,
    required TimeOfDay logTime,
    String status = 'taken',
    TimeOfDay? actualTime,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final logDateStr = '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';
      final logTimeStr = '${logTime.hour.toString().padLeft(2, '0')}:${logTime.minute.toString().padLeft(2, '0')}:00';
      final actualTimeStr = actualTime != null 
          ? '${actualTime.hour.toString().padLeft(2, '0')}:${actualTime.minute.toString().padLeft(2, '0')}:00'
          : null;
      
      final result = await ActivityService.logMedicationIntake(
        medicationId: medicationId,
        scheduleId: scheduleId,
        logDate: logDateStr,
        logTime: logTimeStr,
        status: status,
        actualTime: actualTimeStr,
        notes: notes,
      );
      
      if (result['success']) {
        await loadMedications();
        _showMessage(result['message']);
        return result;
      } else {
        _showMessage(result['message'], isError: true);
        return result;
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error logging medication: $e', isError: true);
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateMedicationLogStatus(int logId, String status, {TimeOfDay? actualTime}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final actualTimeStr = actualTime != null 
          ? '${actualTime.hour.toString().padLeft(2, '0')}:${actualTime.minute.toString().padLeft(2, '0')}:00'
          : null;
      
      final result = await ActivityService.updateMedicationLogStatus(logId, status, actualTime: actualTimeStr);
      
      if (result['success']) {
        await loadMedications();
        _showMessage(result['message']);
        return result;
      } else {
        _showMessage(result['message'], isError: true);
        return result;
      }
    } catch (e) {
      _error = e.toString();
      _showMessage('Error updating log status: $e', isError: true);
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getMedicationLogsForDate(DateTime date) async {
    try {
      final result = await ActivityService.getMedicationLogsByDate(date);
      if (result['success']) {
        return {'success': true, 'logs': result['logs']};
      }
      return {'success': false, 'logs': []};
    } catch (e) {
      debugPrint('Error getting medication logs: $e');
      return {'success': false, 'logs': []};
    }
  }

  Future<Map<String, dynamic>> getMedicationDailySummary(DateTime date) async {
    try {
      final result = await ActivityService.getMedicationDailySummary(date);
      if (result['success']) {
        return {'success': true, 'summary': result['summary']};
      }
      return {'success': false, 'summary': null};
    } catch (e) {
      debugPrint('Error getting daily summary: $e');
      return {'success': false, 'summary': null};
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingMedicationDoses() async {
    try {
      return await ActivityService.getUpcomingMedicationDoses();
    } catch (e) {
      debugPrint('Error getting upcoming doses: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMissedMedicationDoses(DateTime date) async {
    try {
      return await ActivityService.getMissedMedicationDoses(date);
    } catch (e) {
      debugPrint('Error getting missed doses: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getMedicationAdherenceRate(int medicationId, DateTime startDate, DateTime endDate) async {
    try {
      return await ActivityService.getMedicationAdherenceRate(medicationId, startDate, endDate);
    } catch (e) {
      debugPrint('Error getting adherence rate: $e');
      return {'success': false, 'message': 'Error: $e', 'adherence': null};
    }
  }

  // Get medications for a specific date
  List<Medication> getMedicationsForDate(DateTime date) {
    return _medications.where((med) {
      if (med.startDate.isAfter(date)) return false;
      if (med.endDate != null && med.endDate!.isBefore(date)) return false;
      return med.isActive;
    }).toList();
  }

  // Get medications for a specific date with proper dose calculation
  List<Map<String, dynamic>> getMedicationsForDateWithDoses(DateTime date) {
    final activeMedications = getMedicationsForDate(date);
    final result = <Map<String, dynamic>>[];
    
    for (var med in activeMedications) {
      final doses = med.getTodaysDoses(date);
      if (doses.isNotEmpty) {
        result.add({
          'medication': med,
          'doses': doses,
        });
      }
    }
    
    return result;
  }

  // Get today's adherence percentage
  double getTodaysAdherence() {
    final today = DateTime.now();
    final medicationsWithDoses = getMedicationsForDateWithDoses(today);
    
    int totalDoses = 0;
    int takenDoses = 0;
    
    for (var item in medicationsWithDoses) {
      final doses = item['doses'] as List<MedicationDose>;
      for (var dose in doses) {
        totalDoses++;
        if (dose.isTaken) {
          takenDoses++;
        }
      }
    }
    
    if (totalDoses == 0) return 100.0;
    return (takenDoses / totalDoses) * 100;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  void disposeCallbacks() {
    onShowMessage = null;
  }
}