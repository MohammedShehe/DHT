// lib/widgets/add_meal_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_models.dart';
import '../models/food_model.dart';
import '../providers/activity_provider.dart';
import 'food_selection_widget.dart';
import 'custom_food_dialog.dart';

class AddMealDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final String? mealType;

  const AddMealDialog({super.key, this.selectedDate, this.mealType});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  String _mealType = 'Breakfast';
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  List<LoggedFood> _selectedFoods = [];
  bool _showFoodSelector = false;

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Brunch',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.mealType != null && _mealTypes.contains(widget.mealType)) {
      _mealType = widget.mealType!;
    }
  }

  void _addFood(FoodItem food, double quantity, String unit) {
    final loggedFood = LoggedFood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      food: food,
      quantity: quantity,
      servingUnit: unit,
      time: DateTime.now(),
      mealType: _mealType,
    );
    
    setState(() {
      _selectedFoods.add(loggedFood);
      _showFoodSelector = false;
    });
  }

  void _removeFood(String id) {
    setState(() {
      _selectedFoods.removeWhere((f) => f.id == id);
    });
  }

  int get _totalCalories {
    int total = 0;
    for (var food in _selectedFoods) {
      total += food.calories;
    }
    return total;
  }

  double get _totalProtein {
    double total = 0.0;
    for (var food in _selectedFoods) {
      total += food.protein;
    }
    return total;
  }

  double get _totalCarbs {
    double total = 0.0;
    for (var food in _selectedFoods) {
      total += food.carbs;
    }
    return total;
  }

  double get _totalFat {
    double total = 0.0;
    for (var food in _selectedFoods) {
      total += food.fat;
    }
    return total;
  }

  Future<void> _saveMeal() async {
    if (_selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one food item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create meal from selected foods
    final items = _selectedFoods.map((f) => 
      '${f.food.name} (${f.quantity} ${f.servingUnit})'
    ).join(', ');

    final now = DateTime.now();
    final mealTime = DateTime(
      now.year, now.month, now.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _mealType,
      calories: _totalCalories,
      time: DateFormat.jm().format(mealTime),
      items: items,
      protein: _totalProtein,
      carbs: _totalCarbs,
      fat: _totalFat,
    );

    // Use provider to add meal
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    await provider.addMeal(meal);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showCustomFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomFoodDialog(
        onFoodCreated: (food) {
          _addFood(food, 1.0, food.servingUnit ?? 'serving');
        },
        categoryId: _mealType.toLowerCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showFoodSelector) {
      return FoodSelectionWidget(
        onFoodSelected: _addFood,
        initialMealType: _mealType,
        onClose: () {
          setState(() {
            _showFoodSelector = false;
          });
        },
      );
    }

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
                  'Log Meal',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                
                // Meal Type
                DropdownButtonFormField<String>(
                  value: _mealType,
                  items: _mealTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _mealType = value!),
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(height: 16),

                // Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  leading: const Icon(Icons.access_time),
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

                // Selected Foods List
                if (_selectedFoods.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selected Foods',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_totalCalories} kcal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C853),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _selectedFoods.length,
                      itemBuilder: (context, index) {
                        final food = _selectedFoods[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.restaurant, color: Color(0xFF00C853), size: 20),
                            ),
                            title: Text(food.food.name),
                            subtitle: Text(
                              '${food.quantity} ${food.servingUnit} • ${food.calories} kcal',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeFood(food.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Add Food Button
                if (_selectedFoods.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No foods selected',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Add Food Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showCustomFoodDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Custom'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFoodSelector = true;
                            });
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Search Foods'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Macronutrients Summary
                if (_selectedFoods.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem(
                                'Protein',
                                '${_totalProtein.toStringAsFixed(1)}g',
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryItem(
                                'Carbs',
                                '${_totalCarbs.toStringAsFixed(1)}g',
                                Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryItem(
                                'Fat',
                                '${_totalFat.toStringAsFixed(1)}g',
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Save Button
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
                        onPressed: _saveMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                        ),
                        child: const Text('Save Meal'),
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}