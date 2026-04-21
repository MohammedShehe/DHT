import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/hydration_models.dart';
import '../providers/hydration_provider.dart';

class AddHydrationDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final HydrationProvider provider;
  final HydrationLog? existingLog;

  const AddHydrationDialog({
    super.key,
    this.selectedDate,
    required this.provider,
    this.existingLog,
  });

  @override
  State<AddHydrationDialog> createState() => _AddHydrationDialogState();
}

class _AddHydrationDialogState extends State<AddHydrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _customDrinkNameController = TextEditingController();
  
  int _amount = 250;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DrinkType? _selectedDrinkType;
  bool _isOtherType = false;
  bool _isLoading = false;
  bool _isEditMode = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _isEditMode = widget.existingLog != null;
    
    if (_isEditMode && widget.existingLog != null) {
      final log = widget.existingLog!;
      _amount = log.amountMl;
      _selectedTime = log.consumptionTime;
      _selectedDate = log.logDate;
      _notesController.text = log.notes ?? '';
      
      final drinkType = widget.provider.drinkTypes.firstWhere(
        (d) => d.value == log.drinkType,
        orElse: () => widget.provider.drinkTypes.first,
      );
      _selectedDrinkType = drinkType;
      _isOtherType = log.drinkType == 'other';
      if (_isOtherType && log.customDrinkName != null) {
        _customDrinkNameController.text = log.customDrinkName!;
      }
    } else {
      if (widget.provider.drinkTypes.isNotEmpty) {
        _selectedDrinkType = widget.provider.drinkTypes.first;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customDrinkNameController.dispose();
    super.dispose();
  }

  void _setPresetAmount(int amount) {
    setState(() => _amount = amount);
  }

  void _selectDrinkType(DrinkType type) {
    setState(() {
      _selectedDrinkType = type;
      _isOtherType = type.value == 'other';
      if (!_isOtherType) {
        _customDrinkNameController.clear();
      }
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveHydration() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDrinkType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a drink type'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isOtherType && _customDrinkNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a custom drink name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    
    if (_isEditMode && widget.existingLog != null) {
      result = await widget.provider.updateHydrationLog(
        id: widget.existingLog!.id,
        amountMl: _amount,
        drinkType: _selectedDrinkType!.value,
        customDrinkName: _isOtherType ? _customDrinkNameController.text.trim() : null,
        consumptionTime: _selectedTime,
        logDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      print('Update result: $result');
    } else {
      result = await widget.provider.logHydration(
        amountMl: _amount,
        drinkType: _selectedDrinkType!.value,
        customDrinkName: _isOtherType ? _customDrinkNameController.text.trim() : null,
        consumptionTime: _selectedTime,
        logDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Operation failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteLog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Delete ${widget.existingLog?.displayName} (${widget.existingLog?.amountMl}ml) from ${widget.existingLog?.formattedTime}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final result = await widget.provider.deleteHydrationLog(widget.existingLog!.id);
      setState(() => _isLoading = false);
      if (result['success'] && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Delete failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HydrationProvider>(
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
                      _isEditMode ? 'Edit Hydration' : 'Log Hydration',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          // Date picker
                          const Text(
                            'Date',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Select Date'),
                            subtitle: Text(
                              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_today, color: Colors.blue),
                            ),
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 16),

                          // Preset amounts
                          const Text(
                            'Quick Add',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: provider.presetAmounts.map((preset) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ElevatedButton(
                                    onPressed: () => _setPresetAmount(preset.value),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _amount == preset.value
                                          ? Colors.blue
                                          : Colors.blue.withOpacity(0.1),
                                      foregroundColor: _amount == preset.value
                                          ? Colors.white
                                          : Colors.blue,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Text(preset.label),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Custom amount
                          const Text(
                            'Custom Amount',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _amount.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount (ml)',
                              prefixIcon: const Icon(Icons.water_drop, color: Colors.blue),
                              suffixText: 'ml',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0 && parsed <= 5000) {
                                setState(() => _amount = parsed);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter amount';
                              }
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Please enter a valid amount';
                              }
                              if (parsed > 5000) {
                                return 'Amount cannot exceed 5000ml';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Drink type
                          const Text(
                            'Drink Type',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: provider.drinkTypes.map((type) {
                              final isSelected = _selectedDrinkType?.value == type.value;
                              return GestureDetector(
                                onTap: () => _selectDrinkType(type),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? type.colorValue.withOpacity(0.2)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected
                                        ? Border.all(color: type.colorValue, width: 1)
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.water_drop,
                                        size: 16,
                                        color: isSelected ? type.colorValue : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        type.label,
                                        style: TextStyle(
                                          color: isSelected ? type.colorValue : Colors.grey[700],
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          
                          // Custom drink name for "Other" type
                          if (_isOtherType) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _customDrinkNameController,
                              decoration: InputDecoration(
                                labelText: 'Custom Drink Name',
                                prefixIcon: const Icon(Icons.edit, color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (_isOtherType && (value == null || value.isEmpty)) {
                                  return 'Please enter a drink name';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          
                          // Time picker
                          const Text(
                            'Time',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Select Time'),
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
                            onTap: _selectTime,
                          ),
                          const SizedBox(height: 16),
                          
                          // Notes
                          const Text(
                            'Notes (Optional)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any notes about your hydration...',
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
                            onPressed: _isLoading ? null : _saveHydration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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
                                : Text(_isEditMode ? 'Update' : 'Log Hydration'),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_isEditMode) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _deleteLog,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete Entry', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
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