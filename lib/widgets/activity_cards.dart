// lib/widgets/activity_cards.dart
import 'package:flutter/material.dart';
import '../models/activity_models.dart';
import '../models/meal_models.dart';

class ActivityCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  factory ActivityCard.meal({
    required Meal meal,
    required VoidCallback onTap,
  }) {
    return ActivityCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getMealColor(meal.mealType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getMealIcon(meal.mealType),
              color: _getMealColor(meal.mealType),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.totalCalories} kcal • ${meal.formattedTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meal.itemsSummary,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  factory ActivityCard.workout({
    required Workout workout,
    required VoidCallback onTap,
  }) {
    Color intensityColor;
    switch (workout.intensity.toLowerCase()) {
      case 'high':
        intensityColor = Colors.red;
        break;
      case 'moderate':
        intensityColor = Colors.orange;
        break;
      case 'low':
        intensityColor = Colors.green;
        break;
      default:
        intensityColor = Colors.blue;
    }

    return ActivityCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: intensityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: intensityColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${workout.duration} min • ${workout.calories} kcal • ${workout.time}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: intensityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workout.intensity,
                    style: TextStyle(
                      fontSize: 10,
                      color: intensityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  factory ActivityCard.sleep({
    required Sleep sleep,
    required VoidCallback onTap,
  }) {
    return ActivityCard(
      onTap: onTap,
      child: SleepCardContent(sleep: sleep),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

// Helper functions for meal colors and icons
Color _getMealColor(String mealType) {
  switch (mealType.toLowerCase()) {
    case 'breakfast':
      return Colors.orange;
    case 'lunch':
      return Colors.green;
    case 'dinner':
      return Colors.purple;
    case 'snack':
      return Colors.pink;
    case 'brunch':
      return Colors.teal;
    default:
      return Colors.blue;
  }
}

IconData _getMealIcon(String mealType) {
  switch (mealType.toLowerCase()) {
    case 'breakfast':
      return Icons.breakfast_dining;
    case 'lunch':
      return Icons.lunch_dining;
    case 'dinner':
      return Icons.dinner_dining;
    case 'snack':
      return Icons.cookie;
    case 'brunch':
      return Icons.brunch_dining;
    default:
      return Icons.restaurant;
  }
}

// Separate widget for sleep card content that has access to context
class SleepCardContent extends StatelessWidget {
  final Sleep sleep;

  const SleepCardContent({super.key, required this.sleep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bedtime, color: Colors.purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sleep · ${sleep.duration.toStringAsFixed(1)}h',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${sleep.bedTime.format(context)} - ${sleep.wakeTime.format(context)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sleep.quality,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sleep.interruptions} interruptions',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );
  }
}