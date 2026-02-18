// lib/widgets/add_medication_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_models.dart';
import '../providers/activity_provider.dart';

class AddMedicationDialog extends StatefulWidget {
  const AddMedicationDialog({super.key});

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
  
  List<TimeOfDay> _selectedTimes = [TimeOfDay.now()];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _selectedColor = 'purple';
  
  final List<String> _colorOptions = [
    'purple', 'blue', 'green', 'orange', 'red', 'teal'
  ];
  
  final Map<String, Color> _colorMap = {
    'purple': Colors.purple,
    'blue': Colors.blue,
    'green': Colors.green,
    'orange': Colors.orange,
    'red': Colors.red,
    'teal': Colors.teal,
  };

  final List<String> _unitOptions = [
    'mg', 'g', 'mcg', 'ml', 'IU', 'tablet', 'capsule', 'drop', 'puff'
  ];

  @override
  void initState() {
    super.initState();
    _unitController.text = 'mg';
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
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
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
    }
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate() && _selectedTimes.isNotEmpty) {
      final now = DateTime.now();
      
      // Convert TimeOfDay to DateTime for each scheduled time
      final scheduledTimes = _selectedTimes.map((time) {
        return DateTime(
          now.year, now.month, now.day,
          time.hour, time.minute,
        );
      }).toList();
      
      // Initialize taken list with false for all times
      final taken = List.generate(scheduledTimes.length, (index) => false);
      
      // Create medication JSON with correct structure
      final medicationJson = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'unit': _unitController.text.isEmpty ? 'mg' : _unitController.text.trim(),
        'scheduled_times': scheduledTimes.map((t) => t.toIso8601String()).toList(),
        'taken': taken,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'instructions': _instructionsController.text.isEmpty ? null : _instructionsController.text.trim(),
        'prescribed_by': _prescribedByController.text.isEmpty ? null : _prescribedByController.text.trim(),
        'notes': _notesController.text.isEmpty ? null : _notesController.text.trim(),
        'color': _selectedColor,
        'is_active': true,
      };
      
      // Use provider to add medication
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      provider.addMedication(medicationJson);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } else if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one time for medication'),
          backgroundColor: Colors.red,
        ),
      );
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
                const Text(
                  'Add Medication',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
                          Row(
                            children: _colorOptions.map((colorName) {
                              final isSelected = _selectedColor == colorName;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = colorName),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _colorMap[colorName],
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: Colors.black, width: 2)
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: _colorMap[colorName]!.withOpacity(0.5),
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

                      // Time slots
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
                          ...List.generate(_selectedTimes.length, (index) {
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
                                      title: Text(_selectedTimes[index].format(context)),
                                      leading: const Icon(Icons.access_time, color: Colors.purple),
                                      onTap: () => _selectTime(index),
                                    ),
                                  ),
                                  if (_selectedTimes.length > 1)
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
                        onPressed: _saveMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Add Medication'),
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