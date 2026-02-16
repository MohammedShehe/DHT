import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/activity_service.dart';
import '../models/activity_models.dart';
import '../widgets/date_selector.dart';
import '../widgets/progress_chart.dart';
import '../widgets/activity_cards.dart';
import '../providers/activity_provider.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Sample data - replace with actual data from service
  final Map<String, dynamic> _mealData = {
    'totalCalories': 1850,
    'goalCalories': 2200,
    'protein': 65,
    'carbs': 210,
    'fat': 55,
    'water': 4,
    'meals': [
      {'type': 'Breakfast', 'calories': 450, 'time': '08:30 AM', 'items': 'Oatmeal, Banana, Coffee'},
      {'type': 'Lunch', 'calories': 650, 'time': '01:00 PM', 'items': 'Grilled Chicken Salad'},
      {'type': 'Snack', 'calories': 250, 'time': '04:30 PM', 'items': 'Greek Yogurt, Apple'},
      {'type': 'Dinner', 'calories': 500, 'time': '07:45 PM', 'items': 'Salmon, Quinoa, Veggies'},
    ]
  };

  final Map<String, dynamic> _workoutData = {
    'totalMinutes': 65,
    'goalMinutes': 60,
    'caloriesBurned': 450,
    'workouts': [
      {'type': 'Morning Run', 'duration': 25, 'calories': 180, 'time': '07:00 AM', 'intensity': 'Moderate'},
      {'type': 'Weight Training', 'duration': 40, 'calories': 270, 'time': '06:00 PM', 'intensity': 'High'},
    ]
  };

  final Map<String, dynamic> _sleepData = {
    'totalHours': 7.5,
    'goalHours': 8,
    'quality': 'Good',
    'deepSleep': 2.5,
    'remSleep': 1.8,
    'lightSleep': 3.2,
    'bedTime': '11:00 PM',
    'wakeTime': '06:30 AM',
    'interruptions': 2,
  };

  // Weekly data for charts
  final List<double> _weeklyCalories = [1650, 1800, 2100, 1950, 1850, 2000, 1750];
  final List<double> _weeklyWorkoutMinutes = [45, 60, 30, 70, 0, 55, 65];
  final List<double> _weeklySleepHours = [6.5, 7.0, 8.0, 7.5, 6.0, 8.5, 7.5];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    setState(() => _isLoading = true);
    try {
      // Load data from service
      // final meals = await ActivityService.getMeals(_selectedDate);
      // final workouts = await ActivityService.getWorkouts(_selectedDate);
      // final sleep = await ActivityService.getSleep(_selectedDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadActivityData();
  }

  void _showAddMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMealDialog(),
    ).then((_) => _loadActivityData());
  }

  void _showAddWorkoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddWorkoutDialog(),
    ).then((_) => _loadActivityData());
  }

  void _showAddSleepDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSleepDialog(),
    ).then((_) => _loadActivityData());
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
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Meals'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
            Tab(icon: Icon(Icons.bedtime), text: 'Sleep'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDatePicker(),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _showWeeklySummary(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : Column(
              children: [
                // Date Selector
                DateSelector(
                  selectedDate: _selectedDate,
                  onDateChanged: _onDateChanged,
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Meals Tab
                      _buildMealsTab(),
                      
                      // Workouts Tab
                      _buildWorkoutsTab(),
                      
                      // Sleep Tab
                      _buildSleepTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddMealDialog();
          } else if (_tabController.index == 1) {
            _showAddWorkoutDialog();
          } else {
            _showAddSleepDialog();
          }
        },
        backgroundColor: const Color(0xFF00C853),
        child: Icon(
          _tabController.index == 0 ? Icons.restaurant :
          _tabController.index == 1 ? Icons.fitness_center :
          Icons.bedtime,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMealsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Chart
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
                    '${_mealData['totalCalories']} / ${_mealData['goalCalories']} kcal',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart.bar(
                      data: _weeklyCalories,
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

          // Macronutrients
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
                          '${_mealData['protein']}g',
                          150,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildNutrientCard(
                          'Carbs',
                          '${_mealData['carbs']}g',
                          300,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildNutrientCard(
                          'Fat',
                          '${_mealData['fat']}g',
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

          // Water Intake
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
                          '${_mealData['water']} / 8 glasses',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00C853)),
                    onPressed: () {
                      setState(() {
                        _mealData['water'] = (_mealData['water'] + 1).clamp(0, 8);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Today's Meals
          const Text(
            "Today's Meals",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...List.generate(_mealData['meals'].length, (index) {
            final meal = _mealData['meals'][index];
            return ActivityCard.meal(
              meal: Meal(
                id: index.toString(),
                type: meal['type'],
                calories: meal['calories'],
                time: meal['time'],
                items: meal['items'],
              ),
              onTap: () => _showMealDetails(meal),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Chart
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
                    '${_workoutData['totalMinutes']} / ${_workoutData['goalMinutes']} minutes',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart.line(
                      data: _weeklyWorkoutMinutes,
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

          // Summary Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Calories Burned',
                  '${_workoutData['caloriesBurned']}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Minutes',
                  '${_workoutData['totalMinutes']}',
                  Icons.timer,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Today's Workouts
          const Text(
            "Today's Workouts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...List.generate(_workoutData['workouts'].length, (index) {
            final workout = _workoutData['workouts'][index];
            return ActivityCard.workout(
              workout: Workout(
                id: index.toString(),
                type: workout['type'],
                duration: workout['duration'],
                calories: workout['calories'],
                time: workout['time'],
                intensity: workout['intensity'],
              ),
              onTap: () => _showWorkoutDetails(workout),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSleepTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Chart
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
                    '${_sleepData['totalHours']} / ${_sleepData['goalHours']} hours',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ProgressChart.bar(
                      data: _weeklySleepHours,
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

          // Sleep Quality
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
                          color: _getSleepQualityColor(_sleepData['quality']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _sleepData['quality'],
                          style: TextStyle(
                            color: _getSleepQualityColor(_sleepData['quality']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSleepStageRow('Deep Sleep', _sleepData['deepSleep'], Colors.purple),
                  _buildSleepStageRow('REM Sleep', _sleepData['remSleep'], Colors.blue),
                  _buildSleepStageRow('Light Sleep', _sleepData['lightSleep'], Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sleep Schedule
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
                          _sleepData['bedTime'],
                          Icons.nightlight_round,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSleepTimeCard(
                          'Wake up',
                          _sleepData['wakeTime'],
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
                          '${_sleepData['interruptions']} times',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value, int goal, Color color) {
    final percentage = (int.parse(value.replaceAll('g', '')) / goal * 100).clamp(0, 100);
    
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

  Widget _buildSleepStageRow(String label, double hours, Color color) {
    final percentage = (hours / _sleepData['totalHours'] * 100).round();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600])),
              Text('${hours}h ($percentage%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: hours / _sleepData['totalHours'],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
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
                    _weeklyCalories,
                    Colors.orange,
                    'kcal',
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyStatCard(
                    'Workouts',
                    _weeklyWorkoutMinutes,
                    Colors.green,
                    'min',
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyStatCard(
                    'Sleep',
                    _weeklySleepHours,
                    Colors.purple,
                    'h',
                  ),
                ],
              ),
            ),
          ],
        ),
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

  void _showMealDetails(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meal['type']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Time', meal['time']),
            _buildDetailRow('Calories', '${meal['calories']} kcal'),
            _buildDetailRow('Items', meal['items']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Edit functionality
            },
            child: const Text('Edit', style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
  }

  void _showWorkoutDetails(Map<String, dynamic> workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workout['type']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Time', workout['time']),
            _buildDetailRow('Duration', '${workout['duration']} min'),
            _buildDetailRow('Calories', '${workout['calories']} kcal'),
            _buildDetailRow('Intensity', workout['intensity']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Edit functionality
            },
            child: const Text('Edit', style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

// Add Meal Dialog
class AddMealDialog extends StatefulWidget {
  const AddMealDialog({super.key});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  String _mealType = 'Breakfast';
  final _foodItemsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Brunch',
  ];

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
                const Text(
                  'Log Meal',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
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
                      const SizedBox(height: 8),

                      // Food Items
                      TextFormField(
                        controller: _foodItemsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Food Items',
                          hintText: 'Enter food items (one per line)',
                          prefixIcon: Icon(Icons.fastfood),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter food items';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Calories
                      TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Calories',
                          prefixIcon: Icon(Icons.local_fire_department),
                          suffixText: 'kcal',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter calories';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Macronutrients (Optional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // Protein
                      TextFormField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein',
                          prefixIcon: Icon(Icons.fitness_center),
                          suffixText: 'g',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Carbs
                      TextFormField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Carbohydrates',
                          prefixIcon: Icon(Icons.energy_savings_leaf),
                          suffixText: 'g',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Fat
                      TextFormField(
                        controller: _fatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fat',
                          prefixIcon: Icon(Icons.oil_barrel),
                          suffixText: 'g',
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Save meal
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Meal logged successfully!'),
                                backgroundColor: Color(0xFF00C853),
                              ),
                            );
                          }
                        },
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
}

// Add Workout Dialog
class AddWorkoutDialog extends StatefulWidget {
  const AddWorkoutDialog({super.key});

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _workoutTypeController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _intensity = 'Moderate';
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _intensityLevels = ['Low', 'Moderate', 'High', 'Very High'];

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
                  'Log Workout',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Workout Type
                      TextFormField(
                        controller: _workoutTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Workout Type',
                          hintText: 'e.g., Running, Weight Training',
                          prefixIcon: Icon(Icons.fitness_center),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter workout type';
                          }
                          return null;
                        },
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
                      const SizedBox(height: 8),

                      // Duration
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                          prefixIcon: Icon(Icons.timer),
                          suffixText: 'minutes',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Calories Burned
                      TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories Burned (Optional)',
                          prefixIcon: Icon(Icons.local_fire_department),
                          suffixText: 'kcal',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Intensity
                      DropdownButtonFormField<String>(
                        value: _intensity,
                        items: _intensityLevels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _intensity = value!),
                        decoration: const InputDecoration(
                          labelText: 'Intensity',
                          prefixIcon: Icon(Icons.speed),
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Save workout
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Workout logged successfully!'),
                                backgroundColor: Color(0xFF00C853),
                              ),
                            );
                          }
                        },
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
}

// Add Sleep Dialog
class AddSleepDialog extends StatefulWidget {
  const AddSleepDialog({super.key});

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
                        onPressed: () {
                          // Calculate sleep duration
                          final now = DateTime.now();
                          final bedDateTime = DateTime(
                            now.year, now.month, now.day,
                            _bedTime.hour, _bedTime.minute,
                          );
                          final wakeDateTime = DateTime(
                            now.year, now.month, now.day,
                            _wakeTime.hour, _wakeTime.minute,
                          );
                          
                          Duration sleepDuration;
                          if (wakeDateTime.isBefore(bedDateTime)) {
                            sleepDuration = wakeDateTime
                                .add(const Duration(days: 1))
                                .difference(bedDateTime);
                          } else {
                            sleepDuration = wakeDateTime.difference(bedDateTime);
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sleep logged! Duration: ${sleepDuration.inHours}h ${sleepDuration.inMinutes % 60}m',
                              ),
                              backgroundColor: const Color(0xFF00C853),
                            ),
                          );
                        },
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
}