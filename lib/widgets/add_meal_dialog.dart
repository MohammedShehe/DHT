import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';
import '../providers/meal_provider.dart';
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
  
  List<MealItemInput> _selectedItems = [];
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
    final item = MealItemInput.fromFood(food, quantity, unit);
    setState(() {
      _selectedItems.add(item);
      _showFoodSelector = false;
    });
  }

  void _addCustomFood(String name, int calories, double protein, double carbs, double fat, double quantity, String unit) {
    final item = MealItemInput.custom(
      customFoodName: name,
      quantity: quantity,
      servingUnit: unit,
      customCalories: calories,
      customProtein: protein,
      customCarbs: carbs,
      customFat: fat,
    );
    setState(() {
      _selectedItems.add(item);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  int get _totalCalories {
    return _selectedItems.fold(0, (sum, item) => sum + item.calories);
  }

  double get _totalProtein {
    return _selectedItems.fold(0.0, (sum, item) => sum + item.protein);
  }

  double get _totalCarbs {
    return _selectedItems.fold(0.0, (sum, item) => sum + item.carbs);
  }

  double get _totalFat {
    return _selectedItems.fold(0.0, (sum, item) => sum + item.fat);
  }

  Future<void> _saveMeal() async {
    if (_selectedItems.isEmpty) {
      _showMessage('Please add at least one food item', isError: true);
      return;
    }

    final now = DateTime.now();
    final selectedDate = widget.selectedDate ?? now;
    final mealTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final items = _selectedItems.map((item) => item.toCreateMealItem()).toList();

    final request = CreateMealRequest(
      mealType: _mealType,
      mealTime: mealTime,
      items: items,
    );

    final provider = Provider.of<MealProvider>(context, listen: false);
    final result = await provider.createMeal(request);

    if (mounted && result['success']) {
      Navigator.pop(context, true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCustomFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomFoodDialog(
        onFoodCreated: (food) {
          _addFood(food, 1.0, food.servingUnit);
        },
        onCustomFoodAdded: _addCustomFood,
        initialCategory: _mealType,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                      color: const Color(0xFF00C853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.access_time, color: Color(0xFF00C853)),
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

                if (_selectedItems.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selected Items',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$_totalCalories kcal',
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
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
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
                            title: Text(item.displayName),
                            subtitle: Text(
                              '${item.quantity.toStringAsFixed(1)} ${item.servingUnit} • ${item.calories} kcal',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                if (_selectedItems.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No items selected',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the buttons below to add food items',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_selectedItems.isNotEmpty) ...[
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
                        onPressed: _saveMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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

class MealItemInput {
  final int? foodItemId;
  final String? customFoodName;
  final double quantity;
  final String servingUnit;
  final int? customCalories;
  final double? customProtein;
  final double? customCarbs;
  final double? customFat;

  MealItemInput({
    this.foodItemId,
    this.customFoodName,
    required this.quantity,
    required this.servingUnit,
    this.customCalories,
    this.customProtein,
    this.customCarbs,
    this.customFat,
  });

  factory MealItemInput.fromFood(FoodItem food, double quantity, String servingUnit) {
    return MealItemInput(
      foodItemId: food.id,
      quantity: quantity,
      servingUnit: servingUnit,
    );
  }

  factory MealItemInput.custom({
    required String customFoodName,
    required double quantity,
    required String servingUnit,
    required int customCalories,
    required double customProtein,
    required double customCarbs,
    required double customFat,
  }) {
    return MealItemInput(
      customFoodName: customFoodName,
      quantity: quantity,
      servingUnit: servingUnit,
      customCalories: customCalories,
      customProtein: customProtein,
      customCarbs: customCarbs,
      customFat: customFat,
    );
  }

  int get calories {
    if (customCalories != null) return customCalories!;
    return 0;
  }

  double get protein => customProtein ?? 0.0;
  double get carbs => customCarbs ?? 0.0;
  double get fat => customFat ?? 0.0;

  String get displayName {
    if (customFoodName != null) return customFoodName!;
    return 'Food Item';
  }

  CreateMealItem toCreateMealItem() {
    return CreateMealItem(
      foodItemId: foodItemId,
      quantity: quantity,
      servingUnit: servingUnit,
      customFoodName: customFoodName,
      customCalories: customCalories,
      customProtein: customProtein,
      customCarbs: customCarbs,
      customFat: customFat,
    );
  }
}