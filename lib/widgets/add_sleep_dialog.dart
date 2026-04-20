import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sleep_activity_models.dart';
import '../providers/sleep_activity_provider.dart';

class AddSleepDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final SleepLog? existingSleepLog;

  const AddSleepDialog({super.key, this.selectedDate, this.existingSleepLog});

  @override
  State<AddSleepDialog> createState() => _AddSleepDialogState();
}

class _AddSleepDialogState extends State<AddSleepDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  TimeOfDay _bedTime = TimeOfDay.now();
  TimeOfDay _wakeTime = TimeOfDay.now();
  int _interruptions = 0;
  String _selectedQuality = 'Good';
  bool _isLoading = false;
  
  List<SleepQualityType> _qualityTypes = [];

  @override
  void initState() {
    super.initState();
    _loadQualityTypes();
    
    if (widget.existingSleepLog != null) {
      _bedTime = widget.existingSleepLog!.bedtime;
      _wakeTime = widget.existingSleepLog!.wakeTime;
      _interruptions = widget.existingSleepLog!.interruptions;
      _selectedQuality = widget.existingSleepLog!.sleepQuality;
      _notesController.text = widget.existingSleepLog!.notes ?? '';
    }
  }

  Future<void> _loadQualityTypes() async {
    final provider = Provider.of<SleepActivityProvider>(context, listen: false);
    await provider.loadQualityTypes();
    setState(() {
      _qualityTypes = provider.qualityTypes;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSleep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final selectedDate = widget.selectedDate ?? DateTime.now();
    final provider = Provider.of<SleepActivityProvider>(context, listen: false);

    final result = await provider.logSleep(
      sleepDate: selectedDate,
      bedtime: _bedTime,
      wakeTime: _wakeTime,
      interruptions: _interruptions,
      sleepQuality: _selectedQuality,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  double _calculateSleepDuration() {
    DateTime now = DateTime.now();
    DateTime bedDateTime = DateTime(
      now.year, now.month, now.day,
      _bedTime.hour, _bedTime.minute,
    );
    DateTime wakeDateTime = DateTime(
      now.year, now.month, now.day,
      _wakeTime.hour, _wakeTime.minute,
    );
    
    if (wakeDateTime.isBefore(bedDateTime)) {
      wakeDateTime = wakeDateTime.add(const Duration(days: 1));
    }
    
    Duration duration = wakeDateTime.difference(bedDateTime);
    return duration.inHours + (duration.inMinutes % 60) / 60.0;
  }

  @override
  Widget build(BuildContext context) {
    final sleepDuration = _calculateSleepDuration();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                  widget.existingSleepLog == null ? 'Log Sleep' : 'Edit Sleep',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Bedtime
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bedtime *'),
                        subtitle: Text(
                          _bedTime.format(context),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.nightlight_round, color: Colors.indigo),
                        ),
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
                      const SizedBox(height: 16),

                      // Wake Time
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Wake Time *'),
                        subtitle: Text(
                          _wakeTime.format(context),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.wb_sunny, color: Colors.orange),
                        ),
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

                      // Sleep Duration Preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bedtime, color: Colors.purple),
                            const SizedBox(width: 8),
                            Text(
                              'Sleep Duration: ${sleepDuration.toStringAsFixed(1)} hours',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
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
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              if (_interruptions > 0) {
                                setState(() => _interruptions--);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () => setState(() => _interruptions++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sleep Quality
                      DropdownButtonFormField<String>(
                        value: _selectedQuality,
                        items: _qualityTypes.isEmpty
                            ? const [
                                DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                                DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                                DropdownMenuItem(value: 'Good', child: Text('Good')),
                                DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                              ]
                            : _qualityTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type.value,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: type.colorValue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(type.label),
                                    ],
                                  ),
                                );
                              }).toList(),
                        onChanged: (value) => setState(() => _selectedQuality = value!),
                        decoration: const InputDecoration(
                          labelText: 'Sleep Quality *',
                          prefixIcon: Icon(Icons.star, color: Colors.purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select sleep quality';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Add any notes about your sleep...',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
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
                        onPressed: _isLoading ? null : _saveSleep,
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
                            : Text(widget.existingSleepLog == null ? 'Save' : 'Update'),
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