import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/smart_reminder_provider.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_models.dart';
import '../models/smart_reminder_model.dart';
import '../widgets/add_hydration_dialog.dart';
import '../widgets/add_meal_dialog.dart';
import '../widgets/add_workout_dialog.dart';
import '../widgets/add_sleep_dialog.dart';
import '../widgets/add_medication_dialog.dart';
import 'activity_tab.dart';
import 'gamification_tab.dart';
import '../models/gamification_models.dart' as gamification;

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _loadUserName();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      dashboardProvider.onShowMessage = (String message, {bool isError = false}) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.red : Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
      
      _animationController.forward();
      
      // Load smart reminders
      final reminderProvider = Provider.of<SmartReminderProvider>(context, listen: false);
      reminderProvider.loadReminders();
    });
  }

  Future<void> _loadUserName() async {
    try {
      final email = await AuthService.getUserEmail();
      
      if (email != null && email.isNotEmpty) {
        final namePart = email.split('@')[0];
        final cleanName = namePart.replaceAll(RegExp(r'[0-9]'), '');
        final displayName = cleanName.isNotEmpty 
            ? cleanName[0].toUpperCase() + cleanName.substring(1).toLowerCase()
            : 'User';
        setState(() {
          _userName = displayName;
        });
      } else {
        setState(() {
          _userName = 'User';
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      setState(() {
        _userName = 'User';
      });
    }
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.disposeCallbacks();
    } catch (e) {
      // Provider might not be available
    }
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToActivityTab({int tabIndex = 0}) {
    // Update the bottom navigation bar to activity tab with specific index
    // This assumes the parent HomeDashboard has a method to change tabs
    // For now, we'll just show a snackbar and rely on the actual navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Activity Tab...'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // In a real app, you would update the bottom nav bar index
    // This would need to be handled by the parent widget
    // For now, we'll just navigate to the ActivityTab directly
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const ActivityTab()),
    // );
  }

  void _navigateToGamificationTab({int tabIndex = 0}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Gamification Tab...'),
        backgroundColor: Colors.amber,
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQuickLogOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Log',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildQuickLogOption(
              'Log Steps',
              Icons.directions_walk,
              Colors.blue,
              () {
                Navigator.pop(context);
                _showLogStepsDialog();
              },
            ),
            _buildQuickLogOption(
              'Log Water',
              Icons.local_drink,
              Colors.cyan,
              () {
                Navigator.pop(context);
                _showAddHydrationDialog();
              },
            ),
            _buildQuickLogOption(
              'Log Sleep',
              Icons.bedtime,
              Colors.purple,
              () {
                Navigator.pop(context);
                _showAddSleepDialog();
              },
            ),
            _buildQuickLogOption(
              'Log Meditation',
              Icons.self_improvement,
              Colors.indigo,
              () {
                Navigator.pop(context);
                _showLogMeditationDialog();
              },
            ),
            _buildQuickLogOption(
              'Log Meal',
              Icons.restaurant,
              Colors.green,
              () {
                Navigator.pop(context);
                _showAddMealDialog();
              },
            ),
            _buildQuickLogOption(
              'Log Workout',
              Icons.fitness_center,
              Colors.orange,
              () {
                Navigator.pop(context);
                _showAddWorkoutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogStepsDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Steps'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the number of steps you walked:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Steps',
                border: OutlineInputBorder(),
                suffixText: 'steps',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final steps = int.tryParse(controller.text);
              if (steps != null && steps > 0) {
                final provider = Provider.of<GamificationProvider>(context, listen: false);
                provider.logActivityProgress(
                  type: gamification.GoalType.steps,
                  value: steps.toDouble(),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Steps'),
          ),
        ],
      ),
    );
  }

  void _showLogMeditationDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Meditation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter meditation duration in minutes:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                final provider = Provider.of<GamificationProvider>(context, listen: false);
                provider.logActivityProgress(
                  type: gamification.GoalType.meditation,
                  value: minutes.toDouble(),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Meditation'),
          ),
        ],
      ),
    );
  }

  void _showAddHydrationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHydrationDialog(),
    );
  }

  void _showAddMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMealDialog(),
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

  void _showAddMedicationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMedicationDialog(),
    );
  }

  void _showFullWeeklySummary() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
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
              'Weekly Activity Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 6)))} - ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailedStatCard(
                      'Steps',
                      provider.weeklySummary?['steps'] ?? [0, 0, 0, 0, 0, 0, 0],
                      Colors.blue,
                      'steps',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailedStatCard(
                      'Water',
                      provider.weeklySummary?['water'] ?? [0, 0, 0, 0, 0, 0, 0],
                      Colors.cyan,
                      'glasses',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailedStatCard(
                      'Sleep',
                      provider.weeklySummary?['sleep'] ?? [0, 0, 0, 0, 0, 0, 0],
                      Colors.purple,
                      'hours',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailedStatCard(
                      'Meditation',
                      provider.weeklySummary?['meditation'] ?? [0, 0, 0, 0, 0, 0, 0],
                      Colors.indigo,
                      'minutes',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatCard(String title, List<dynamic> data, Color color, String unit) {
    final numericData = data.map((e) => e is int ? e.toDouble() : (e as double?) ?? 0.0).toList();
    final total = numericData.reduce((a, b) => a + b);
    final average = total / numericData.length;
    
    // Format based on unit
    String formattedTotal;
    if (unit == 'hours') {
      formattedTotal = total.toStringAsFixed(1);
    } else {
      formattedTotal = total.toInt().toString();
    }
    
    String formattedAvg;
    if (unit == 'hours') {
      formattedAvg = average.toStringAsFixed(1);
    } else {
      formattedAvg = average.toInt().toString();
    }

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
                    'Avg: $formattedAvg $unit',
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: $formattedTotal $unit',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Row(
                children: List.generate(numericData.length, (index) {
                  final maxValue = numericData.reduce((a, b) => a > b ? a : b);
                  final barHeight = maxValue > 0 
                      ? (numericData[index] / maxValue) * 60 
                      : 0.0;
                  
                  return Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 12,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: numericData[index] > 0 ? color : Colors.grey[300],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                          style: TextStyle(
                            fontSize: 10,
                            color: numericData[index] > 0 ? Colors.black : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogOption(String label, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Smart Reminder Bell
          Consumer<SmartReminderProvider>(
            builder: (context, reminderProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      _showRemindersDialog(context, reminderProvider);
                    },
                  ),
                  if (reminderProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${reminderProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<DashboardProvider>(context, listen: false);
              provider.loadDashboardData();
              
              Provider.of<ActivityProvider>(context, listen: false).loadActivityData();
              Provider.of<GamificationProvider>(context, listen: false).loadGoals();
              
              // Refresh smart reminders
              Provider.of<SmartReminderProvider>(context, listen: false).loadReminders(forceRefresh: true);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard refreshed'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<DashboardProvider, SmartReminderProvider>(
        builder: (context, provider, reminderProvider, child) {
          if (provider.isLoading && provider.summary == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C853),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadDashboardData();
              await reminderProvider.loadReminders(forceRefresh: true);
            },
            color: const Color(0xFF00C853),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(provider.summary),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildTodaySummary(provider.summary),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(provider.weeklySummary),
                  const SizedBox(height: 24),
                  _buildRecentActivities(provider.recentActivities),
                  const SizedBox(height: 24),
                  _buildSmartReminders(reminderProvider),
                  const SizedBox(height: 24),
                  _buildHealthTips(provider.healthTips),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickLogOptions,
        backgroundColor: const Color(0xFF00C853),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeCard(DashboardSummary? summary) {
    final displayName = _userName.isNotEmpty ? _userName : 'User';
    
    if (summary == null) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00C853).withOpacity(0.9),
                const Color(0xFF00E676),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              'Welcome back, $displayName!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00C853).withOpacity(0.9),
              const Color(0xFF00E676),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.greeting}, $displayName!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level ${summary.level} · ${summary.totalPoints} points',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to gamification tab to see streaks
                    _navigateToGamificationTab(tabIndex: 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${summary.currentStreak} day streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (summary.levelProgress > 0) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '${(summary.levelProgress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: summary.levelProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 6,
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to activity tab to see more stats
                      _navigateToActivityTab(tabIndex: 1); // Workouts tab
                    },
                    child: Tooltip(
                      message: 'Total Daily Energy Expenditure\n(BMR + Daily Activity + Exercise)',
                      preferBelow: false,
                      child: _buildMetricChip(
                        summary.caloriesBurned.toString(),
                        'TDEE (kcal)',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to activity tab - steps tab
                      _navigateToActivityTab(tabIndex: 1); // Workouts tab since steps are part of activity
                    },
                    child: _buildMetricChip(
                      summary.stepsToday.toString(),
                      'Steps Today',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to activity tab - sleep tab
                      _navigateToActivityTab(tabIndex: 2); // Sleep tab
                    },
                    child: _buildMetricChip(
                      summary.sleepHours.toStringAsFixed(1),
                      'Sleep (hrs)',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
              Icons.directions_walk,
              'Log Steps',
              Colors.blue,
              () => _showLogStepsDialog(),
            ),
            _buildQuickActionItem(
              Icons.local_drink,
              'Log Water',
              Colors.cyan,
              _showAddHydrationDialog,
            ),
            _buildQuickActionItem(
              Icons.restaurant,
              'Log Meal',
              Colors.green,
              _showAddMealDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
              Icons.fitness_center,
              'Workout',
              Colors.orange,
              _showAddWorkoutDialog,
            ),
            _buildQuickActionItem(
              Icons.bedtime,
              'Log Sleep',
              Colors.purple,
              _showAddSleepDialog,
            ),
            _buildQuickActionItem(
              Icons.self_improvement,
              'Meditate',
              Colors.indigo,
              _showLogMeditationDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
              Icons.medication,
              'Medication',
              Colors.pink,
              _showAddMedicationDialog,
            ),
            _buildQuickActionItem(
              Icons.emoji_events,
              'View Goals',
              Colors.amber,
              () => _navigateToGamificationTab(tabIndex: 1),
            ),
            _buildQuickActionItem(
              Icons.bar_chart,
              'View Stats',
              Colors.teal,
              _showFullWeeklySummary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(DashboardSummary? summary) {
    if (summary == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    final goals = summary.goalsProgress ?? {};
    
    int stepsGoal = goals['steps']?['goal'] ?? 10000;
    double waterGoal = (goals['water']?['goal'] ?? 8).toDouble();
    double sleepGoal = (goals['sleep']?['goal'] ?? 8.0).toDouble();
    int meditationGoal = goals['meditation']?['goal'] ?? 10;
    int workoutsGoal = goals['workouts']?['goal'] ?? 5;
    int caloriesGoal = goals['calories']?['goal'] ?? 60000;
    
    int caloriesThisMonth = goals['calories']?['current'] ?? 0;
    int workoutsThisWeek = goals['workouts']?['current'] ?? 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            _buildProgressRow(
              'Steps',
              summary.stepsToday.toDouble(),
              stepsGoal.toDouble(),
              Icons.directions_walk,
              Colors.blue,
              'steps',
            ),
            const SizedBox(height: 12),
            
            _buildProgressRow(
              'Water',
              summary.waterGlasses,
              waterGoal,
              Icons.local_drink,
              Colors.cyan,
              'glasses',
            ),
            const SizedBox(height: 12),
            
            _buildProgressRow(
              'Sleep',
              summary.sleepHours,
              sleepGoal,
              Icons.bedtime,
              Colors.purple,
              'hours',
            ),
            const SizedBox(height: 12),
            
            _buildProgressRow(
              'Meditation',
              summary.meditationMinutes.toDouble(),
              meditationGoal.toDouble(),
              Icons.self_improvement,
              Colors.indigo,
              'minutes',
            ),
            const SizedBox(height: 12),
            
            const Divider(),
            const SizedBox(height: 8),
            
            const Text(
              'Extended Goals',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            
            _buildProgressRow(
              'Workouts (This Week)',
              workoutsThisWeek.toDouble(),
              workoutsGoal.toDouble(),
              Icons.fitness_center,
              Colors.orange,
              'workouts',
            ),
            const SizedBox(height: 12),
            
            _buildProgressRow(
              'Calories (This Month)',
              caloriesThisMonth.toDouble(),
              caloriesGoal.toDouble(),
              Icons.local_fire_department,
              Colors.red,
              'kcal',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, double current, double goal, IconData icon, Color color, String unit) {
    final percentage = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    
    String currentFormatted;
    if (current == current.roundToDouble()) {
      currentFormatted = current.toInt().toString();
    } else {
      currentFormatted = current.toStringAsFixed(1);
    }
    
    String goalFormatted;
    if (goal == goal.roundToDouble()) {
      goalFormatted = goal.toInt().toString();
    } else {
      goalFormatted = goal.toStringAsFixed(1);
    }
    
    return InkWell(
      onTap: () {
        // Navigate to appropriate tab based on label
        if (label.contains('Steps')) {
          _navigateToActivityTab(tabIndex: 1);
        } else if (label.contains('Water')) {
          _navigateToActivityTab(tabIndex: 3);
        } else if (label.contains('Sleep')) {
          _navigateToActivityTab(tabIndex: 2);
        } else if (label.contains('Meditation')) {
          _navigateToGamificationTab(tabIndex: 0);
        } else if (label.contains('Workouts')) {
          _navigateToActivityTab(tabIndex: 1);
        } else if (label.contains('Calories')) {
          _navigateToActivityTab(tabIndex: 0);
        }
      },
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    Text(
                      goal > 0 
                          ? '$currentFormatted/$goalFormatted $unit'
                          : '$currentFormatted $unit',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (goal > 0)
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 6,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, dynamic>? weeklyData) {
    if (weeklyData == null) {
      return const SizedBox();
    }

    final stepsData = (weeklyData['steps'] as List?)?.cast<num>().map((e) => e.toDouble()).toList() ?? [0, 0, 0, 0, 0, 0, 0];
    final labels = weeklyData['labels'] as List<String>? ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    bool hasAnyData = stepsData.any((value) => value > 0);

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Activity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Steps breakdown by day',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _showFullWeeklySummary,
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!hasAnyData)
              SizedBox(
                height: 150,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_walk, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No steps data this week',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        'Start walking to see your progress!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: Row(
                  children: List.generate(stepsData.length, (index) {
                    final maxValue = stepsData.reduce((a, b) => a > b ? a : b);
                    final barHeight = maxValue > 0 
                        ? (stepsData[index] / maxValue) * 120 
                        : 0.0;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Show day details
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${labels[index]}: ${stepsData[index].toInt()} steps'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 20,
                                  height: barHeight.toDouble(),
                                  decoration: BoxDecoration(
                                    color: stepsData[index] > 0 ? Colors.green : Colors.grey[300],
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 10,
                                color: stepsData[index] > 0 ? Colors.black : Colors.grey[500],
                              ),
                            ),
                            if (stepsData[index] > 0)
                              Text(
                                stepsData[index].toInt().toString(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(List<ActivitySummary> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your latest logs',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                _navigateToActivityTab(tabIndex: 0);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (activities.isEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No recent activities',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap the + button to log your first activity',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to appropriate tab based on activity type
                  if (activity.type == 'steps' || activity.type == 'workout') {
                    _navigateToActivityTab(tabIndex: 1);
                  } else if (activity.type == 'water') {
                    _navigateToActivityTab(tabIndex: 3);
                  } else if (activity.type == 'sleep') {
                    _navigateToActivityTab(tabIndex: 2);
                  } else if (activity.type == 'meal' || activity.type == 'calories') {
                    _navigateToActivityTab(tabIndex: 0);
                  } else if (activity.type == 'meditation') {
                    _navigateToGamificationTab(tabIndex: 0);
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activity.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(activity.icon, color: activity.color, size: 20),
                    ),
                    title: Text(activity.title),
                    subtitle: Text(activity.subtitle),
                    trailing: Text(
                      DateFormat.jm().format(activity.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // Smart Reminders Section
  Widget _buildSmartReminders(SmartReminderProvider provider) {
    final unreadReminders = provider.unreadReminders;
    
    if (unreadReminders.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Smart Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${unreadReminders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (unreadReminders.length > 3)
              TextButton(
                onPressed: () => _showRemindersDialog(context, provider),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Show only top 3 unread reminders
        ...unreadReminders.take(3).map((reminder) => _buildSmartReminderCard(context, reminder, provider)),
      ],
    );
  }

  // Smart Reminder Card
  Widget _buildSmartReminderCard(BuildContext context, SmartReminder reminder, SmartReminderProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: reminder.priority == ReminderPriority.critical
          ? Colors.red.withOpacity(0.05)
          : reminder.priority == ReminderPriority.high
              ? Colors.orange.withOpacity(0.05)
              : null,
      child: InkWell(
        onTap: () {
          provider.executeAction(reminder, context);
          provider.markAsRead(reminder.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: reminder.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  reminder.icon,
                  color: reminder.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: reminder.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            reminder.priority.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              color: reminder.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.jm().format(reminder.timestamp),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (reminder.pointsReward != null && reminder.pointsReward! > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars, size: 8, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  '+${reminder.pointsReward}',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action indicator
              if (reminder.actionType != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Show all reminders dialog
  void _showRemindersDialog(BuildContext context, SmartReminderProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Smart Insights',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    provider.markAllAsRead();
                    Navigator.pop(context);
                  },
                  child: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No insights yet',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Continue using the app to get personalized insights',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = provider.reminders[index];
                        return _buildSmartReminderCard(context, reminder, provider);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTips(List<HealthTip> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Tips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return _buildTipCard(tip);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(HealthTip tip) {
    return GestureDetector(
      onTap: () {
        if (tip.action != null) {
          if (tip.action!.contains('water') || tip.action!.contains('hydration')) {
            _showAddHydrationDialog();
          } else if (tip.action!.contains('meal')) {
            _showAddMealDialog();
          } else if (tip.action!.contains('activity') || tip.action!.contains('steps')) {
            _showLogStepsDialog();
          } else if (tip.action!.contains('sleep')) {
            _showAddSleepDialog();
          } else if (tip.action!.contains('meditation')) {
            _showLogMeditationDialog();
          } else {
            _navigateToActivityTab();
          }
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tip.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tip.icon, color: tip.color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    tip.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}