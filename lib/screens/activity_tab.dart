// lib/screens/activity_tab.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_models.dart';
import '../providers/activity_provider.dart';
import '../widgets/date_selector.dart';
import '../widgets/progress_chart.dart';
import '../widgets/activity_cards.dart';
import '../widgets/add_meal_dialog.dart';
import '../widgets/add_workout_dialog.dart';
import '../widgets/add_sleep_dialog.dart';
import '../widgets/add_hydration_dialog.dart';
import '../widgets/add_medication_dialog.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Set up message callback for the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      provider.onShowMessage = (String message, {bool isError = false}) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.red : Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      };
      
      // Load initial data
      provider.loadActivityData();
    });
  }

  @override
  void dispose() {
    // Clean up the callback
    try {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      provider.disposeCallbacks();
    } catch (e) {
      // Provider might not be available during dispose
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    provider.setSelectedDate(date);
  }

  void _showAddMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMealDialog(
        selectedDate: _selectedDate,
        mealType: _tabController.index == 0 ? null : 
                  _tabController.index == 1 ? 'Lunch' :
                  _tabController.index == 2 ? 'Dinner' :
                  _tabController.index == 3 ? 'Snack' : 'Breakfast',
      ),
    );
  }

  void _showAddWorkoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddWorkoutDialog(),
    );
  }

  void _showAddSleepDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSleepDialog(),
    );
  }

  void _showAddHydrationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHydrationDialog(
        selectedDate: _selectedDate,
      ),
    );
  }

  void _showAddMedicationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMedicationDialog(),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00C853),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      _onDateChanged(picked);
    }
  }

  void _showWeeklySummary() {
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WeeklySummarySheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity Logging',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00C853),
          labelColor: const Color(0xFF00C853),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Meals'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
            Tab(icon: Icon(Icons.bedtime), text: 'Sleep'),
            Tab(icon: Icon(Icons.local_drink), text: 'Hydration'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showWeeklySummary,
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C853),
              ),
            );
          }

          return Column(
            children: [
              DateSelector(
                selectedDate: _selectedDate,
                onDateChanged: _onDateChanged,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    MealsTab(provider: provider),
                    WorkoutsTab(provider: provider),
                    SleepTab(provider: provider),
                    HydrationTab(provider: provider),
                    MedicationsTab(provider: provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddMealDialog();
          } else if (_tabController.index == 1) {
            _showAddWorkoutDialog();
          } else if (_tabController.index == 2) {
            _showAddSleepDialog();
          } else if (_tabController.index == 3) {
            _showAddHydrationDialog();
          } else {
            _showAddMedicationDialog();
          }
        },
        backgroundColor: const Color(0xFF00C853),
        child: Icon(
          _tabController.index == 0 ? Icons.restaurant :
          _tabController.index == 1 ? Icons.fitness_center :
          _tabController.index == 2 ? Icons.bedtime :
          _tabController.index == 3 ? Icons.local_drink :
          Icons.medication,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Individual Tab Widgets
class MealsTab extends StatelessWidget {
  final ActivityProvider provider;

  const MealsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calorie Intake',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.totalCalories} / 2200 kcal',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart.bar(
                      data: provider.weeklyCalories,
                      labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                      color: Colors.orange,
                      title: 'Weekly Calories',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Macronutrients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutrientCard(
                          'Protein',
                          '${provider.totalProtein.toStringAsFixed(0)}g',
                          150,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildNutrientCard(
                          'Carbs',
                          '${provider.totalCarbs.toStringAsFixed(0)}g',
                          300,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildNutrientCard(
                          'Fat',
                          '${provider.totalFat.toStringAsFixed(0)}g',
                          70,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop, color: Colors.blue, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Water Intake',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.waterGlasses} / 8 glasses',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            "Today's Meals",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          if (provider.meals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.restaurant, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No meals logged today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.meals.map((meal) => ActivityCard.meal(
              meal: meal,
              onTap: () => _showMealDetails(context, meal),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value, int goal, Color color) {
    final numericValue = double.tryParse(value.replaceAll('g', '')) ?? 0;
    final percentage = (numericValue / goal * 100).clamp(0, 100);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  void _showMealDetails(BuildContext context, Meal meal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MealDetailsSheet(meal: meal),
    );
  }
}

class WorkoutsTab extends StatelessWidget {
  final ActivityProvider provider;

  const WorkoutsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Duration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.totalWorkoutMinutes} / 60 minutes',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart.line(
                      data: provider.weeklyWorkoutMinutes,
                      labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                      color: Colors.green,
                      title: 'Weekly Workouts',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Calories Burned',
                  '${provider.totalCaloriesBurned}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Minutes',
                  '${provider.totalWorkoutMinutes}',
                  Icons.timer,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            "Today's Workouts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          if (provider.workouts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No workouts logged today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.workouts.map((workout) => ActivityCard.workout(
              workout: workout,
              onTap: () => _showWorkoutDetails(context, workout),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkoutDetails(BuildContext context, Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workout.type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Time', workout.time),
            _buildInfoRow('Duration', '${workout.duration} min'),
            _buildInfoRow('Calories', '${workout.calories} kcal'),
            _buildInfoRow('Intensity', workout.intensity),
            if (workout.notes != null) _buildInfoRow('Notes', workout.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class SleepTab extends StatelessWidget {
  final ActivityProvider provider;

  const SleepTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final sleep = provider.sleep.isNotEmpty ? provider.sleep.first : null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Duration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.totalSleepHours.toStringAsFixed(1)} / 8 hours',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart.bar(
                      data: provider.weeklySleepHours,
                      labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                      color: Colors.purple,
                      title: 'Weekly Sleep',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (sleep != null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sleep Quality',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getSleepQualityColor(sleep.quality).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sleep.quality,
                            style: TextStyle(
                              color: _getSleepQualityColor(sleep.quality),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sleep.deepSleep != null)
                      _buildSleepStageRow('Deep Sleep', sleep.deepSleep!, sleep.duration, Colors.purple),
                    if (sleep.remSleep != null)
                      _buildSleepStageRow('REM Sleep', sleep.remSleep!, sleep.duration, Colors.blue),
                    if (sleep.lightSleep != null)
                      _buildSleepStageRow('Light Sleep', sleep.lightSleep!, sleep.duration, Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSleepTimeCard(
                            'Bedtime',
                            '${sleep.bedTime.hour.toString().padLeft(2, '0')}:${sleep.bedTime.minute.toString().padLeft(2, '0')}',
                            Icons.nightlight_round,
                            Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSleepTimeCard(
                            'Wake up',
                            '${sleep.wakeTime.hour.toString().padLeft(2, '0')}:${sleep.wakeTime.minute.toString().padLeft(2, '0')}',
                            Icons.wb_sunny,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Interruptions'),
                          Text(
                            '${sleep.interruptions} times',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.bedtime, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No sleep data for today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getSleepQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSleepStageRow(String label, double hours, double total, Color color) {
    final percentage = (hours / total * 100).round();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600])),
              Text('${hours.toStringAsFixed(1)}h ($percentage%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: hours / total,
            backgroundColor: color.withOpacity(0.2),
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimeCard(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class HydrationTab extends StatelessWidget {
  final ActivityProvider provider;

  const HydrationTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final goalAmount = 2500; // 8 glasses * 250ml
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Water Intake',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.water_drop, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.waterGlasses} glasses',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress circle
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: provider.totalWaterIntake / goalAmount,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            color: Colors.blue,
                            strokeWidth: 12,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${provider.totalWaterIntake}ml',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'of ${goalAmount}ml', // Fixed: Use goalAmount variable directly
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Weekly chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Hydration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart.bar(
                      data: provider.weeklyHydration,
                      labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                      color: Colors.blue,
                      title: 'Weekly Hydration',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Today's entries
          const Text(
            "Today's Entries",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          if (provider.hydration.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.water_drop, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No hydration entries today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.hydration.map((entry) => _buildHydrationEntryCard(context, entry, provider)).toList(),
        ],
      ),
    );
  }

  Widget _buildHydrationEntryCard(BuildContext context, Hydration entry, ActivityProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.water_drop, color: Colors.blue),
        ),
        title: Text('${entry.amount}ml ${entry.type ?? 'Water'}'),
        subtitle: Text(DateFormat.jm().format(entry.time)),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              provider.deleteHydration(entry.id);
            }
          },
        ),
      ),
    );
  }
}

class MedicationsTab extends StatelessWidget {
  final ActivityProvider provider;

  const MedicationsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todaysMeds = provider.getMedicationsForDate(today);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication, color: Colors.purple, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medication Adherence',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getTakenCount(todaysMeds)}/${_getTotalDoses(todaysMeds)} doses taken today',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.getTodaysAdherence().round()}%',
                      style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Active medications
          const Text(
            'Today\'s Medications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          if (todaysMeds.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.medication, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No medications scheduled for today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...todaysMeds.map((medication) => _buildMedicationCard(context, medication, provider)).toList(),
        ],
      ),
    );
  }

  int _getTotalDoses(List<Medication> medications) {
    int total = 0;
    for (var med in medications) {
      total += med.scheduledTimes.length;
    }
    return total;
  }

  int _getTakenCount(List<Medication> medications) {
    int taken = 0;
    for (var med in medications) {
      for (var t in med.taken) {
        if (t) taken++;
      }
    }
    return taken;
  }

  Widget _buildMedicationCard(BuildContext context, Medication medication, ActivityProvider provider) {
    final color = medication.color != null 
        ? Color(int.parse(medication.color!.replaceFirst('#', '0xff')))
        : Colors.purple;
    
    // Filter times for today only
    final today = DateTime.now();
    final todayTimes = <int, DateTime>{};
    for (int i = 0; i < medication.scheduledTimes.length; i++) {
      final time = medication.scheduledTimes[i];
      if (time.year == today.year &&
          time.month == today.month &&
          time.day == today.day) {
        todayTimes[i] = time;
      }
    }
    
    if (todayTimes.isEmpty) return const SizedBox();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${medication.dosage}${medication.unit}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (medication.prescribedBy != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      medication.prescribedBy!,
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            if (medication.instructions != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        medication.instructions!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Doses
            const Text(
              "Today's Doses",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            
            ...todayTimes.entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              final taken = index < medication.taken.length ? medication.taken[index] : false;
              return _buildDoseTile(
                context,
                DateFormat.jm().format(time),
                taken,
                color,
                () {
                  provider.markMedicationTaken(medication.id, index, !taken);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseTile(BuildContext context, String time, bool taken, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: taken ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: taken ? color.withOpacity(0.3) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              taken ? Icons.check_circle : Icons.radio_button_unchecked,
              color: taken ? color : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: taken ? FontWeight.w600 : FontWeight.normal,
                color: taken ? color : Colors.grey[700],
              ),
            ),
            const Spacer(),
            if (taken)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Taken',
                  style: TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Bottom Sheets
class MealDetailsSheet extends StatelessWidget {
  final Meal meal;

  const MealDetailsSheet({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFF00C853)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.type,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meal.time,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Nutrition Facts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          _buildNutrientDetailRow('Calories', '${meal.calories} kcal', Colors.orange),
          if (meal.protein != null)
            _buildNutrientDetailRow('Protein', '${meal.protein}g', Colors.blue),
          if (meal.carbs != null)
            _buildNutrientDetailRow('Carbohydrates', '${meal.carbs}g', Colors.green),
          if (meal.fat != null)
            _buildNutrientDetailRow('Fat', '${meal.fat}g', Colors.red),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          
          const Text(
            'Food Items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            meal.items,
            style: const TextStyle(fontSize: 14),
          ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              label == 'Calories' ? Icons.local_fire_department :
              label == 'Protein' ? Icons.fitness_center :
              label == 'Carbohydrates' ? Icons.energy_savings_leaf :
              Icons.oil_barrel,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class WeeklySummarySheet extends StatelessWidget {
  final ActivityProvider provider;

  const WeeklySummarySheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Weekly Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildWeeklyStatCard(
                  'Calories',
                  provider.weeklyCalories,
                  Colors.orange,
                  'kcal',
                ),
                const SizedBox(height: 16),
                _buildWeeklyStatCard(
                  'Workouts',
                  provider.weeklyWorkoutMinutes,
                  Colors.green,
                  'min',
                ),
                const SizedBox(height: 16),
                _buildWeeklyStatCard(
                  'Sleep',
                  provider.weeklySleepHours,
                  Colors.purple,
                  'h',
                ),
                const SizedBox(height: 16),
                _buildWeeklyStatCard(
                  'Hydration',
                  provider.weeklyHydration,
                  Colors.blue,
                  'ml',
                ),
                const SizedBox(height: 16),
                _buildMedicationWeeklyCard(context, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatCard(String title, List<double> data, Color color, String unit) {
    final average = (data.reduce((a, b) => a + b) / data.length).toStringAsFixed(1);
    final total = data.reduce((a, b) => a + b).toStringAsFixed(1);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Avg: $average $unit',
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data[index],
                          color: color,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: $total $unit',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationWeeklyCard(BuildContext context, ActivityProvider provider) {
    final todayMeds = provider.getMedicationsForDate(DateTime.now());
    final totalDoses = todayMeds.fold(0, (sum, med) => sum + med.scheduledTimes.length);
    final takenDoses = todayMeds.fold(0, (sum, med) => sum + med.taken.where((t) => t).length);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Medication Adherence',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today: ${provider.getTodaysAdherence().round()}%',
                    style: const TextStyle(color: Colors.purple, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total doses: $totalDoses',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Taken: $takenDoses',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${provider.getTodaysAdherence().round()}%',
                    style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}