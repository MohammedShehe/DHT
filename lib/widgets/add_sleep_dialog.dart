// lib/widgets/add_sleep_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_models.dart';
import '../providers/activity_provider.dart';

class AddSleepDialog extends StatefulWidget {
  final DateTime? selectedDate;

  const AddSleepDialog({super.key, this.selectedDate});

  @override
  State<AddSleepDialog> createState() => _AddSleepDialogState();
}

class _AddSleepDialogState extends State<AddSleepDialog> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay _bedTime = TimeOfDay.now();
  TimeOfDay _wakeTime = TimeOfDay.now();
  int _interruptions = 0;
  String _quality = 'Good';

  final List<String> _qualityLevels = ['Poor', 'Fair', 'Good', 'Excellent'];

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
                  'Log Sleep',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Bedtime
                      ListTile(
                        title: const Text('Bedtime'),
                        subtitle: Text(_bedTime.format(context)),
                        leading: const Icon(Icons.nightlight_round),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _bedTime,
                          );
                          if (time != null) {
                            setState(() => _bedTime = time);
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      // Wake Time
                      ListTile(
                        title: const Text('Wake Time'),
                        subtitle: Text(_wakeTime.format(context)),
                        leading: const Icon(Icons.wb_sunny),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _wakeTime,
                          );
                          if (time != null) {
                            setState(() => _wakeTime = time);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Interruptions
                      Row(
                        children: [
                          const Icon(Icons.notifications, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Interruptions: $_interruptions',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () {
                              if (_interruptions > 0) {
                                setState(() => _interruptions--);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () => setState(() => _interruptions++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sleep Quality
                      DropdownButtonFormField<String>(
                        value: _quality,
                        items: _qualityLevels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _quality = value!),
                        decoration: const InputDecoration(
                          labelText: 'Sleep Quality',
                          prefixIcon: Icon(Icons.star),
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
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveSleep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                        ),
                        child: const Text('Save'),
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

  void _saveSleep() {
    final now = DateTime.now();
    final selectedDate = widget.selectedDate ?? now;
    
    // Create DateTime objects for bed and wake times
    final bedDateTime = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      _bedTime.hour, _bedTime.minute,
    );
    
    final wakeDateTime = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      _wakeTime.hour, _wakeTime.minute,
    );
    
    // Calculate sleep duration correctly (handle overnight sleep)
    Duration sleepDuration;
    if (wakeDateTime.isBefore(bedDateTime)) {
      // Wake time is on the next day
      sleepDuration = wakeDateTime
          .add(const Duration(days: 1))
          .difference(bedDateTime);
    } else {
      sleepDuration = wakeDateTime.difference(bedDateTime);
    }
    
    final sleep = Sleep(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: selectedDate,
      bedTime: _bedTime,
      wakeTime: _wakeTime,
      duration: sleepDuration.inHours + (sleepDuration.inMinutes % 60) / 60.0,
      interruptions: _interruptions,
      quality: _quality,
      deepSleep: sleepDuration.inHours * 0.3, // Example calculation
      remSleep: sleepDuration.inHours * 0.25,
      lightSleep: sleepDuration.inHours * 0.45,
    );
    
    // Use provider to add sleep
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    provider.addSleep(sleep);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}