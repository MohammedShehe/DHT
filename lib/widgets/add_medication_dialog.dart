import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_models.dart';
import '../providers/activity_provider.dart';

class AddMedicationDialog extends StatefulWidget {
  final Medication? existingMedication;

  const AddMedicationDialog({super.key, this.existingMedication});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _prescribedByController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<TimeOfDay> _selectedTimes = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _selectedColor = '#9C27B0';
  bool _isLoading = false;
  bool _isEditMode = false;
  int? _existingMedicationId;
  List<int> _existingScheduleIds = [];
  
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'purple', 'value': '#9C27B0', 'color': Colors.purple},
    {'name': 'blue', 'value': '#2196F3', 'color': Colors.blue},
    {'name': 'green', 'value': '#4CAF50', 'color': Colors.green},
    {'name': 'orange', 'value': '#FF9800', 'color': Colors.orange},
    {'name': 'red', 'value': '#F44336', 'color': Colors.red},
    {'name': 'teal', 'value': '#009688', 'color': Colors.teal},
    {'name': 'cyan', 'value': '#00BCD4', 'color': Colors.cyan},
    {'name': 'pink', 'value': '#E91E63', 'color': Colors.pink},
  ];

  final List<String> _unitOptions = [
    'mg', 'g', 'mcg', 'ml', 'IU', 'tablet', 'capsule', 'drop', 'puff'
  ];

  @override
  void initState() {
    super.initState();
    _unitController.text = 'mg';
    
    if (widget.existingMedication != null) {
      _isEditMode = true;
      _loadExistingMedication();
    } else {
      _selectedTimes = [TimeOfDay.now()];
    }
  }

  void _loadExistingMedication() {
    final med = widget.existingMedication!;
    _existingMedicationId = med.id;
    _nameController.text = med.name;
    _dosageController.text = med.dosage.toString();
    _unitController.text = med.unit;
    _instructionsController.text = med.instructions ?? '';
    _prescribedByController.text = med.prescribedBy ?? '';
    _notesController.text = med.notes ?? '';
    _startDate = med.startDate;
    _endDate = med.endDate;
    _selectedColor = med.color;
    
    // Store existing schedule IDs for deletion
    _existingScheduleIds = med.schedules.map((s) => s.id!).toList();
    
    debugPrint('Medication schedules count: ${med.schedules.length}');
    debugPrint('Existing schedule IDs: $_existingScheduleIds');
    
    // Load the scheduled times from the existing medication
    if (med.schedules.isNotEmpty) {
      _selectedTimes = med.schedules.map((schedule) => schedule.timeOfDay).toList();
      for (int i = 0; i < _selectedTimes.length; i++) {
        debugPrint('  Schedule $i: ${_selectedTimes[i].hour}:${_selectedTimes[i].minute}');
      }
    } else {
      _selectedTimes = [TimeOfDay.now()];
      debugPrint('No schedules found, using default time');
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _unitController.dispose();
    _instructionsController.dispose();
    _prescribedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addTimeSlot() {
    setState(() {
      _selectedTimes.add(TimeOfDay.now());
    });
    debugPrint('Added new time slot, total: ${_selectedTimes.length}');
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
    debugPrint('Removed time slot at index $index, remaining: ${_selectedTimes.length}');
  }

  Future<void> _selectTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (time != null) {
      setState(() {
        _selectedTimes[index] = time;
      });
      debugPrint('Updated schedule $index to: ${time.hour}:${time.minute}');
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one time for medication'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Convert TimeOfDay to schedule data
    final schedulesData = _selectedTimes.map((time) {
      return {
        'time_of_day': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
        'days_of_week': 'all',
      };
    }).toList();
    
    debugPrint('Saving medication with ${schedulesData.length} schedules:');
    for (int i = 0; i < schedulesData.length; i++) {
      debugPrint('  Schedule $i: ${schedulesData[i]['time_of_day']}');
    }
    
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    
    if (_existingMedicationId != null) {
      // Step 1: Delete all existing schedules
      debugPrint('Deleting ${_existingScheduleIds.length} existing schedules...');
      for (int scheduleId in _existingScheduleIds) {
        try {
          await provider.deleteSchedule(_existingMedicationId!, scheduleId);
          debugPrint('✅ Deleted schedule ID: $scheduleId');
        } catch (e) {
          debugPrint('❌ Error deleting schedule $scheduleId: $e');
        }
      }
      
      // Step 2: Update medication details
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'dosage': double.parse(_dosageController.text.trim()),
        'unit': _unitController.text.isEmpty ? 'mg' : _unitController.text.trim(),
        'color': _selectedColor,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'instructions': _instructionsController.text.isNotEmpty ? _instructionsController.text.trim() : null,
        'prescribed_by': _prescribedByController.text.isNotEmpty ? _prescribedByController.text.trim() : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      };
      if (_endDate != null) {
        updateData['end_date'] = _endDate!.toIso8601String().split('T')[0];
      } else {
        updateData['end_date'] = null;
      }
      
      debugPrint('Updating medication details...');
      final updateResult = await provider.updateMedication(_existingMedicationId!, updateData);
      
      if (updateResult['success']) {
        // Step 3: Add new schedules
        debugPrint('Adding ${schedulesData.length} new schedules...');
        for (var scheduleData in schedulesData) {
          try {
            await provider.addSchedule(_existingMedicationId!, scheduleData);
            debugPrint('✅ Added schedule: ${scheduleData['time_of_day']}');
          } catch (e) {
            debugPrint('❌ Error adding schedule: $e');
          }
        }
        
        // Step 4: Refresh data
        await provider.loadActivityData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
        setState(() => _isLoading = false);
        return;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updateResult['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    } else {
      // Create new medication with schedules
      final medicationData = {
        'name': _nameController.text.trim(),
        'dosage': double.parse(_dosageController.text.trim()),
        'unit': _unitController.text.isEmpty ? 'mg' : _unitController.text.trim(),
        'color': _selectedColor,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate?.toIso8601String().split('T')[0],
        'instructions': _instructionsController.text.isNotEmpty ? _instructionsController.text.trim() : null,
        'prescribed_by': _prescribedByController.text.isNotEmpty ? _prescribedByController.text.trim() : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        'schedules': schedulesData,
      };
      
      final result = await provider.createMedication(medicationData);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                  _isEditMode ? 'Edit Medication' : 'Add Medication',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Medication name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Medication Name *',
                          prefixIcon: const Icon(Icons.medication, color: Colors.purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medication name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dosage and unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dosageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Dosage *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _unitController.text,
                              items: _unitOptions.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _unitController.text = value!);
                              },
                              decoration: InputDecoration(
                                labelText: 'Unit *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Color selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Color',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: _colorOptions.map((colorOption) {
                              final isSelected = _selectedColor == colorOption['value'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = colorOption['value']),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colorOption['color'],
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: Colors.black, width: 2)
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (colorOption['color'] as Color).withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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
                                  'Start Date *',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

                      // Time slots section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Times *',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              TextButton.icon(
                                onPressed: _addTimeSlot,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Time'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_selectedTimes.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                'No times scheduled. Tap "Add Time" to add.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          else
                            ...List.generate(_selectedTimes.length, (index) {
                              final time = _selectedTimes[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        leading: const Icon(Icons.access_time, color: Colors.purple),
                                        onTap: () => _selectTime(index),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => _removeTimeSlot(index),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Instructions
                      TextFormField(
                        controller: _instructionsController,
                        decoration: InputDecoration(
                          labelText: 'Instructions',
                          prefixIcon: const Icon(Icons.info_outline, color: Colors.purple),
                          hintText: 'e.g., Take with food, before bed, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Prescribed by
                      TextFormField(
                        controller: _prescribedByController,
                        decoration: InputDecoration(
                          labelText: 'Prescribed By',
                          prefixIcon: const Icon(Icons.person, color: Colors.purple),
                          hintText: 'Doctor\'s name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Additional Notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        onPressed: _isLoading ? null : _saveMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
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
                            : Text(_isEditMode ? 'Update' : 'Add Medication'),
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
}