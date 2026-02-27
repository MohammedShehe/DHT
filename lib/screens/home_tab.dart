import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/gamification_provider.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_models.dart';

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
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.onShowMessage = (String message, {bool isError = false}) {
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

  void _navigateToActivity(String route) {
    // Navigate to the appropriate tab in ActivityTab
    int tabIndex = 0;
    
    if (route.contains('tab=0')) tabIndex = 0;
    else if (route.contains('tab=1')) tabIndex = 1;
    else if (route.contains('tab=2')) tabIndex = 2;
    else if (route.contains('tab=3')) tabIndex = 3;
    else if (route.contains('tab=4')) tabIndex = 4;
    
    // Navigate to activity tab with specific index
    // This would need to be implemented based on your navigation structure
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<DashboardProvider>(context, listen: false);
              provider.loadDashboardData();
              
              Provider.of<ActivityProvider>(context, listen: false).loadActivityData();
              Provider.of<GamificationProvider>(context, listen: false).loadGoals();
              
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
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.summary == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C853),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadDashboardData,
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
                  _buildHealthTips(provider.healthTips),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickLogOptions(context),
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
                Container(
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
                  child: _buildMetricChip(
                    summary.caloriesBurned.toString(),
                    'Calories',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricChip(
                    summary.stepsToday.toString(),
                    'Steps',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricChip(
                    summary.sleepHours.toStringAsFixed(1),
                    'Sleep',
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
    final actions = DashboardService.getQuickActions();
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionItem(
          action['icon'] as IconData,
          action['label'] as String,
          action['color'] as Color,
          action['route'] as String,
        );
      },
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color, String route) {
    return InkWell(
      onTap: () => _navigateToActivity(route),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

    // Get goals from summary if available
    final goals = summary.goalsProgress ?? {};
    
    int stepsGoal = goals['steps']?['goal'] ?? 10000;
    double waterGoal = (goals['water']?['goal'] ?? 8).toDouble();  // ← Changed to double
    double sleepGoal = (goals['sleep']?['goal'] ?? 8.0).toDouble();
    int meditationGoal = goals['meditation']?['goal'] ?? 10;
    int caloriesGoal = goals['calories']?['goal'] ?? 60000;
    
    // Current month progress for calories
    int caloriesThisMonth = goals['calories']?['current'] ?? 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProgressRow(
              'Steps',
              summary.stepsToday.toDouble(),
              stepsGoal.toDouble(),
              Icons.directions_walk,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildProgressRow(
              'Water',
              summary.waterGlasses,  // ← Now passes double directly
              waterGoal,
              Icons.local_drink,
              Colors.cyan,
            ),
            const SizedBox(height: 12),
            _buildProgressRow(
              'Sleep',
              summary.sleepHours,
              sleepGoal,
              Icons.bedtime,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildProgressRow(
              'Meditation',
              summary.meditationMinutes.toDouble(),
              meditationGoal.toDouble(),
              Icons.self_improvement,
              Colors.indigo,
            ),
            const SizedBox(height: 12),
            _buildProgressRow(
              'Calories (Month)',
              caloriesThisMonth.toDouble(),
              caloriesGoal.toDouble(),
              Icons.local_fire_department,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, double current, double goal, IconData icon, Color color) {
    final percentage = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    
    // Format current value with 1 decimal if it's not a whole number
    String currentFormatted;
    if (current == current.roundToDouble()) {
      currentFormatted = current.toInt().toString();
    } else {
      currentFormatted = current.toStringAsFixed(1);
    }
    
    // Format goal similarly
    String goalFormatted;
    if (goal == goal.roundToDouble()) {
      goalFormatted = goal.toInt().toString();
    } else {
      goalFormatted = goal.toStringAsFixed(1);
    }
    
    return Row(
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
                  Text(label, style: TextStyle(color: Colors.grey[700])),
                  Text(
                    goal > 0 
                        ? '$currentFormatted/$goalFormatted'
                        : currentFormatted,
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
    );
  }

  Widget _buildWeeklyChart(Map<String, dynamic>? weeklyData) {
    if (weeklyData == null) {
      return const SizedBox();
    }

    final stepsData = (weeklyData['steps'] as List?)?.cast<double>() ?? [0, 0, 0, 0, 0, 0, 0];
    final labels = weeklyData['labels'] as List<String>? ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hasData = weeklyData['hasData'] ?? true;

    // Check if there's actually any data (some values > 0)
    bool hasAnyData = stepsData.any((value) => value > 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Steps',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to activity tab
                _navigateToActivity('/activity');
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
              return Card(
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
              );
            },
          ),
      ],
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
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: tip.action != null ? () => _navigateToActivity(tip.action!) : null,
          borderRadius: BorderRadius.circular(16),
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

  void _showQuickLogOptions(BuildContext context) {
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
                // Navigate to steps logging
                _navigateToActivity('/activity?tab=steps');
              },
            ),
            _buildQuickLogOption(
              'Log Water',
              Icons.local_drink,
              Colors.cyan,
              () {
                Navigator.pop(context);
                _navigateToActivity('/activity?tab=3');
              },
            ),
            _buildQuickLogOption(
              'Log Sleep',
              Icons.bedtime,
              Colors.purple,
              () {
                Navigator.pop(context);
                _navigateToActivity('/activity?tab=2');
              },
            ),
            _buildQuickLogOption(
              'Log Meditation',
              Icons.self_improvement,
              Colors.indigo,
              () {
                Navigator.pop(context);
                _navigateToActivity('/activity?tab=meditation');
              },
            ),
            _buildQuickLogOption(
              'Log Meal',
              Icons.restaurant,
              Colors.green,
              () {
                Navigator.pop(context);
                _navigateToActivity('/activity?tab=0');
              },
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
}