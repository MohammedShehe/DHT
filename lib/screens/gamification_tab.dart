import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../providers/gamification_provider.dart';
import '../widgets/goal_setting_dialog.dart';
import '../widgets/reminder_dialog.dart';
import '../models/gamification_models.dart' as gamification;

class GamificationTab extends StatefulWidget {
  const GamificationTab({super.key});

  @override
  State<GamificationTab> createState() => _GamificationTabState();
}

class _GamificationTabState extends State<GamificationTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set up message callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GamificationProvider>(context, listen: false);
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
    });
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<GamificationProvider>(context, listen: false);
      provider.disposeCallbacks();
    } catch (e) {
      // Provider might not be available during dispose
    }
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalSettingDialog(
        onGoalCreated: (goal) {
          // Refresh goals list
          final provider = Provider.of<GamificationProvider>(context, listen: false);
          provider.loadGoals();
        },
      ),
    ).then((goal) {
      if (goal != null) {
        final provider = Provider.of<GamificationProvider>(context, listen: false);
        provider.addGoal(goal);
      }
    });
  }

  void _showCreateReminderDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReminderDialog(),
    ).then((reminder) {
      if (reminder != null) {
        final provider = Provider.of<GamificationProvider>(context, listen: false);
        provider.addReminder(reminder);
      }
    });
  }

  void _refreshLeaderboard() {
    final provider = Provider.of<GamificationProvider>(context, listen: false);
    // TODO: Implement leaderboard refresh from backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leaderboard refreshed'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gamification & Goals',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
            Tab(icon: Icon(Icons.flag), text: 'Goals'),
            Tab(icon: Icon(Icons.alarm), text: 'Reminders'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          ],
        ),
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              BadgesTab(provider: provider),
              GoalsTab(provider: provider),
              RemindersTab(provider: provider),
              LeaderboardTab(provider: provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 1) {
            _showCreateGoalDialog();
          } else if (_tabController.index == 2) {
            _showCreateReminderDialog();
          } else if (_tabController.index == 0) {
            // Scroll to top of badges tab
            // You can implement this if needed
          } else if (_tabController.index == 3) {
            _refreshLeaderboard();
          }
        },
        backgroundColor: Colors.amber,
        child: Icon(
          _tabController.index == 1 ? Icons.add :
          _tabController.index == 2 ? Icons.alarm_add :
          _tabController.index == 0 ? Icons.military_tech :
          Icons.refresh,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Badges Tab
class BadgesTab extends StatelessWidget {
  final GamificationProvider provider;

  const BadgesTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final userStats = provider.userStats;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Progress Card
          if (userStats != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.shade700,
                      Colors.amber.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Level',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${userStats.totalPoints} pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${userStats.level}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${userStats.badgesEarned}/${userStats.totalBadges} Badges',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: userStats.levelProgress,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                color: Colors.white,
                                strokeWidth: 8,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(userStats.levelProgress * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'to Lv ${userStats.level + 1}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Streak Card
          if (userStats != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Streak',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            '${userStats.currentStreak} days',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
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
                        'Best: ${userStats.longestStreak}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Category Stats
          if (userStats != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Points by Category',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryStat('Activity', userStats.categoryPoints['activity'] ?? 0, Colors.green),
                    const SizedBox(height: 8),
                    _buildCategoryStat('Nutrition', userStats.categoryPoints['nutrition'] ?? 0, Colors.orange),
                    const SizedBox(height: 8),
                    _buildCategoryStat('Sleep', userStats.categoryPoints['sleep'] ?? 0, Colors.purple),
                    const SizedBox(height: 8),
                    _buildCategoryStat('Hydration', userStats.categoryPoints['hydration'] ?? 0, Colors.blue),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Recent Badges
          const Text(
            'Recent Badges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (provider.earnedBadges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.military_tech, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No badges earned yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete activities to earn badges!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.getRecentEarnedBadges().map((badge) => _buildBadgeCard(badge)),

          const SizedBox(height: 16),

          // All Badges
          const Text(
            'All Badges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          ...provider.badges.map((badge) => _buildBadgeCard(badge, showUnearned: true)),
        ],
      ),
    );
  }

  Widget _buildCategoryStat(String label, int points, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: points / 1000,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$points pts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(gamification.Badge badge, {bool showUnearned = false}) {
    if (!badge.isEarned && !showUnearned) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: badge.isEarned ? null : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: badge.rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                badge.categoryIcon,
                color: badge.rarityColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        badge.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: badge.isEarned ? badge.rarityColor : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badge.rarityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge.rarity.toString().split('.').last,
                          style: TextStyle(
                            fontSize: 10,
                            color: badge.rarityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (badge.isEarned && badge.earnedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Earned: ${DateFormat.yMMMd().format(badge.earnedDate!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: badge.rarityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge.isEarned)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badge.rarityColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${badge.pointsValue} pts',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Goals Tab - UPDATED to work with backend
class GoalsTab extends StatelessWidget {
  final GamificationProvider provider;

  const GoalsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final activeGoals = provider.activeGoals;
    final completedGoals = provider.completedGoals;

    return RefreshIndicator(
      onRefresh: () => provider.loadGoals(),
      color: Colors.amber,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Goals Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Goals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateGoalDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Goal'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (provider.isLoadingGoals)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
              )
            else if (activeGoals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.flag, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No active goals',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first goal!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activeGoals.map((goal) => _buildGoalCard(context, goal)),

            const SizedBox(height: 24),

            // Completed Goals Section
            if (completedGoals.isNotEmpty) ...[
              const Text(
                'Completed Goals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...completedGoals.map((goal) => _buildGoalCard(context, goal, isCompleted: true)),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalSettingDialog(
        onGoalCreated: (goal) {
          // Refresh goals list
          provider.loadGoals();
        },
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, gamification.Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalSettingDialog(
        existingGoal: goal,
        onGoalCreated: (updated) {
          provider.loadGoals();
        },
      ),
    );
  }

  void _showLogProgressDialog(BuildContext context, gamification.Goal goal) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log ${_getGoalTitle(goal.type)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goal.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(goal.icon, color: goal.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGoalTitle(goal.type),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Target: ${goal.targetValue.toInt()} ${_getGoalUnit(goal.type)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Current: ${goal.currentValue.toInt()} ${_getGoalUnit(goal.type)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: goal.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount to Log',
                hintText: 'Enter ${_getGoalUnit(goal.type)}',
                suffixText: _getGoalUnit(goal.type),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                provider.logActivityProgress(
                  type: goal.type,
                  value: value,
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
              backgroundColor: goal.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGoalDialog(BuildContext context, gamification.Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete your ${_getGoalTitle(goal.type)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteGoal(goal);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, gamification.Goal goal, {bool isCompleted = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isCompleted ? Colors.green.withOpacity(0.05) : null,
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
                    color: goal.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(goal.icon, color: goal.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGoalTitle(goal.type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getGoalPeriodText(goal.period),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            goal.formattedProgress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(goal.progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: goal.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: goal.progress,
                        backgroundColor: goal.color.withOpacity(0.1),
                        color: goal.color,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Goal Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGoalDetail(
                    'Target',
                    '${goal.targetValue.toInt()} ${_getGoalUnit(goal.type)}',
                    goal.color,
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  _buildGoalDetail(
                    'Current',
                    '${goal.currentValue.toInt()} ${_getGoalUnit(goal.type)}',
                    goal.color,
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  _buildGoalDetail(
                    'Created',
                    DateFormat.MMMd().format(goal.createdAt),
                    goal.color,
                  ),
                ],
              ),
            ),

            if (!isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditGoalDialog(context, goal),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showLogProgressDialog(context, goal),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Log Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goal.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteGoalDialog(context, goal),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getGoalTitle(gamification.GoalType type) {
    switch (type) {
      case gamification.GoalType.steps:
        return 'Steps Goal';
      case gamification.GoalType.water:
        return 'Water Intake Goal';
      case gamification.GoalType.sleep:
        return 'Sleep Goal';
      case gamification.GoalType.meditation:
        return 'Meditation Goal';
      case gamification.GoalType.workouts:
        return 'Workout Goal';
      case gamification.GoalType.calories:
        return 'Calorie Goal';
    }
  }

  String _getGoalPeriodText(gamification.GoalPeriod period) {
    switch (period) {
      case gamification.GoalPeriod.daily:
        return 'Daily';
      case gamification.GoalPeriod.weekly:
        return 'Weekly';
      case gamification.GoalPeriod.monthly:
        return 'Monthly';
    }
  }

  String _getGoalUnit(gamification.GoalType type) {
    switch (type) {
      case gamification.GoalType.steps:
        return 'steps';
      case gamification.GoalType.water:
        return 'glasses';
      case gamification.GoalType.sleep:
        return 'hours';
      case gamification.GoalType.meditation:
        return 'min';
      case gamification.GoalType.workouts:
        return 'workouts';
      case gamification.GoalType.calories:
        return 'kcal';
    }
  }
}

// Reminders Tab
class RemindersTab extends StatelessWidget {
  final GamificationProvider provider;

  const RemindersTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Reminders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (provider.reminders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.alarm, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No reminders set',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to set your first reminder!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.reminders.map((reminder) => _buildReminderCard(context, reminder)),

          const SizedBox(height: 16),

          // Quick reminder suggestions
          const Text(
            'Quick Suggestions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          _buildSuggestionChip(
            context,
            'Morning Workout',
            '7:00 AM',
            Icons.fitness_center,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildSuggestionChip(
            context,
            'Drink Water',
            'Every 2 hours',
            Icons.local_drink,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildSuggestionChip(
            context,
            'Evening Meditation',
            '8:00 PM',
            Icons.self_improvement,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, gamification.Reminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                    color: reminder.isEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.alarm,
                    color: reminder.isEnabled ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: reminder.isEnabled ? Colors.black : Colors.grey,
                        ),
                      ),
                      Text(
                        reminder.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: reminder.isEnabled ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder.isEnabled,
                  onChanged: (value) => provider.toggleReminder(reminder.id),
                  activeColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time and days
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: reminder.isEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        reminder.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: reminder.isEnabled ? Colors.blue : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: reminder.formattedDays.map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: reminder.isEnabled ? Colors.grey[200] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 10,
                            color: reminder.isEnabled ? Colors.grey[700] : Colors.grey[400],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            if (reminder.action != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: reminder.isEnabled ? Colors.grey[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Opens: ${_getActionLabel(reminder.action!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ReminderDialog(existingReminder: reminder),
                    ).then((updated) {
                      if (updated != null) {
                        provider.updateReminder(updated);
                      }
                    });
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Reminder'),
                        content: const Text('Are you sure you want to delete this reminder?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deleteReminder(reminder.id);
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const ReminderDialog(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'open_activity':
        return 'Activity Logging';
      case 'open_hydration':
        return 'Hydration Logging';
      case 'open_meal':
        return 'Meal Logging';
      case 'open_medication':
        return 'Medication Reminder';
      case 'open_meditation':
        return 'Meditation';
      default:
        return action;
    }
  }
}

// Leaderboard Tab
class LeaderboardTab extends StatelessWidget {
  final GamificationProvider provider;

  const LeaderboardTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final userEntry = provider.currentUserEntry;
    final topThree = provider.topThree;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top 3 Podium
          if (topThree.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place
                if (topThree.length > 1)
                  Expanded(
                    child: _buildPodiumItem(
                      topThree[1],
                      rank: 2,
                      height: 120,
                    ),
                  ),
                // 1st Place
                Expanded(
                  child: _buildPodiumItem(
                    topThree[0],
                    rank: 1,
                    height: 160,
                  ),
                ),
                // 3rd Place
                if (topThree.length > 2)
                  Expanded(
                    child: _buildPodiumItem(
                      topThree[2],
                      rank: 3,
                      height: 100,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // Leaderboard List
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.leaderboard.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = provider.leaderboard[index];
                final isCurrentUser = entry.isCurrentUser;
                
                return Container(
                  color: isCurrentUser ? Colors.amber.withOpacity(0.1) : null,
                  child: ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankColor(entry.rank).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getRankColor(entry.rank),
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          entry.userName,
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('${entry.streak} day streak'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.points} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // User Stats Card
          if (userEntry != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Ranking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Top ${((userEntry.rank / provider.leaderboard.length) * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRankStat('Rank', '#${userEntry.rank}', Colors.amber),
                        _buildRankStat('Points', '${userEntry.points}', Colors.green),
                        _buildRankStat('Streak', '${userEntry.streak}', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: Colors.grey[200],
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '150 points to next rank',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(gamification.LeaderboardEntry entry, {required int rank, required double height}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _getRankColor(rank).withOpacity(0.2),
          child: Text(
            '#$rank',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _getRankColor(rank),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.userName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.points} pts',
          style: TextStyle(
            fontSize: 10,
            color: _getRankColor(rank),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: _getRankColor(rank).withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '${entry.streak}🔥',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}