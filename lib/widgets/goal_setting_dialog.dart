import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gamification_models.dart';
import '../services/goal_service.dart';

class GoalSettingDialog extends StatefulWidget {
  final Goal? existingGoal;
  final GoalTemplate? template; 
  final Function(Goal)? onGoalCreated;

  const GoalSettingDialog({super.key, this.existingGoal, this.template, this.onGoalCreated});

  @override
  State<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<GoalSettingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  
  GoalType _selectedType = GoalType.steps;
  GoalPeriod _selectedPeriod = GoalPeriod.daily;
  bool _isLoading = false;

  // Fixed periods based on backend requirements
  static const Map<GoalType, GoalPeriod> _fixedPeriods = {
    GoalType.steps: GoalPeriod.daily,
    GoalType.water: GoalPeriod.daily,
    GoalType.sleep: GoalPeriod.daily,
    GoalType.meditation: GoalPeriod.daily,
    GoalType.workouts: GoalPeriod.weekly,
    GoalType.calories: GoalPeriod.monthly,
  };

  final Map<GoalType, String> _typeTitles = {
    GoalType.steps: 'Steps',
    GoalType.water: 'Water Glasses',
    GoalType.sleep: 'Sleep Hours',
    GoalType.meditation: 'Meditation Minutes',
    GoalType.workouts: 'Workouts',
    GoalType.calories: 'Calories',
  };

  final Map<GoalType, String> _typeUnits = {
    GoalType.steps: 'steps',
    GoalType.water: 'glasses',
    GoalType.sleep: 'hours',
    GoalType.meditation: 'minutes',
    GoalType.workouts: 'workouts',
    GoalType.calories: 'kcal',
  };

  final Map<GoalPeriod, String> _periodTitles = {
    GoalPeriod.daily: 'Daily',
    GoalPeriod.weekly: 'Weekly',
    GoalPeriod.monthly: 'Monthly',
  };

  final Map<GoalType, double> _suggestedTargets = {
    GoalType.steps: 10000,
    GoalType.water: 8,
    GoalType.sleep: 8,
    GoalType.meditation: 10,
    GoalType.workouts: 5,
    GoalType.calories: 50000,
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      _loadExistingGoal();
    } else if (widget.template != null) {
      _loadFromTemplate();
    } else {
      _updateTargetSuggestion();
    }
  }

  void _loadFromTemplate() {
    final template = widget.template!;
    setState(() {
      _selectedType = template.type;
      // Force fixed period based on type
      _selectedPeriod = _getFixedPeriod(template.type);
      _targetController.text = template.defaultTarget.toString();
    });
  }

  void _loadExistingGoal() {
    final goal = widget.existingGoal!;
    setState(() {
      _targetController.text = goal.targetValue.toString();
      _selectedType = goal.type;
      // Force fixed period based on type, ignore any saved period that doesn't match
      _selectedPeriod = _getFixedPeriod(goal.type);
    });
  }

  void _updateTargetSuggestion() {
    setState(() {
      _targetController.text = _suggestedTargets[_selectedType]?.toString() ?? '';
      // Force fixed period when type changes
      _selectedPeriod = _getFixedPeriod(_selectedType);
    });
  }

  // Helper method to get the fixed period for a goal type
  GoalPeriod _getFixedPeriod(GoalType type) {
    return _fixedPeriods[type] ?? GoalPeriod.daily;
  }

  // Check if period can be changed for this type
  bool _isPeriodEditable(GoalType type) {
    // All types have fixed periods in this app, so none are editable
    return false;
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final targetValue = double.parse(_targetController.text);

    final result = await GoalService.createGoal(
      type: _selectedType,
      targetValue: targetValue,
      period: _selectedPeriod, // This will always be the correct fixed period
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onGoalCreated != null && result['goal'] != null) {
        widget.onGoalCreated!(result['goal']);
      }

      Navigator.pop(context, result['goal']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateGoal() async {
    if (!_formKey.currentState!.validate() || widget.existingGoal == null) return;

    setState(() => _isLoading = true);

    final targetValue = double.parse(_targetController.text);

    // For existing goals, we need to delete and recreate since the backend doesn't support updates
    final deleteResult = await GoalService.deleteGoal(widget.existingGoal!.type);
    
    if (!deleteResult['success']) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update goal: ${deleteResult['message']}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create new goal with updated values - use fixed period
    final createResult = await GoalService.createGoal(
      type: _selectedType,
      targetValue: targetValue,
      period: _selectedPeriod, // This will always be the correct fixed period
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (createResult['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      if (widget.onGoalCreated != null && createResult['goal'] != null) {
        widget.onGoalCreated!(createResult['goal']);
      }
      
      Navigator.pop(context, createResult['goal']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(createResult['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.existingGoal == null ? 'Create New Goal' : 'Edit Goal',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // Form
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Goal Type
                      DropdownButtonFormField<GoalType>(
                        value: _selectedType,
                        items: GoalType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  _getIconForType(type),
                                  color: _getColorForType(type),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(_typeTitles[type]!),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: widget.existingGoal != null 
                            ? null // Disable type change when editing
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedType = value;
                                    _updateTargetSuggestion();
                                  });
                                }
                              },
                        decoration: InputDecoration(
                          labelText: 'Goal Type',
                          prefixIcon: Icon(
                            _getIconForType(_selectedType),
                            color: _getColorForType(_selectedType),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Period - DISABLED/LOCKED with explanation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Period',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _periodTitles[_selectedPeriod]!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getColorForType(_selectedType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Fixed',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getColorForType(_selectedType),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPeriodDescription(_selectedType),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Target
                      TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Target',
                          prefixIcon: const Icon(Icons.flag),
                          suffixText: _typeUnits[_selectedType],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a target';
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null) {
                            return 'Please enter a valid number';
                          }
                          if (numValue <= 0) {
                            return 'Target must be greater than 0';
                          }
                          
                          // Additional validation based on goal type
                          if (_selectedType == GoalType.steps && numValue > 100000) {
                            return 'Steps target seems too high';
                          }
                          if (_selectedType == GoalType.water && numValue > 30) {
                            return 'Water target seems too high';
                          }
                          if (_selectedType == GoalType.sleep && numValue > 24) {
                            return 'Sleep hours cannot exceed 24';
                          }
                          if (_selectedType == GoalType.meditation && numValue > 480) {
                            return 'Meditation minutes seem too high';
                          }
                          if (_selectedType == GoalType.workouts && numValue > 50) {
                            return 'Workouts per week seem too high';
                          }
                          if (_selectedType == GoalType.calories && numValue > 100000) {
                            return 'Calorie target seems too high';
                          }
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quick suggestions (only show for new goals)
                      if (widget.existingGoal == null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick Suggestions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildSuggestionChip('10,000 steps', GoalType.steps, 10000),
                                  _buildSuggestionChip('8 glasses', GoalType.water, 8),
                                  _buildSuggestionChip('8 hours sleep', GoalType.sleep, 8),
                                  _buildSuggestionChip('10 min meditation', GoalType.meditation, 10),
                                  _buildSuggestionChip('5 workouts/week', GoalType.workouts, 5),
                                  _buildSuggestionChip('50,000 calories', GoalType.calories, 50000),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.existingGoal == null
                                    ? 'You can log progress for this goal through the Activity tab. '
                                        'Goals will automatically update when you log activities.'
                                    : 'To update an existing goal, you need to recreate it. '
                                        'Your progress will reset with the new target.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading 
                            ? null 
                            : (widget.existingGoal == null ? _saveGoal : _updateGoal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.existingGoal == null ? 'Create Goal' : 'Update Goal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPeriodDescription(GoalType type) {
    switch (type) {
      case GoalType.steps:
      case GoalType.water:
      case GoalType.sleep:
      case GoalType.meditation:
        return 'This goal is tracked daily';
      case GoalType.workouts:
        return 'This goal is tracked weekly';
      case GoalType.calories:
        return 'This goal is tracked monthly';
    }
  }

  Widget _buildSuggestionChip(String label, GoalType type, double target) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _targetController.text = target.toString();
          _selectedPeriod = _getFixedPeriod(type);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedType == type
              ? _getColorForType(type).withOpacity(0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedType == type
                ? _getColorForType(type)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _selectedType == type
                ? _getColorForType(type)
                : Colors.grey[600],
            fontWeight: _selectedType == type ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(GoalType type) {
    switch (type) {
      case GoalType.steps:
        return Icons.directions_walk;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.workouts:
        return Icons.fitness_center;
      case GoalType.water:
        return Icons.local_drink;
      case GoalType.sleep:
        return Icons.bedtime;
      case GoalType.meditation:
        return Icons.self_improvement;
    }
  }

  Color _getColorForType(GoalType type) {
    switch (type) {
      case GoalType.steps:
        return Colors.blue;
      case GoalType.calories:
        return Colors.orange;
      case GoalType.workouts:
        return Colors.green;
      case GoalType.water:
        return Colors.cyan;
      case GoalType.sleep:
        return Colors.purple;
      case GoalType.meditation:
        return Colors.indigo;
    }
  }
}