// lib/widgets/edit_workout_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_detail_models.dart';
import '../providers/workout_detail_provider.dart';
import '../services/workout_detail_service.dart';

class EditWorkoutDialog extends StatefulWidget {
  final WorkoutDetail workout;
  final WorkoutDetailProvider workoutProvider;
  final VoidCallback onUpdated;

  const EditWorkoutDialog({
    super.key,
    required this.workout,
    required this.workoutProvider,
    required this.onUpdated,
  });

  @override
  State<EditWorkoutDialog> createState() => _EditWorkoutDialogState();
}

class _EditWorkoutDialogState extends State<EditWorkoutDialog> {
  late TextEditingController _customWorkoutNameController;
  late TextEditingController _durationController;
  late TextEditingController _distanceController;
  late TextEditingController _heartRateController;
  late TextEditingController _notesController;
  
  late String _selectedIntensity;
  late String? _selectedFeeling;
  late DateTime _selectedDateTime;
  late int? _selectedWorkoutTypeId;
  
  bool _isLoading = false;
  bool _useCustomWorkout = false;

  final List<String> _intensityOptions = ['low', 'moderate', 'high', 'very_high'];
  final List<String> _feelingOptions = ['very_bad', 'bad', 'neutral', 'good', 'excellent'];

  @override
  void initState() {
    super.initState();
    
    _useCustomWorkout = widget.workout.customWorkoutName != null && 
                        widget.workout.customWorkoutName!.isNotEmpty;
    
    _customWorkoutNameController = TextEditingController(
      text: _useCustomWorkout ? widget.workout.customWorkoutName : '',
    );
    _durationController = TextEditingController(
      text: widget.workout.durationMinutes.toString(),
    );
    _distanceController = TextEditingController(
      text: widget.workout.distance?.toString() ?? '',
    );
    _heartRateController = TextEditingController(
      text: widget.workout.heartRate?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.workout.notes ?? '',
    );
    
    _selectedIntensity = widget.workout.intensity;
    _selectedFeeling = widget.workout.feeling;
    _selectedDateTime = widget.workout.workoutTime;
    _selectedWorkoutTypeId = _useCustomWorkout ? null : widget.workout.workoutTypeId;
  }

  @override
  void dispose() {
    _customWorkoutNameController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateWorkout() async {
    if (_durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter duration')),
      );
      return;
    }

    if (!_useCustomWorkout && _selectedWorkoutTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a workout type')),
      );
      return;
    }

    if (_useCustomWorkout && _customWorkoutNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = UpdateWorkoutRequest(
      workoutTypeId: _useCustomWorkout ? null : _selectedWorkoutTypeId,
      customWorkoutName: _useCustomWorkout ? _customWorkoutNameController.text.trim() : null,
      workoutTime: _selectedDateTime,
      durationMinutes: int.tryParse(_durationController.text),
      intensity: _selectedIntensity,
      distance: _distanceController.text.isNotEmpty ? double.tryParse(_distanceController.text) : null,
      heartRate: _heartRateController.text.isNotEmpty ? int.tryParse(_heartRateController.text) : null,
      feeling: _selectedFeeling,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final result = await widget.workoutProvider.updateWorkout(widget.workout.id, request);

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
      }
    }
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final result = await widget.workoutProvider.deleteWorkout(widget.workout.id);
      setState(() => _isLoading = false);

      if (result['success'] && mounted) {
        Navigator.pop(context);
        widget.onUpdated();
      }
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Workout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _isLoading ? null : _deleteWorkout,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Workout Type Selection
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Custom Workout'),
                  value: _useCustomWorkout,
                  onChanged: _isLoading ? null : (value) {
                    setState(() => _useCustomWorkout = value);
                  },
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          if (_useCustomWorkout)
            TextField(
              controller: _customWorkoutNameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            )
          else
            FutureBuilder<List<WorkoutType>>(
              future: _loadWorkoutTypes(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return DropdownButtonFormField<int>(
                    value: _selectedWorkoutTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Workout Type',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((type) {
                      return DropdownMenuItem(
                        value: type.id,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: _isLoading ? null : (value) {
                      setState(() => _selectedWorkoutTypeId = value);
                    },
                  );
                }
                return const SizedBox();
              },
            ),

          const SizedBox(height: 16),

          // Date and Time
          InkWell(
            onTap: _isLoading ? null : _selectDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('MMM d, yyyy · h:mm a').format(_selectedDateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Duration
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Distance
          TextField(
            controller: _distanceController,
            decoration: const InputDecoration(
              labelText: 'Distance (km)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Heart Rate
          TextField(
            controller: _heartRateController,
            decoration: const InputDecoration(
              labelText: 'Heart Rate (bpm)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Intensity
          DropdownButtonFormField<String>(
            value: _selectedIntensity,
            decoration: const InputDecoration(
              labelText: 'Intensity',
              border: OutlineInputBorder(),
            ),
            items: _intensityOptions.map((intensity) {
              return DropdownMenuItem(
                value: intensity,
                child: Text(intensity[0].toUpperCase() + intensity.substring(1)),
              );
            }).toList(),
            onChanged: _isLoading ? null : (value) {
              setState(() => _selectedIntensity = value!);
            },
          ),

          const SizedBox(height: 16),

          // Feeling
          DropdownButtonFormField<String?>(
            value: _selectedFeeling,
            decoration: const InputDecoration(
              labelText: 'How did you feel?',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Not recorded')),
              ..._feelingOptions.map((feeling) {
                String display = feeling.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                return DropdownMenuItem(
                  value: feeling,
                  child: Text(display),
                );
              }),
            ],
            onChanged: _isLoading ? null : (value) {
              setState(() => _selectedFeeling = value);
            },
          ),

          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 24),

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
                  onPressed: _isLoading ? null : _updateWorkout,
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
                      : const Text('Update'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<WorkoutType>> _loadWorkoutTypes() async {
    final result = await WorkoutDetailService.getWorkoutTypes();
    if (result['success']) {
      return result['types'] as List<WorkoutType>;
    }
    return [];
  }
}