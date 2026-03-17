import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/google_fit_provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity_models.dart';
import '../widgets/google_fit_connection_widget.dart';

class GoogleFitTestPage extends StatefulWidget {
  const GoogleFitTestPage({super.key});

  @override
  State<GoogleFitTestPage> createState() => _GoogleFitTestPageState();
}

class _GoogleFitTestPageState extends State<GoogleFitTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Fit Integration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GoogleFitProvider>(context, listen: false)
                  .loadTodayData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Fit Connection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            Consumer<GoogleFitProvider>(
              builder: (context, provider, child) {
                return GoogleFitConnectionWidget(
                  onConnected: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connected to Google Fit'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Consumer2<GoogleFitProvider, ActivityProvider>(
              builder: (context, fitProvider, activityProvider, child) {
                if (!fitProvider.isConnected) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Connect to Google Fit to see data'),
                    ),
                  );
                }
                
                if (fitProvider.isSyncing) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              'Today\'s Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDataItem(
                                  'Steps',
                                  '${fitProvider.todaySummary?.totalSteps ?? 0}',
                                  Icons.directions_walk,
                                  Colors.blue,
                                ),
                                _buildDataItem(
                                  'Calories',
                                  '${fitProvider.todaySummary?.totalCalories ?? 0}',
                                  Icons.local_fire_department,
                                  Colors.orange,
                                ),
                                _buildDataItem(
                                  'Heart Rate',
                                  '${fitProvider.todaySummary?.averageHeartRate.round() ?? 0} bpm',
                                  Icons.favorite,
                                  Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (fitProvider.todayActivities.isNotEmpty) ...[
                      const Text(
                        'Activities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...fitProvider.todayActivities.map((activity) {
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
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fitness_center,
                                  color: Colors.green),
                            ),
                            title: Text(activity.name),
                            subtitle: Text(
                              '${activity.duration.toInt()} min • ${activity.calories} kcal',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final workout = Workout(
                                  id: activity.id,
                                  type: activity.name,
                                  duration: activity.duration.toInt(),
                                  calories: activity.calories,
                                  time: '${activity.startTime.hour}:${activity.startTime.minute.toString().padLeft(2, '0')}',
                                  intensity: 'Moderate',
                                  notes: 'Synced from Google Fit',
                                );
                                await activityProvider.addWorkout(workout);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Activity synced to app'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: const Text('Sync'),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    if (fitProvider.lastNightSleep != null) ...[
                      const Text(
                        'Last Night\'s Sleep',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSleepDetail(
                                    'Duration',
                                    '${fitProvider.lastNightSleep!.duration.toStringAsFixed(1)}h',
                                    Icons.timer,
                                    Colors.purple,
                                  ),
                                  _buildSleepDetail(
                                    'Deep Sleep',
                                    '${fitProvider.lastNightSleep!.deepSleepDuration?.toStringAsFixed(1) ?? '0'}h',
                                    Icons.bedtime,
                                    Colors.indigo,
                                  ),
                                  _buildSleepDetail(
                                    'REM Sleep',
                                    '${fitProvider.lastNightSleep!.remSleepDuration?.toStringAsFixed(1) ?? '0'}h',
                                    Icons.nights_stay,
                                    Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: fitProvider.isSyncing
                            ? null
                            : () async {
                                final result = await fitProvider
                                    .syncToActivityProvider(activityProvider);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor: result['success']
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              },
                        icon: fitProvider.isSyncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          fitProvider.isSyncing
                              ? 'Syncing...'
                              : 'Sync All to App',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
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

  Widget _buildSleepDetail(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
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
}