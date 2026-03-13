import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';
import '../providers/meal_provider.dart';
import 'package:provider/provider.dart';

class CustomFoodDialog extends StatefulWidget {
  final Function(FoodItem) onFoodCreated;
  final Function(String, int, double, double, double, double, String) onCustomFoodAdded;
  final String initialCategory;

  const CustomFoodDialog({
    super.key,
    required this.onFoodCreated,
    required this.onCustomFoodAdded,
    required this.initialCategory,
  });

  @override
  State<CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<CustomFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _quantityController = TextEditingController(text: '1.0');
  
  String _servingUnit = 'g';
  int? _selectedCategoryId;
  bool _isLoading = false;

  final List<String> _servingUnits = ['g', 'ml', 'oz', 'cup', 'tbsp', 'tsp', 'piece', 'slice', 'serving'];

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1.0';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Find category ID by name
  int? _getCategoryIdByName(MealProvider provider, String categoryName) {
    final category = provider.categories.firstWhere(
      (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => provider.categories.firstWhere(
        (c) => c.name == 'Other',
        orElse: () => provider.categories.first,
      ),
    );
    return category.id;
  }

  Future<void> _createFood() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<MealProvider>(context, listen: false);
    
    if (_selectedCategoryId == null) {
      _selectedCategoryId = _getCategoryIdByName(provider, widget.initialCategory);
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create the food in backend
    final request = CreateCustomFoodRequest(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      calories: int.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      servingUnit: _servingUnit,
    );

    final result = await provider.createCustomFood(request);

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] && result['food'] != null) {
        // Add to current meal with quantity
        final food = result['food'] as FoodItem;
        final quantity = double.tryParse(_quantityController.text) ?? 1.0;
        
        widget.onFoodCreated(food);
        widget.onCustomFoodAdded(
          food.name,
          food.calories,
          food.protein,
          food.carbs,
          food.fat,
          quantity,
          _servingUnit,
        );
        
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create food'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealProvider>(
      builder: (context, provider, child) {
        if (_selectedCategoryId == null && provider.categories.isNotEmpty) {
          _selectedCategoryId = _getCategoryIdByName(provider, widget.initialCategory);
        }

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Custom Food',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your own food item',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Category selection
                  if (provider.categories.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      items: provider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null) return 'Please select a category';
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Food name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Food Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter food name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Calories
                          TextFormField(
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Calories (per serving) *',
                              border: OutlineInputBorder(),
                              suffixText: 'kcal',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final val = int.tryParse(value);
                              if (val == null || val <= 0) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Protein, Carbs, Fat row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _proteinController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Protein (g) *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _carbsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Carbs (g) *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _fatController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Fat (g) *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    border: const OutlineInputBorder(),
                                    suffixText: _servingUnit,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    final val = double.tryParse(value);
                                    if (val == null || val <= 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Serving unit
                          DropdownButtonFormField<String>(
                            value: _servingUnit,
                            items: _servingUnits.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _servingUnit = value);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Serving Unit',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
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
                          onPressed: _isLoading ? null : _createFood,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
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
                              : const Text('Add Food'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}