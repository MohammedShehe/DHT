import 'package:flutter/material.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';

class ActivityProvider extends ChangeNotifier {
  List<Meal> _meals = [];
  List<Workout> _workouts = [];
  List<Sleep> _sleep = [];
  List<Hydration> _hydration = [];
  List<Medication> _medications = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  // Callback for showing messages (to be set from UI)
  Function(String message, {bool isError})? onShowMessage;

  // Getters
  List<Meal> get meals => _meals;
  List<Workout> get workouts => _workouts;
  List<Sleep> get sleep => _sleep;
  List<Hydration> get hydration => _hydration;
  List<Medication> get medications => _medications;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Nutrition summary
  int get totalCalories => _meals.fold(0, (sum, meal) => sum + meal.calories);
  double get totalProtein => _meals.fold(0, (sum, meal) => sum + (meal.protein ?? 0));
  double get totalCarbs => _meals.fold(0, (sum, meal) => sum + (meal.carbs ?? 0));
  double get totalFat => _meals.fold(0, (sum, meal) => sum + (meal.fat ?? 0));
  
  // Workout summary
  int get totalWorkoutMinutes => _workouts.fold(0, (sum, workout) => sum + workout.duration);
  int get totalCaloriesBurned => _workouts.fold(0, (sum, workout) => sum + workout.calories);
  
  // Sleep summary
  double get totalSleepHours => _sleep.fold(0, (sum, sleep) => sum + sleep.duration);

  // Hydration summary
  int get totalWaterIntake => _hydration.fold(0, (sum, entry) => sum + entry.amount);
  int get waterGlasses => (totalWaterIntake / 250).round(); // Standard glass = 250ml

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadActivityData();
    notifyListeners();
  }

  Future<void> loadActivityData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load data from service with individual error handling
      try {
        _meals = await ActivityService.getMeals(_selectedDate);
      } catch (e) {
        debugPrint('Error loading meals: $e');
        _meals = [];
      }
      
      try {
        _workouts = await ActivityService.getWorkouts(_selectedDate);
      } catch (e) {
        debugPrint('Error loading workouts: $e');
        _workouts = [];
      }
      
      try {
        _sleep = await ActivityService.getSleep(_selectedDate);
      } catch (e) {
        debugPrint('Error loading sleep: $e');
        _sleep = [];
      }
      
      try {
        _hydration = await ActivityService.getHydration(_selectedDate);
      } catch (e) {
        debugPrint('Error loading hydration: $e');
        _hydration = [];
      }
      
      try {
        _medications = await ActivityService.getMedications();
        // Filter out invalid medications
        _medications = _medications.where((med) {
          return med.scheduledTimes.isNotEmpty;
        }).toList();
      } catch (e) {
        debugPrint('Error loading medications: $e');
        _medications = [];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading activity data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(Meal meal) async {
    try {
      await ActivityService.saveMeal(meal);
      await loadActivityData();
      _showMessage('Meal added successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding meal: $e');
      _showMessage('Error adding meal: $e', isError: true);
    }
  }

  Future<void> updateMeal(Meal meal) async {
    try {
      await ActivityService.updateMeal(meal);
      await loadActivityData();
      _showMessage('Meal updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating meal: $e');
      _showMessage('Error updating meal: $e', isError: true);
    }
  }

  Future<void> deleteMeal(String mealId) async {
    try {
      await ActivityService.deleteMeal(mealId);
      await loadActivityData();
      _showMessage('Meal deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error deleting meal: $e');
      _showMessage('Error deleting meal: $e', isError: true);
    }
  }

  Future<void> addWorkout(Workout workout) async {
    try {
      await ActivityService.saveWorkout(workout);
      await loadActivityData();
      _showMessage('Workout added successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding workout: $e');
      _showMessage('Error adding workout: $e', isError: true);
    }
  }

  Future<void> updateWorkout(Workout workout) async {
    try {
      await ActivityService.updateWorkout(workout);
      await loadActivityData();
      _showMessage('Workout updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating workout: $e');
      _showMessage('Error updating workout: $e', isError: true);
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await ActivityService.deleteWorkout(workoutId);
      await loadActivityData();
      _showMessage('Workout deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error deleting workout: $e');
      _showMessage('Error deleting workout: $e', isError: true);
    }
  }

  Future<void> addSleep(Sleep sleep) async {
    try {
      await ActivityService.saveSleep(sleep);
      await loadActivityData();
      _showMessage('Sleep logged successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding sleep: $e');
      _showMessage('Error adding sleep: $e', isError: true);
    }
  }

  Future<void> updateSleep(Sleep sleep) async {
    try {
      await ActivityService.updateSleep(sleep);
      await loadActivityData();
      _showMessage('Sleep updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating sleep: $e');
      _showMessage('Error updating sleep: $e', isError: true);
    }
  }

  Future<void> deleteSleep(String sleepId) async {
    try {
      await ActivityService.deleteSleep(sleepId);
      await loadActivityData();
      _showMessage('Sleep deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error deleting sleep: $e');
      _showMessage('Error deleting sleep: $e', isError: true);
    }
  }

  // Hydration methods
  Future<void> addHydration(Hydration hydration) async {
    try {
      await ActivityService.saveHydration(hydration);
      await loadActivityData();
      _showMessage('Hydration added successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding hydration: $e');
      _showMessage('Error adding hydration: $e', isError: true);
    }
  }

  Future<void> updateHydration(Hydration hydration) async {
    try {
      await ActivityService.updateHydration(hydration);
      await loadActivityData();
      _showMessage('Hydration updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating hydration: $e');
      _showMessage('Error updating hydration: $e', isError: true);
    }
  }

  Future<void> deleteHydration(String hydrationId) async {
    try {
      await ActivityService.deleteHydration(hydrationId);
      await loadActivityData();
      _showMessage('Hydration deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error deleting hydration: $e');
      _showMessage('Error deleting hydration: $e', isError: true);
    }
  }

  // Medication methods with improved error handling
  Future<void> addMedication(dynamic medicationData) async {
    try {
      Medication medication;
      
      if (medicationData is Map<String, dynamic>) {
        // Ensure required fields exist
        if (!medicationData.containsKey('scheduled_times')) {
          medicationData['scheduled_times'] = [];
        }
        if (!medicationData.containsKey('taken')) {
          medicationData['taken'] = [];
        }
        if (!medicationData.containsKey('id')) {
          medicationData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        }
        
        medication = Medication.fromJson(medicationData);
      } else if (medicationData is Medication) {
        medication = medicationData;
      } else {
        throw Exception('Invalid medication data type');
      }
      
      await ActivityService.saveMedication(medication);
      await loadActivityData();
      _showMessage('${medication.name} added successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding medication: $e');
      _showMessage('Error adding medication: $e', isError: true);
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await ActivityService.updateMedication(medication);
      await loadActivityData();
      _showMessage('${medication.name} updated successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating medication: $e');
      _showMessage('Error updating medication: $e', isError: true);
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await ActivityService.deleteMedication(medicationId);
      await loadActivityData();
      _showMessage('Medication deleted successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error deleting medication: $e');
      _showMessage('Error deleting medication: $e', isError: true);
    }
  }

  Future<void> markMedicationTaken(String medicationId, int timeIndex, bool taken) async {
    try {
      await ActivityService.markMedicationTaken(medicationId, timeIndex, taken);
      await loadActivityData();
      _showMessage(taken ? 'Medication marked as taken' : 'Medication marked as not taken');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error marking medication taken: $e');
      _showMessage('Error updating medication status: $e', isError: true);
    }
  }

  // Helper method to show messages via callback
  void _showMessage(String message, {bool isError = false}) {
    if (onShowMessage != null) {
      onShowMessage!(message, isError: isError);
    }
  }

  // Helper method to get medications for a specific date
  List<Medication> getMedicationsForDate(DateTime date) {
    try {
      return _medications.where((med) {
        // Check if medication is active on this date
        if (med.startDate.isAfter(date)) return false;
        if (med.endDate != null && med.endDate!.isBefore(date)) return false;
        
        // Check if there are scheduled times for this date
        return med.scheduledTimes.any((time) {
          return time.year == date.year &&
                 time.month == date.month &&
                 time.day == date.day;
        });
      }).toList();
    } catch (e) {
      debugPrint('Error filtering medications for date: $e');
      return [];
    }
  }

  // Helper method to get today's adherence
  double getTodaysAdherence() {
    try {
      final today = DateTime.now();
      final todaysMeds = getMedicationsForDate(today);
      
      if (todaysMeds.isEmpty) return 100.0;
      
      int totalDoses = 0;
      int takenDoses = 0;
      
      for (var med in todaysMeds) {
        for (int i = 0; i < med.scheduledTimes.length; i++) {
          final time = med.scheduledTimes[i];
          if (time.year == today.year &&
              time.month == today.month &&
              time.day == today.day) {
            totalDoses++;
            if (i < med.taken.length && med.taken[i]) {
              takenDoses++;
            }
          }
        }
      }
      
      if (totalDoses == 0) return 100.0;
      return (takenDoses / totalDoses) * 100;
    } catch (e) {
      debugPrint('Error calculating adherence: $e');
      return 0.0;
    }
  }
}