import 'package:flutter/material.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';

class ActivityProvider extends ChangeNotifier {
  List<Meal> _meals = [];
  List<Workout> _workouts = [];
  List<Sleep> _sleep = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Meal> get meals => _meals;
  List<Workout> get workouts => _workouts;
  List<Sleep> get sleep => _sleep;
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
      // Load data from service
      _meals = await ActivityService.getMeals(_selectedDate);
      _workouts = await ActivityService.getWorkouts(_selectedDate);
      _sleep = await ActivityService.getSleep(_selectedDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(Meal meal) async {
    try {
      await ActivityService.saveMeal(meal);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateMeal(Meal meal) async {
    try {
      await ActivityService.updateMeal(meal);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMeal(String mealId) async {
    try {
      await ActivityService.deleteMeal(mealId);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addWorkout(Workout workout) async {
    try {
      await ActivityService.saveWorkout(workout);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateWorkout(Workout workout) async {
    try {
      await ActivityService.updateWorkout(workout);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await ActivityService.deleteWorkout(workoutId);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addSleep(Sleep sleep) async {
    try {
      await ActivityService.saveSleep(sleep);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateSleep(Sleep sleep) async {
    try {
      await ActivityService.updateSleep(sleep);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSleep(String sleepId) async {
    try {
      await ActivityService.deleteSleep(sleepId);
      await loadActivityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}