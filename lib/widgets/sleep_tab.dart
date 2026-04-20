import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_activity_provider.dart';
import '../providers/activity_provider.dart';
import '../models/sleep_activity_models.dart';
import 'add_sleep_dialog.dart';

class SleepTab extends StatefulWidget {
  final ActivityProvider? activityProvider;
  final Future<void> Function()? onRefresh;

  const SleepTab({super.key, this.activityProvider, this.onRefresh});

  @override
  State<SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<SleepTab> with SingleTickerProviderStateMixin {
  late TabController _statsTabController;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _statsTabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SleepActivityProvider>(context, listen: false);
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
      
      // Load initial data
      provider.loadSleepLogForDate(DateTime.now());
      provider.loadAllStats();
      provider.loadQualityTypes();
    });
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<SleepActivityProvider>(context, listen: false);
      provider.disposeCallbacks();
    } catch (e) {}
    _statsTabController.dispose();
    super.dispose();
  }

  void _showAddSleepDialog() {
    final provider = Provider.of<SleepActivityProvider>(context, listen: false);
    
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
      if (widget.onRefresh != null) widget.onRefresh!();
    });
  }

  void _showDeleteConfirmation() {
    final provider = Provider.of<SleepActivityProvider>(context, listen: false);
    
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
              if (widget.onRefresh != null) widget.onRefresh!();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _changeDate(DateTime newDate) {
    final provider = Provider.of<SleepActivityProvider>(context, listen: false);
    provider.setSelectedDate(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepActivityProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadSleepLogForDate(provider.selectedDate);
            await provider.loadAllStats();
            if (widget.onRefresh != null) await widget.onRefresh!();
          },
          color: Colors.purple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date selector
                _buildDateSelector(provider),
                
                const SizedBox(height: 16),
                
                // Sleep log card (if exists)
                if (provider.currentSleepLog != null)
                  _buildSleepLogCard(context, provider.currentSleepLog!, provider),
                
                // Stats Tabs
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _statsTabController,
                    indicator: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    tabs: const [
                      Tab(text: 'Weekly', icon: Icon(Icons.calendar_view_week)),
                      Tab(text: 'Chart', icon: Icon(Icons.show_chart)),
                      Tab(text: 'Summary', icon: Icon(Icons.summarize)),
                      Tab(text: 'Insights', icon: Icon(Icons.insights)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  child: TabBarView(
                    controller: _statsTabController,
                    children: [
                      _buildWeeklyStatsTab(provider),
                      _buildChartTab(provider),
                      _buildSummaryTab(provider),
                      _buildInsightsTab(provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(SleepActivityProvider provider) {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected = provider.selectedDate.year == date.year &&
              provider.selectedDate.month == date.month &&
              provider.selectedDate.day == date.day;
          
          final dayName = DateFormat('E').format(date);
          final dayNumber = date.day.toString();
          
          return GestureDetector(
            onTap: () => _changeDate(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                          '${sleepLog.absoluteTotalHours.toStringAsFixed(1)} hours',
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
                      value: 'edit',
                      child: Row(
                        children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddSleepDialog();
                    } else if (value == 'delete') {
                      _showDeleteConfirmation();
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

  Widget _buildWeeklyStatsTab(SleepActivityProvider provider) {
    final durationData = provider.getWeeklyDurationData();
    final interruptionData = provider.getWeeklyInterruptionData();
    final labels = provider.getWeekLabels();
    
    final maxDuration = durationData.isNotEmpty ? durationData.reduce((a, b) => a > b ? a : b) : 8.0;
    final maxInt = interruptionData.isNotEmpty ? interruptionData.reduce((a, b) => a > b ? a : b) : 5.0;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Duration chart
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sleep Duration (hours)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Interruptions chart
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interruptions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: Row(
                    children: List.generate(7, (index) {
                      final barHeight = maxInt > 0 ? ((interruptionData[index] / maxInt) * 90).toDouble() : 0.0;
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
                                    color: interruptionData[index] > 0 ? Colors.orange : Colors.grey[300],
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
                                color: interruptionData[index] > 0 ? Colors.black : Colors.grey[500],
                              ),
                            ),
                            Text(
                              interruptionData[index].toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
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
        ],
      ),
    );
  }

  Widget _buildChartTab(SleepActivityProvider provider) {
    final chartData = provider.getChartDataForDisplay();
    
    if (chartData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No data available', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Log some sleep to see your progress', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: chartData.length,
      itemBuilder: (context, index) {
        final data = chartData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bedtime, color: Colors.purple),
            ),
            title: Text(data['date'] as String),
            subtitle: Text('Hours: ${data['hours']?.toStringAsFixed(1) ?? '0.0'}h'),
            trailing: Text(
              'Interruptions: ${data['interruptions']}',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(SleepActivityProvider provider) {
    if (provider.summary == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.purple));
    }
    
    final summary = provider.summary!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Period selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPeriodChip('week', _selectedPeriod, () {
                setState(() => _selectedPeriod = 'week');
                provider.loadSummary(period: 'week');
              }),
              _buildPeriodChip('month', _selectedPeriod, () {
                setState(() => _selectedPeriod = 'month');
                provider.loadSummary(period: 'month');
              }),
              _buildPeriodChip('quarter', _selectedPeriod, () {
                setState(() => _selectedPeriod = 'quarter');
                provider.loadSummary(period: 'quarter');
              }),
            ],
          ),
          const SizedBox(height: 16),
          
          // Stats cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard('Total Logs', '${summary.totalLogs}', Icons.calendar_today, Colors.blue),
              _buildStatCard('Avg Sleep', '${summary.averageSleepHours.toStringAsFixed(1)}h', Icons.bedtime, Colors.purple),
              _buildStatCard('Best Sleep', '${summary.bestSleepHours.toStringAsFixed(1)}h', Icons.arrow_upward, Colors.green),
              _buildStatCard('Worst Sleep', '${summary.worstSleepHours.toStringAsFixed(1)}h', Icons.arrow_downward, Colors.red),
              _buildStatCard('Avg Interruptions', '${summary.averageInterruptions.toStringAsFixed(0)}', Icons.notifications, Colors.orange),
              _buildStatCard('Most Common', summary.mostCommonQuality, Icons.star, Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quality distribution
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sleep Quality Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildQualityBar('Excellent', summary.qualityDistribution['excellent']?['count'] ?? 0, summary.totalLogs, Colors.green),
                const SizedBox(height: 8),
                _buildQualityBar('Good', summary.qualityDistribution['good']?['count'] ?? 0, summary.totalLogs, Colors.blue),
                const SizedBox(height: 8),
                _buildQualityBar('Fair', summary.qualityDistribution['fair']?['count'] ?? 0, summary.totalLogs, Colors.orange),
                const SizedBox(height: 8),
                _buildQualityBar('Poor', summary.qualityDistribution['poor']?['count'] ?? 0, summary.totalLogs, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(SleepActivityProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Comparison card
          if (provider.comparison != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Week over Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildComparisonItem(
                            'Avg Sleep',
                            provider.comparison!.currentWeek['avg_hours']?.toStringAsFixed(1) ?? '0',
                            provider.comparison!.previousWeek['avg_hours']?.toStringAsFixed(1) ?? '0',
                            provider.comparison!.changes['hours'] ?? 0,
                            'h',
                          ),
                        ),
                        Expanded(
                          child: _buildComparisonItem(
                            'Interruptions',
                            provider.comparison!.currentWeek['avg_interruptions']?.toStringAsFixed(0) ?? '0',
                            provider.comparison!.previousWeek['avg_interruptions']?.toStringAsFixed(0) ?? '0',
                            -(provider.comparison!.changes['interruptions'] ?? 0),
                            'x',
                            inverseBetter: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Consistency card
          if (provider.consistency != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bedtime Consistency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: provider.consistency!.consistencyScore / 100,
                                backgroundColor: Colors.grey[200],
                                color: Colors.purple,
                                strokeWidth: 8,
                              ),
                            ),
                            Text(
                              '${provider.consistency!.consistencyScore.round()}%',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.consistency!.message,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Variance: ${provider.consistency!.bedtimeVarianceMinutes} min',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Quality tips
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sleep Tips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildTipTile(Icons.bedtime, 'Maintain Schedule', 'Go to bed and wake up at the same time every day'),
                  const Divider(),
                  _buildTipTile(Icons.devices, 'Reduce Blue Light', 'Avoid screens 1 hour before bedtime'),
                  const Divider(),
                  _buildTipTile(Icons.coffee, 'Limit Caffeine', 'Avoid caffeine 6 hours before bed'),
                  const Divider(),
                  _buildTipTile(Icons.fitness_center, 'Exercise Regularly', 'Regular exercise improves sleep quality'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period, String selected, VoidCallback onTap) {
    final isSelected = selected == period;
    final displayName = period == 'week' ? 'Week' : period == 'month' ? 'Month' : 'Quarter';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('$count ($percentage%)', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? count / total : 0,
          backgroundColor: color.withOpacity(0.1),
          color: color,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildComparisonItem(String label, String current, String previous, double change, String unit, {bool inverseBetter = false}) {
    final isImprovement = inverseBetter ? change < 0 : change > 0;
    final changeAbs = change.abs().toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('$current $unit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('vs $previous $unit', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isImprovement ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImprovement ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 10,
                  color: isImprovement ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 2),
                Text(
                  '$changeAbs $unit',
                  style: TextStyle(
                    fontSize: 10,
                    color: isImprovement ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipTile(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}