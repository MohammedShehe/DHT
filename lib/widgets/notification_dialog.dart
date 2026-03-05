import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';

class NotificationDialog extends StatefulWidget {
  final NotificationPreference? existingPreference;
  final Function(NotificationPreference)? onNotificationCreated;

  const NotificationDialog({
    super.key, 
    this.existingPreference,
    this.onNotificationCreated,
  });

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Weekdays by default
  String _selectedAction = ''; // Empty for no action
  bool _isEnabled = true;

  final List<Map<String, dynamic>> _availableActions = [
    {'value': '', 'label': 'No Action', 'icon': Icons.notifications_none},
    {'value': 'open_activity', 'label': 'Open Activity', 'icon': Icons.fitness_center},
    {'value': 'log_water', 'label': 'Log Water', 'icon': Icons.local_drink},
    {'value': 'log_meal', 'label': 'Log Meal', 'icon': Icons.restaurant},
    {'value': 'take_medication', 'label': 'Take Medication', 'icon': Icons.medication},
    {'value': 'meditate', 'label': 'Meditate', 'icon': Icons.self_improvement},
  ];

  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final Map<int, String> _dayAbbr = {0: 'S', 1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S'};

  @override
  void initState() {
    super.initState();
    if (widget.existingPreference != null) {
      _loadExistingPreference();
    }
  }

  void _loadExistingPreference() {
    final pref = widget.existingPreference!;
    _titleController.text = pref.title;
    _messageController.text = pref.message;
    _selectedTime = pref.time;
    _selectedDays = pref.dayIndices;
    _selectedAction = pref.actionType ?? '';
    _isEnabled = pref.isEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
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

  // Helper method to check if list contains all items (replaces extension)
  bool _containsAll(List<int> list, List<int> items) {
    for (var item in items) {
      if (!list.contains(item)) return false;
    }
    return true;
  }

  String _getRepeatDaysString() {
    if (_selectedDays.length == 7) return 'all';
    if (_selectedDays.length == 5 && _containsAll(_selectedDays, [1, 2, 3, 4, 5])) {
      return 'weekdays';
    }
    if (_selectedDays.length == 2 && _containsAll(_selectedDays, [0, 6])) {
      return 'weekends';
    }
    
    const dayMap = {0: 'sun', 1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat'};
    return _selectedDays.map((d) => dayMap[d]!).join(',');
  }

  void _saveNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create notification preference
    final preference = NotificationPreference(
      id: widget.existingPreference?.id,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      time: _selectedTime,
      repeatDays: _getRepeatDaysString(),
      actionType: _selectedAction.isEmpty ? null : _selectedAction,
      isEnabled: _isEnabled,
    );

    // Save via service
    final result = await NotificationService.savePreference(preference);
    
    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Notification saved successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onNotificationCreated != null && result['preference'] != null) {
        widget.onNotificationCreated!(result['preference']);
      }

      Navigator.pop(context, result['preference'] ?? preference);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to save notification'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
                  widget.existingPreference == null ? 'Create Reminder' : 'Edit Reminder',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // Form
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title *',
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

                      // Message Field
                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Message *',
                          prefixIcon: const Icon(Icons.message),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
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

                      // Repeat Days Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repeat *',
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
                                        _containsAll(_selectedDays, [1, 2, 3, 4, 5])
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
                                          _containsAll(_selectedDays, [1, 2, 3, 4, 5])
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
                                        _containsAll(_selectedDays, [0, 6])
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
                                          _containsAll(_selectedDays, [0, 6])
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
                                      _dayAbbr[index]!,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 16,
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

                      // Action Selection
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
                              children: _availableActions.map((action) {
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Enabled Switch
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Enable Notification',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            Switch(
                              value: _isEnabled,
                              onChanged: (value) => setState(() => _isEnabled = value),
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reset Info (for predefined notifications)
                      if (widget.existingPreference?.isPredefined == true) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
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
                                  'This is a predefined notification. You can edit or disable it.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
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
                        onPressed: _saveNotification,
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
}

