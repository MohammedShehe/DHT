import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gamification_models.dart';

class GoalSettingDialog extends StatefulWidget {
  final Goal? existingGoal;

  const GoalSettingDialog({super.key, this.existingGoal});

  @override
  State<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<GoalSettingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  
  GoalType _selectedType = GoalType.steps;
  GoalPeriod _selectedPeriod = GoalPeriod.daily;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _pointsReward = 10;

  final Map<GoalType, String> _typeTitles = {
    GoalType.steps: 'Steps',
    GoalType.calories: 'Calories Burned',
    GoalType.workoutMinutes: 'Workout Minutes',
    GoalType.waterGlasses: 'Water Glasses',
    GoalType.sleepHours: 'Sleep Hours',
    GoalType.meditation: 'Meditation Minutes',
  };

  final Map<GoalPeriod, String> _periodTitles = {
    GoalPeriod.daily: 'Daily',
    GoalPeriod.weekly: 'Weekly',
    GoalPeriod.monthly: 'Monthly',
  };

  final Map<GoalType, double> _suggestedTargets = {
    GoalType.steps: 10000,
    GoalType.calories: 500,
    GoalType.workoutMinutes: 30,
    GoalType.waterGlasses: 8,
    GoalType.sleepHours: 8,
    GoalType.meditation: 10,
  };

  final Map<GoalType, int> _suggestedPoints = {
    GoalType.steps: 10,
    GoalType.calories: 15,
    GoalType.workoutMinutes: 20,
    GoalType.waterGlasses: 5,
    GoalType.sleepHours: 10,
    GoalType.meditation: 15,
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      _loadExistingGoal();
    }
  }

  void _loadExistingGoal() {
    final goal = widget.existingGoal!;
    _titleController.text = goal.title;
    _descriptionController.text = goal.description;
    _targetController.text = goal.target.toString();
    _selectedType = goal.type;
    _selectedPeriod = goal.period;
    _startDate = goal.startDate;
    _endDate = goal.endDate;
    _pointsReward = goal.pointsReward;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _updateTargetSuggestion() {
    _targetController.text = _suggestedTargets[_selectedType]?.toString() ?? '';
    _pointsReward = _suggestedPoints[_selectedType] ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
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
                Text(
                  widget.existingGoal == null ? 'Create New Goal' : 'Edit Goal',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Goal Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Goal Title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a goal title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

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
                        onChanged: (value) {
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

                      // Period
                      DropdownButtonFormField<GoalPeriod>(
                        value: _selectedPeriod,
                        items: GoalPeriod.values.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(_periodTitles[period]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPeriod = value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Goal Period',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          suffixText: _getUnitForType(_selectedType),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a target';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Target must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quick suggestions
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
                                _buildSuggestionChip('8 glasses', GoalType.waterGlasses, 8),
                                _buildSuggestionChip('30 min workout', GoalType.workoutMinutes, 30),
                                _buildSuggestionChip('8 hours sleep', GoalType.sleepHours, 8),
                                _buildSuggestionChip('500 calories', GoalType.calories, 500),
                                _buildSuggestionChip('10 min meditation', GoalType.meditation, 10),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date range
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => _startDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(DateFormat.yMMMd().format(_startDate)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Date (Optional)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                                      firstDate: _startDate,
                                      lastDate: _startDate.add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => _endDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          _endDate != null
                                              ? DateFormat.yMMMd().format(_endDate!)
                                              : 'No end date',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Points reward
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stars, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Points Reward',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'You will earn $_pointsReward points upon completion',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_pointsReward pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: _saveGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Goal'),
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

  Widget _buildSuggestionChip(String label, GoalType type, double target) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _targetController.text = target.toString();
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
      case GoalType.workoutMinutes:
        return Icons.fitness_center;
      case GoalType.waterGlasses:
        return Icons.local_drink;
      case GoalType.sleepHours:
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
      case GoalType.workoutMinutes:
        return Colors.green;
      case GoalType.waterGlasses:
        return Colors.cyan;
      case GoalType.sleepHours:
        return Colors.purple;
      case GoalType.meditation:
        return Colors.indigo;
    }
  }

  String _getUnitForType(GoalType type) {
    switch (type) {
      case GoalType.steps:
        return 'steps';
      case GoalType.calories:
        return 'kcal';
      case GoalType.workoutMinutes:
        return 'min';
      case GoalType.waterGlasses:
        return 'glasses';
      case GoalType.sleepHours:
        return 'hours';
      case GoalType.meditation:
        return 'min';
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        id: widget.existingGoal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        period: _selectedPeriod,
        target: double.parse(_targetController.text),
        startDate: _startDate,
        endDate: _endDate,
        pointsReward: _pointsReward,
      );
      
      Navigator.pop(context, goal);
    }
  }
}