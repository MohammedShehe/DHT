// lib/screens/activity_tab.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_models.dart';
import '../models/meal_models.dart';
import '../models/meal_request_models.dart';
import '../models/workout_detail_models.dart';
import '../models/sleep_activity_models.dart';
import '../providers/activity_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/google_fit_provider.dart';
import '../providers/workout_detail_provider.dart';
import '../providers/sleep_activity_provider.dart';
import '../widgets/date_selector.dart';
import '../widgets/progress_chart.dart';
import '../widgets/activity_cards.dart';
import '../widgets/add_meal_dialog.dart';
import '../widgets/add_workout_dialog.dart';
import '../widgets/add_sleep_dialog.dart';
import '../widgets/add_hydration_dialog.dart';
import '../widgets/add_medication_dialog.dart';
import '../widgets/google_fit_connection_widget.dart';
import '../widgets/edit_workout_dialog.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      final workoutProvider = Provider.of<WorkoutDetailProvider>(context, listen: false);
      final sleepProvider = Provider.of<SleepActivityProvider>(context, listen: false);
      
      activityProvider.onShowMessage = (String message, {bool isError = false}) {
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
      
      workoutProvider.onShowMessage = (String message, {bool isError = false}) {
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
      
      sleepProvider.onShowMessage = (String message, {bool isError = false}) {
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
      
      activityProvider.loadActivityData();
      workoutProvider.loadAllData();
      sleepProvider.loadSleepLogForDate(DateTime.now());
      sleepProvider.loadAllStats();
    });
  }

  @override
  void dispose() {
    try {
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      activityProvider.disposeCallbacks();
      
      final workoutProvider = Provider.of<WorkoutDetailProvider>(context, listen: false);
      workoutProvider.disposeCallbacks();
    } catch (e) {}
    _tabController.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final workoutProvider = Provider.of<WorkoutDetailProvider>(context, listen: false);
    final sleepProvider = Provider.of<SleepActivityProvider>(context, listen: false);
    
    activityProvider.setSelectedDate(date);
    workoutProvider.setSelectedDate(date);
    sleepProvider.setSelectedDate(date);
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final workoutProvider = Provider.of<WorkoutDetailProvider>(context, listen: false);
    final sleepProvider = Provider.of<SleepActivityProvider>(context, listen: false);
    
    await Future.wait([
      activityProvider.refreshCurrentDate(),
      workoutProvider.refreshCurrentDate(),
      sleepProvider.loadSleepLogForDate(_selectedDate),
      sleepProvider.loadAllStats(),
    ]);
    
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
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
    ).then((_) => _refreshData());
  }

  void _showAddWorkoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddWorkoutDialog(selectedDate: _selectedDate),
    ).then((_) => _refreshData());
  }

  void _showAddSleepDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSleepDialog(selectedDate: _selectedDate),
    ).then((_) => _refreshData());
  }

  void _showAddHydrationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHydrationDialog(selectedDate: _selectedDate),
    ).then((_) => _refreshData());
  }

  void _showAddMedicationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMedicationDialog(),
    ).then((_) => _refreshData());
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
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00C853),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
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
      body: Column(
        children: [
          Consumer<GoogleFitProvider>(
            builder: (context, fitProvider, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: fitProvider.isConnected ? null : 80,
                child: GoogleFitConnectionWidget(
                  onConnected: () {
                    Provider.of<ActivityProvider>(context, listen: false)
                        .loadActivityData();
                  },
                ),
              );
            },
          ),
          Consumer3<ActivityProvider, WorkoutDetailProvider, SleepActivityProvider>(
            builder: (context, activityProvider, workoutProvider, sleepProvider, child) {
              if (activityProvider.isLoading && activityProvider.meals.isEmpty) {
                return const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00C853),
                    ),
                  ),
                );
              }

              return Expanded(
                child: Column(
                  children: [
                    DateSelector(
                      selectedDate: _selectedDate,
                      onDateChanged: _onDateChanged,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey[100],
                      child: Text(
                        'Showing data for: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          MealsTab(
                            activityProvider: activityProvider,
                            mealProvider: Provider.of<MealProvider>(context),
                            selectedDate: _selectedDate,
                            onRefresh: _refreshData,
                          ),
                          WorkoutsTab(
                            activityProvider: activityProvider,
                            workoutProvider: workoutProvider,
                            selectedDate: _selectedDate,
                            onRefresh: _refreshData,
                          ),
                          SleepTab(onRefresh: _refreshData),
                          HydrationTab(provider: activityProvider, onRefresh: _refreshData),
                          MedicationsTab(provider: activityProvider, onRefresh: _refreshData),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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

class MealsTab extends StatelessWidget {
  final ActivityProvider activityProvider;
  final MealProvider mealProvider;
  final DateTime selectedDate;
  final Future<void> Function() onRefresh;

  const MealsTab({
    super.key,
    required this.activityProvider,
    required this.mealProvider,
    required this.selectedDate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mealProvider.loadTodaysMeals(date: selectedDate);
    });

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF00C853),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      'Daily Nutrition',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (mealProvider.todaysSummary != null) ...[
                      Text(
                        '${mealProvider.todaysSummary!.totalCalories} / 2200 kcal',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (mealProvider.todaysSummary!.totalCalories / 2200).clamp(0.0, 1.0),
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ] else ...[
                      const Text(
                        '0 / 2200 kcal',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ProgressChart.bar(
                        data: activityProvider.weeklyCalories,
                        labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
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
                            '${mealProvider.todaysSummary?.totalProtein.toStringAsFixed(0) ?? '0'}g',
                            150,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildNutrientCard(
                            'Carbs',
                            '${mealProvider.todaysSummary?.totalCarbs.toStringAsFixed(0) ?? '0'}g',
                            300,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildNutrientCard(
                            'Fat',
                            '${mealProvider.todaysSummary?.totalFat.toStringAsFixed(0) ?? '0'}g',
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
                            '${activityProvider.waterGlasses} / 8 glasses',
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Meals for ${DateFormat('MMM d, yyyy').format(selectedDate)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${mealProvider.todaysMeals.length} meals',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (mealProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF00C853)),
                ),
              )
            else if (mealProvider.todaysMeals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No meals logged for this day',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to log your first meal',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...mealProvider.todaysMeals.map((meal) => _buildMealCard(context, meal)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value, int goal, Color color) {
    final numericValue = double.tryParse(value.replaceAll('g', '')) ?? 0;
    final percentage = goal > 0 ? (numericValue / goal * 100).clamp(0, 100) : 0;
    
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

  Widget _buildMealCard(BuildContext context, Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showMealDetails(context, meal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getMealColor(meal.mealType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMealIcon(meal.mealType),
                      color: _getMealColor(meal.mealType),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          meal.formattedTime,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${meal.totalCalories} kcal',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                meal.itemsSummary,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMacroPill('P: ${meal.totalProtein.toStringAsFixed(1)}g', Colors.blue),
                  const SizedBox(width: 8),
                  _buildMacroPill('C: ${meal.totalCarbs.toStringAsFixed(1)}g', Colors.green),
                  const SizedBox(width: 8),
                  _buildMacroPill('F: ${meal.totalFat.toStringAsFixed(1)}g', Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showMealDetails(BuildContext context, Meal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MealDetailsSheet(meal: meal),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.purple;
      case 'snack':
        return Colors.pink;
      case 'brunch':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      case 'brunch':
        return Icons.brunch_dining;
      default:
        return Icons.restaurant;
    }
  }
}

class WorkoutsTab extends StatelessWidget {
  final ActivityProvider activityProvider;
  final WorkoutDetailProvider workoutProvider;
  final DateTime selectedDate;
  final Future<void> Function() onRefresh;

  const WorkoutsTab({
    super.key,
    required this.activityProvider,
    required this.workoutProvider,
    required this.selectedDate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      workoutProvider.setSelectedDate(selectedDate);
    });

    final workouts = workoutProvider.workouts;

    return RefreshIndicator(
      onRefresh: () async {
        await workoutProvider.refreshCurrentDate();
        await onRefresh();
      },
      color: Colors.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Workouts',
                    '${workoutProvider.workoutCount}',
                    Icons.fitness_center,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Duration',
                    '${workoutProvider.totalDuration} min',
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Calories',
                    '${workoutProvider.totalCalories}',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Distance',
                    '${workoutProvider.totalDistance.toStringAsFixed(1)} km',
                    Icons.straighten,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekly Chart
            if (workoutProvider.weeklyStats.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Activity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration in minutes (Mon - Sun)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: workoutProvider.getWeeklyDurationData().isEmpty
                                ? 100
                                : (workoutProvider.getWeeklyDurationData().reduce((a, b) => a > b ? a : b) * 1.2).clamp(10, double.infinity),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final duration = workoutProvider.getWeeklyDurationData()[group.x.toInt()];
                                  return BarTooltipItem(
                                    '${duration.toInt()} min',
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
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
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: workoutProvider.getWeeklyDurationData()[index],
                                    color: Colors.green,
                                    width: 24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Workout List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Workouts for ${DateFormat('MMM d, yyyy').format(selectedDate)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${workouts.length} workouts',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Workout List
            if (workoutProvider.isLoadingWorkouts && workouts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              )
            else if (workouts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No workouts logged for this day',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to log your first workout',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...workouts.map((workout) => _buildWorkoutCard(context, workout)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutDetail workout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showWorkoutDetails(context, workout),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: workout.intensityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: workout.intensityColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${workout.formattedTime} • ${workout.durationMinutes} min',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: workout.intensityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      workout.intensityDisplay,
                      style: TextStyle(
                        color: workout.intensityColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildWorkoutMetric(
                    'Calories',
                    '${workout.caloriesBurned ?? 0}',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  if (workout.distance != null && workout.distance! > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildWorkoutMetric(
                        'Distance',
                        '${workout.distance!.toStringAsFixed(1)} km',
                        Icons.straighten,
                        Colors.blue,
                      ),
                    ),
                  if (workout.heartRate != null && workout.heartRate! > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildWorkoutMetric(
                        'Heart Rate',
                        '${workout.heartRate} bpm',
                        Icons.favorite,
                        Colors.red,
                      ),
                    ),
                ],
              ),
              if (workout.feeling != null && workout.feeling!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: workout.feelingColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sentiment_satisfied,
                          size: 14,
                          color: workout.feelingColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Feeling: ${workout.feelingDisplay}',
                          style: TextStyle(
                            fontSize: 11,
                            color: workout.feelingColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (workout.notes != null && workout.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    workout.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutMetric(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  void _showWorkoutDetails(BuildContext context, WorkoutDetail workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WorkoutDetailsSheet(workout: workout),
    );
  }
}

class _WorkoutDetailsSheet extends StatelessWidget {
  final WorkoutDetail workout;

  const _WorkoutDetailsSheet({required this.workout});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutDetailProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: workout.intensityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: workout.intensityColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(workout.workoutTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Details Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _buildDetailTile('Duration', '${workout.durationMinutes} minutes', Icons.timer, Colors.blue),
              _buildDetailTile('Calories', '${workout.caloriesBurned ?? 0} kcal', Icons.local_fire_department, Colors.orange),
              if (workout.distance != null && workout.distance! > 0)
                _buildDetailTile('Distance', '${workout.distance!.toStringAsFixed(2)} km', Icons.straighten, Colors.green),
              if (workout.heartRate != null && workout.heartRate! > 0)
                _buildDetailTile('Heart Rate', '${workout.heartRate} bpm', Icons.favorite, Colors.red),
              _buildDetailTile('Intensity', workout.intensityDisplay, Icons.speed, workout.intensityColor),
              if (workout.feeling != null && workout.feeling!.isNotEmpty)
                _buildDetailTile('Feeling', workout.feelingDisplay, Icons.sentiment_satisfied, workout.feelingColor),
            ],
          ),

          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                workout.notes!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 24),

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
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditWorkoutDialog(context, workout, workoutProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditWorkoutDialog(BuildContext context, WorkoutDetail workout, WorkoutDetailProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditWorkoutDialog(
        workout: workout,
        workoutProvider: provider,
        onUpdated: () {
          provider.refreshCurrentDate();
        },
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SleepTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const SleepTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepActivityProvider>(
      builder: (context, provider, child) {
        final sleepLog = provider.currentSleepLog;
        
        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadSleepLogForDate(provider.selectedDate);
            await provider.loadAllStats();
            await onRefresh();
          },
          color: Colors.purple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sleep Duration Card
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
                          '${provider.getWeeklyDurationData().reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} / 8 hours (peak)',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _buildWeeklySleepChart(provider),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sleep Log for selected date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sleep for ${DateFormat('MMM d, yyyy').format(provider.selectedDate)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    if (sleepLog != null)
                      TextButton.icon(
                        onPressed: () => _showEditSleepDialog(context, provider),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Colors.purple),
                    ),
                  )
                else if (sleepLog != null)
                  _buildSleepLogCard(context, sleepLog, provider)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.bedtime, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No sleep data for this day',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to log your sleep',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySleepChart(SleepActivityProvider provider) {
    final durationData = provider.getWeeklyDurationData();
    final labels = provider.getWeekLabels();
    final maxDuration = durationData.isEmpty ? 8 : durationData.reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 180,
      child: Row(
        children: List.generate(7, (index) {
          final barHeight = maxDuration > 0 ? ((durationData[index] / maxDuration) * 140).toDouble() : 0.0;
          return Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 24,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: durationData[index] > 0 ? Colors.purple : Colors.grey[300],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: durationData[index] > 0 ? Colors.black : Colors.grey[500],
                  ),
                ),
                Text(
                  durationData[index].toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSleepLogCard(BuildContext context, SleepLog sleepLog, SleepActivityProvider provider) {
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: sleepLog.qualityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.bedtime, color: sleepLog.qualityColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sleepLog.totalHours.toStringAsFixed(1)} hours',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sleepLog.qualityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sleepLog.qualityDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: sleepLog.qualityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(context, provider);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Bedtime and Wake time
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    'Bedtime',
                    sleepLog.formattedBedtime,
                    Icons.nightlight_round,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard(
                    'Wake up',
                    sleepLog.formattedWakeTime,
                    Icons.wb_sunny,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Interruptions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text('Interruptions'),
                    ],
                  ),
                  Text(
                    '${sleepLog.interruptions} times',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            if (sleepLog.notes != null && sleepLog.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sleepLog.notes!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color) {
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

  void _showEditSleepDialog(BuildContext context, SleepActivityProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSleepDialog(
        selectedDate: provider.selectedDate,
        existingSleepLog: provider.currentSleepLog,
      ),
    ).then((_) {
      provider.loadSleepLogForDate(provider.selectedDate);
      provider.loadAllStats();
    });
  }

  void _showDeleteConfirmation(BuildContext context, SleepActivityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sleep Log'),
        content: const Text('Are you sure you want to delete this sleep log? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteCurrentSleepLog();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class HydrationTab extends StatelessWidget {
  final ActivityProvider provider;
  final Future<void> Function() onRefresh;

  const HydrationTab({super.key, required this.provider, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final goalAmount = 2500;
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: goalAmount > 0 ? provider.totalWaterIntake / goalAmount : 0,
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
                                'of ${goalAmount}ml',
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
                        labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                        color: Colors.blue,
                        title: 'Weekly Hydration',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              "Hydration for ${DateFormat('MMM d, yyyy').format(provider.selectedDate)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                        'No hydration entries for this day',
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
  final Future<void> Function() onRefresh;

  const MedicationsTab({super.key, required this.provider, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final today = provider.selectedDate;
    final todaysMeds = provider.getMedicationsForDate(today);
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.purple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            
            Text(
              "Medications for ${DateFormat('MMM d, yyyy').format(today)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                        'No medications scheduled for this day',
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
    
    final today = provider.selectedDate;
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
    final average = data.isEmpty ? 0 : (data.reduce((a, b) => a + b) / data.length);
    final total = data.isEmpty ? 0 : data.reduce((a, b) => a + b);
    
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
                    'Avg: ${average.toStringAsFixed(1)} $unit',
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
                  maxY: data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b) * 1.2,
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
              'Total: ${total.toStringAsFixed(1)} $unit',
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

class _MealDetailsSheet extends StatelessWidget {
  final Meal meal;

  const _MealDetailsSheet({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getMealColor(meal.mealType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMealIcon(meal.mealType),
                  color: _getMealColor(meal.mealType),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealType,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(meal.mealTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Calories', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${meal.totalCalories} kcal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailNutrient('Protein', '${meal.totalProtein.toStringAsFixed(1)}g', Colors.blue),
                    _buildDetailNutrient('Carbs', '${meal.totalCarbs.toStringAsFixed(1)}g', Colors.green),
                    _buildDetailNutrient('Fat', '${meal.totalFat.toStringAsFixed(1)}g', Colors.orange),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Food Items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          ...meal.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, size: 18, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.customFoodName ?? item.foodName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${item.quantity.toStringAsFixed(1)} ${item.servingUnit}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.calories} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )).toList(),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.purple;
      case 'snack':
        return Colors.pink;
      case 'brunch':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      case 'brunch':
        return Icons.brunch_dining;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildDetailNutrient(String label, String value, Color color) {
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
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}