import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gamification_models.dart';

class ReminderDialog extends StatefulWidget {
  final Reminder? existingReminder;

  const ReminderDialog({super.key, this.existingReminder});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Weekdays by default
  String _selectedAction = ''; // Changed from String? to String with default empty string

  final List<Map<String, dynamic>> _availableActions = [
    {'value': 'open_activity', 'label': 'Open Activity', 'icon': Icons.fitness_center},
    {'value': 'open_hydration', 'label': 'Log Water', 'icon': Icons.local_drink},
    {'value': 'open_meal', 'label': 'Log Meal', 'icon': Icons.restaurant},
    {'value': 'open_medication', 'label': 'Take Medication', 'icon': Icons.medication},
    {'value': 'open_meditation', 'label': 'Meditate', 'icon': Icons.self_improvement},
  ];

  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _loadExistingReminder();
    }
  }

  void _loadExistingReminder() {
    final reminder = widget.existingReminder!;
    _titleController.text = reminder.title;
    _descriptionController.text = reminder.description;
    _selectedTime = reminder.time;
    _selectedDays = List.from(reminder.repeatDays);
    _selectedAction = reminder.action ?? ''; // Handle null action
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  void _selectAllDays() {
    setState(() {
      _selectedDays = [0, 1, 2, 3, 4, 5, 6];
    });
  }

  void _selectWeekdays() {
    setState(() {
      _selectedDays = [1, 2, 3, 4, 5];
    });
  }

  void _selectWeekends() {
    setState(() {
      _selectedDays = [0, 6];
    });
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
                  widget.existingReminder == null ? 'Set Reminder' : 'Edit Reminder',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Reminder Title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
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

                      // Time
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Time'),
                        subtitle: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.access_time, color: Colors.blue),
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

                      // Repeat days
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repeat',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          
                          // Quick select buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _selectAllDays,
                                  style: TextButton.styleFrom(
                                    backgroundColor: _selectedDays.length == 7
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'All Days',
                                    style: TextStyle(
                                      color: _selectedDays.length == 7
                                          ? Colors.blue
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: _selectWeekdays,
                                  style: TextButton.styleFrom(
                                    backgroundColor: _selectedDays.length == 5 &&
                                        _selectedDays.containsAll([1, 2, 3, 4, 5])
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Weekdays',
                                    style: TextStyle(
                                      color: _selectedDays.length == 5 &&
                                          _selectedDays.containsAll([1, 2, 3, 4, 5])
                                          ? Colors.blue
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: _selectWeekends,
                                  style: TextButton.styleFrom(
                                    backgroundColor: _selectedDays.length == 2 &&
                                        _selectedDays.containsAll([0, 6])
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Weekends',
                                    style: TextStyle(
                                      color: _selectedDays.length == 2 &&
                                          _selectedDays.containsAll([0, 6])
                                          ? Colors.blue
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Day chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(7, (index) {
                              final isSelected = _selectedDays.contains(index);
                              return GestureDetector(
                                onTap: () => _toggleDay(index),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? null
                                        : Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _dayNames[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action (optional)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Action (Optional)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  title: const Text('No action'),
                                  value: '', // Empty string for no action
                                  groupValue: _selectedAction,
                                  onChanged: (value) {
                                    setState(() => _selectedAction = value ?? '');
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  dense: true,
                                ),
                                ..._availableActions.map((action) {
                                  return RadioListTile<String>(
                                    title: Row(
                                      children: [
                                        Icon(action['icon'], size: 18, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(action['label']),
                                      ],
                                    ),
                                    value: action['value'],
                                    groupValue: _selectedAction,
                                    onChanged: (value) {
                                      setState(() => _selectedAction = value ?? '');
                                    },
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    dense: true,
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
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
                        onPressed: _saveReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Reminder'),
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

  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one day'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final reminder = Reminder(
        id: widget.existingReminder?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        time: _selectedTime,
        repeatDays: _selectedDays,
        isEnabled: widget.existingReminder?.isEnabled ?? true,
        action: _selectedAction.isEmpty ? null : _selectedAction, // Convert empty string to null
      );
      
      Navigator.pop(context, reminder);
    }
  }
}

extension ListContainsAll on List<int> {
  bool containsAll(List<int> items) {
    for (var item in items) {
      if (!contains(item)) return false;
    }
    return true;
  }
}