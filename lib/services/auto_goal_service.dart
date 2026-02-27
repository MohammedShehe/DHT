import 'dart:math';
import '../models/health_profile_model.dart';
import '../models/gamification_models.dart';
import 'goal_service.dart';

class AutoGoalService {
  // Calculate recommended daily steps based on health profile
  static int calculateRecommendedSteps(HealthProfileModel profile) {
    // Base steps
    int baseSteps = 5000;
    
    // Adjust based on age
    if (profile.age != null) {
      if (profile.age! < 30) {
        baseSteps += 2000;
      } else if (profile.age! < 50) {
        baseSteps += 1000;
      } else if (profile.age! > 65) {
        baseSteps -= 1000;
      }
    }
    
    // Adjust based on activity level
    if (profile.activityLevel != null) {
      switch (profile.activityLevel!.toLowerCase()) {
        case 'sedentary':
          baseSteps = (baseSteps * 0.7).round();
          break;
        case 'lightly active':
          baseSteps = (baseSteps * 0.85).round();
          break;
        case 'moderate':
          // Keep as is
          break;
        case 'very active':
          baseSteps = (baseSteps * 1.15).round();
          break;
        case 'extremely active':
          baseSteps = (baseSteps * 1.3).round();
          break;
      }
    }
    
    // Adjust based on health goal
    if (profile.healthGoal != null) {
      if (profile.healthGoal!.toLowerCase().contains('lose weight')) {
        baseSteps = (baseSteps * 1.2).round(); // Increase steps for weight loss
      } else if (profile.healthGoal!.toLowerCase().contains('gain muscle')) {
        baseSteps = (baseSteps * 1.1).round(); // Slight increase for muscle gain
      }
    }
    
    // Ensure reasonable range
    return baseSteps.clamp(3000, 20000);
  }

  // Calculate recommended water intake (glasses) based on health profile
  static int calculateRecommendedWater(HealthProfileModel profile) {
    // Base: 8 glasses per day
    double baseGlasses = 8.0;
    
    // Adjust based on weight (more weight = more water)
    if (profile.weight != null) {
      // Rough formula: weight in kg / 30 = liters per day, convert to glasses (250ml)
      double liters = profile.weight! / 30;
      double glasses = liters * 4; // 4 glasses per liter
      baseGlasses = glasses;
    }
    
    // Adjust based on activity level
    if (profile.activityLevel != null) {
      switch (profile.activityLevel!.toLowerCase()) {
        case 'sedentary':
          baseGlasses *= 1.0;
          break;
        case 'lightly active':
          baseGlasses *= 1.1;
          break;
        case 'moderate':
          baseGlasses *= 1.2;
          break;
        case 'very active':
          baseGlasses *= 1.3;
          break;
        case 'extremely active':
          baseGlasses *= 1.4;
          break;
      }
    }
    
    // Adjust for health conditions
    if (profile.hasDiabetes || profile.hasHypertension) {
      baseGlasses *= 1.1; // Slight increase for these conditions
    }
    
    // Round to nearest whole number
    return baseGlasses.round().clamp(4, 15);
  }

  // Calculate recommended sleep hours based on health profile
  static double calculateRecommendedSleep(HealthProfileModel profile) {
    // Base: 8 hours
    double baseHours = 8.0;
    
    // Adjust based on age
    if (profile.age != null) {
      if (profile.age! < 18) {
        baseHours = 9.0;
      } else if (profile.age! < 30) {
        baseHours = 8.0;
      } else if (profile.age! < 50) {
        baseHours = 7.5;
      } else if (profile.age! > 65) {
        baseHours = 7.5;
      }
    }
    
    // Adjust based on activity level
    if (profile.activityLevel != null) {
      if (profile.activityLevel!.toLowerCase().contains('very') || 
          profile.activityLevel!.toLowerCase().contains('extremely')) {
        baseHours += 0.5; // Active people need more recovery
      }
    }
    
    // Adjust based on health conditions
    if (profile.hasHeartCondition) {
      baseHours += 0.5;
    }
    
    return baseHours;
  }

  // Calculate recommended meditation minutes based on health profile
  static int calculateRecommendedMeditation(HealthProfileModel profile) {
    // Base: 5 minutes
    int baseMinutes = 5;
    
    // Adjust based on health conditions (stress-related)
    if (profile.hasHypertension || profile.hasHeartCondition) {
      baseMinutes = 10;
    }
    
    // Adjust based on health goal
    if (profile.healthGoal != null) {
      if (profile.healthGoal!.toLowerCase().contains('stress') ||
          profile.healthGoal!.toLowerCase().contains('mindfulness')) {
        baseMinutes = 10;
      } else if (profile.healthGoal!.toLowerCase().contains('improve fitness')) {
        baseMinutes = 5;
      }
    }
    
    return baseMinutes;
  }

  // Calculate recommended weekly workouts based on health profile
  static int calculateRecommendedWorkouts(HealthProfileModel profile) {
    // Base: 3 workouts per week
    int baseWorkouts = 3;
    
    // Adjust based on activity level
    if (profile.activityLevel != null) {
      switch (profile.activityLevel!.toLowerCase()) {
        case 'sedentary':
          baseWorkouts = 2;
          break;
        case 'lightly active':
          baseWorkouts = 3;
          break;
        case 'moderate':
          baseWorkouts = 4;
          break;
        case 'very active':
          baseWorkouts = 5;
          break;
        case 'extremely active':
          baseWorkouts = 6;
          break;
      }
    }
    
    // Adjust based on health goal
    if (profile.healthGoal != null) {
      if (profile.healthGoal!.toLowerCase().contains('lose weight')) {
        baseWorkouts += 1;
      } else if (profile.healthGoal!.toLowerCase().contains('gain muscle')) {
        baseWorkouts += 1;
      } else if (profile.healthGoal!.toLowerCase().contains('improve fitness')) {
        baseWorkouts += 0;
      }
    }
    
    // Adjust for health conditions (safety)
    if (profile.hasHeartCondition) {
      baseWorkouts = min(baseWorkouts, 3); // Limit for heart conditions
    }
    
    return baseWorkouts.clamp(1, 7);
  }

  // Calculate recommended monthly calories based on health profile
  static int calculateRecommendedCalories(HealthProfileModel profile) {
    // Base: 2000 calories per day * 30 = 60000 per month
    int dailyCalories = 2000;
    
    // Calculate BMR (Mifflin-St Jeor Equation)
    if (profile.age != null && profile.weight != null && profile.height != null && profile.gender != null) {
      double bmr;
      if (profile.gender!.toLowerCase() == 'male') {
        bmr = (10 * profile.weight!) + (6.25 * profile.height!) - (5 * profile.age!) + 5;
      } else {
        bmr = (10 * profile.weight!) + (6.25 * profile.height!) - (5 * profile.age!) - 161;
      }
      
      // Apply activity factor
      if (profile.activityLevel != null) {
        switch (profile.activityLevel!.toLowerCase()) {
          case 'sedentary':
            bmr *= 1.2;
            break;
          case 'lightly active':
            bmr *= 1.375;
            break;
          case 'moderate':
            bmr *= 1.55;
            break;
          case 'very active':
            bmr *= 1.725;
            break;
          case 'extremely active':
            bmr *= 1.9;
            break;
          default:
            bmr *= 1.55;
        }
      }
      
      dailyCalories = bmr.round();
    }
    
    // Adjust based on health goal
    if (profile.healthGoal != null) {
      if (profile.healthGoal!.toLowerCase().contains('lose weight')) {
        dailyCalories = (dailyCalories * 0.85).round(); // 15% deficit
      } else if (profile.healthGoal!.toLowerCase().contains('gain muscle')) {
        dailyCalories = (dailyCalories * 1.1).round(); // 10% surplus
      }
    }
    
    // Return monthly total
    return dailyCalories * 30;
  }

  // Set all recommended goals based on health profile
  static Future<void> setRecommendedGoals(HealthProfileModel profile) async {
    try {
      // Steps goal (daily)
      int stepsTarget = calculateRecommendedSteps(profile);
      await GoalService.createGoal(
        type: GoalType.steps,
        targetValue: stepsTarget.toDouble(),
        period: GoalPeriod.daily,
        tags: ['auto-generated', 'fitness'],
        category: 'wellness',
      );
      
      // Water goal (daily)
      int waterTarget = calculateRecommendedWater(profile);
      await GoalService.createGoal(
        type: GoalType.water,
        targetValue: waterTarget.toDouble(),
        period: GoalPeriod.daily,
        tags: ['auto-generated', 'hydration'],
        category: 'wellness',
      );
      
      // Sleep goal (daily)
      double sleepTarget = calculateRecommendedSleep(profile);
      await GoalService.createGoal(
        type: GoalType.sleep,
        targetValue: sleepTarget,
        period: GoalPeriod.daily,
        tags: ['auto-generated', 'rest'],
        category: 'wellness',
      );
      
      // Meditation goal (daily)
      int meditationTarget = calculateRecommendedMeditation(profile);
      await GoalService.createGoal(
        type: GoalType.meditation,
        targetValue: meditationTarget.toDouble(),
        period: GoalPeriod.daily,
        tags: ['auto-generated', 'mindfulness'],
        category: 'mindfulness',
      );
      
      // Workouts goal (weekly)
      int workoutsTarget = calculateRecommendedWorkouts(profile);
      await GoalService.createGoal(
        type: GoalType.workouts,
        targetValue: workoutsTarget.toDouble(),
        period: GoalPeriod.weekly,
        tags: ['auto-generated', 'fitness'],
        category: 'fitness',
      );
      
      // Calories goal (monthly)
      int caloriesTarget = calculateRecommendedCalories(profile);
      await GoalService.createGoal(
        type: GoalType.calories,
        targetValue: caloriesTarget.toDouble(),
        period: GoalPeriod.monthly,
        tags: ['auto-generated', 'nutrition'],
        category: 'nutrition',
      );
      
      print('✅ Auto goals set successfully based on health profile');
    } catch (e) {
      print('❌ Error setting auto goals: $e');
    }
  }
}