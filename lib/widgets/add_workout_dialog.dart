// lib/widgets/add_workout_dialog.dart (Updated to use WorkoutDetailService)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout_detail_models.dart';
import '../providers/workout_detail_provider.dart';
import '../services/workout_detail_service.dart';

class AddWorkoutDialog extends StatefulWidget {
  final DateTime? selectedDate;

  const AddWorkoutDialog({super.key, this.selectedDate});

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _distanceController = TextEditingController();
  final _heartRateController = TextEditingController();
  
  int? _selectedWorkoutTypeId;
  String? _customWorkoutName;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _intensity = 'moderate';
  String? _feeling;
  bool _isCustomType = false;
  bool _isLoading = false;

  final List<String> _intensityOptions = [
    'low',
    'moderate',
    'high',
    'very_high',
  ];

  final List<Map<String, dynamic>> _feelingOptions = [
    {'value': 'very_bad', 'label': 'Very Bad', 'icon': Icons.sentiment_very_dissatisfied},
    {'value': 'bad', 'label': 'Bad', 'icon': Icons.sentiment_dissatisfied},
    {'value': 'neutral', 'label': 'Neutral', 'icon': Icons.sentiment_neutral},
    {'value': 'good', 'label': 'Good', 'icon': Icons.sentiment_satisfied},
    {'value': 'excellent', 'label': 'Excellent', 'icon': Icons.sentiment_very_satisfied},
  ];

  @override
  void initState() {
    super.initState();
    // Load workout types when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WorkoutDetailProvider>(context, listen: false);
      if (provider.workoutTypes.isEmpty) {
        provider.loadWorkoutTypes();
      }
    });
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    _customTypeController.dispose();
    _distanceController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final selectedDate = widget.selectedDate ?? now;
    final workoutTime = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final request = CreateWorkoutRequest(
      workoutTypeId: _isCustomType ? null : _selectedWorkoutTypeId,
      customWorkoutName: _isCustomType ? _customTypeController.text.trim() : null,
      workoutTime: workoutTime,
      durationMinutes: int.parse(_durationController.text),
      intensity: _intensity,
      distance: _distanceController.text.isNotEmpty 
          ? double.tryParse(_distanceController.text) 
          : null,
      heartRate: _heartRateController.text.isNotEmpty 
          ? int.tryParse(_heartRateController.text) 
          : null,
      feeling: _feeling,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final provider = Provider.of<WorkoutDetailProvider>(context, listen: false);
    final result = await provider.logWorkout(request);

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success']) {
        Navigator.pop(context, true);
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutDetailProvider>(
      builder: (context, provider, child) {
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
                    const Text(
                      'Log Workout',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          // Workout Type Selection
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Select Type'),
                                  value: false,
                                  groupValue: _isCustomType,
                                  onChanged: (value) {
                                    setState(() {
                                      _isCustomType = false;
                                      _selectedWorkoutTypeId = null;
                                      _customTypeController.clear();
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Custom Type'),
                                  value: true,
                                  groupValue: _isCustomType,
                                  onChanged: (value) {
                                    setState(() {
                                      _isCustomType = true;
                                      _selectedWorkoutTypeId = null;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (!_isCustomType)
                            DropdownButtonFormField<int>(
                              value: _selectedWorkoutTypeId,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Select workout type'),
                                ),
                                ...provider.workoutTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type.id,
                                    child: Text(type.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedWorkoutTypeId = value);
                              },
                              decoration: InputDecoration(
                                labelText: 'Workout Type *',
                                prefixIcon: const Icon(Icons.fitness_center, color: Colors.green),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (!_isCustomType && value == null) {
                                  return 'Please select a workout type';
                                }
                                return null;
                              },
                            )
                          else
                            TextFormField(
                              controller: _customTypeController,
                              decoration: InputDecoration(
                                labelText: 'Custom Workout Type *',
                                prefixIcon: const Icon(Icons.edit, color: Colors.green),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (_isCustomType && (value == null || value.isEmpty)) {
                                  return 'Please enter workout type';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 16),

                          // Time Picker
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Time *'),
                            subtitle: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.access_time, color: Colors.green),
                            ),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (time != null) {
                                setState(() => _selectedTime = time);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Duration
                          TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Duration (minutes) *',
                              prefixIcon: const Icon(Icons.timer, color: Colors.green),
                              suffixText: 'min',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter duration';
                              }
                              final duration = int.tryParse(value);
                              if (duration == null || duration <= 0) {
                                return 'Please enter a valid duration';
                              }
                              if (duration > 1440) {
                                return 'Duration cannot exceed 24 hours';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Intensity
                          DropdownButtonFormField<String>(
                            value: _intensity,
                            items: _intensityOptions.map((intensity) {
                              return DropdownMenuItem(
                                value: intensity,
                                child: Text(intensity[0].toUpperCase() + intensity.substring(1)),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _intensity = value!),
                            decoration: InputDecoration(
                              labelText: 'Intensity *',
                              prefixIcon: const Icon(Icons.speed, color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Distance
                          TextFormField(
                            controller: _distanceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Distance (km)',
                              prefixIcon: const Icon(Icons.straighten, color: Colors.green),
                              suffixText: 'km',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Heart Rate
                          TextFormField(
                            controller: _heartRateController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Heart Rate (bpm)',
                              prefixIcon: const Icon(Icons.favorite, color: Colors.green),
                              suffixText: 'bpm',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final hr = int.tryParse(value);
                                if (hr != null && (hr < 30 || hr > 250)) {
                                  return 'Heart rate must be between 30 and 250';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Feeling
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'How do you feel?',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _feelingOptions.map((option) {
                                  final isSelected = _feeling == option['value'];
                                  return FilterChip(
                                    label: Text(option['label']),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _feeling = selected ? option['value'] : null;
                                      });
                                    },
                                    avatar: Icon(
                                      option['icon'],
                                      size: 16,
                                      color: isSelected ? Colors.white : Colors.grey,
                                    ),
                                    selectedColor: Colors.green,
                                    backgroundColor: Colors.grey[100],
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'Add any notes about your workout...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                            onPressed: _isLoading ? null : _saveWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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
                                : const Text('Log Workout'),
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
      },
    );
  }
}