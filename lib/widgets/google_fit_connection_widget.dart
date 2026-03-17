import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/google_fit_provider.dart';

class GoogleFitConnectionWidget extends StatefulWidget {
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;

  const GoogleFitConnectionWidget({
    super.key,
    this.onConnected,
    this.onDisconnected,
  });

  @override
  State<GoogleFitConnectionWidget> createState() =>
      _GoogleFitConnectionWidgetState();
}

class _GoogleFitConnectionWidgetState extends State<GoogleFitConnectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GoogleFitProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  /// 🔹 HEADER
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: provider.isConnected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: provider.isConnected
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),

                      /// TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Fit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              provider.isConnected
                                  ? (provider.connectedAccount ?? 'Connected')
                                  : (provider.error ?? 'Not connected'),
                              style: TextStyle(
                                fontSize: 12,
                                color: provider.isConnected
                                    ? Colors.green
                                    : (provider.error != null
                                        ? Colors.red
                                        : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// ACTION BUTTON
                      if (provider.isConnecting)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (provider.isConnected)
                        IconButton(
                          icon: const Icon(Icons.sync, color: Colors.blue),
                          onPressed: provider.isSyncing
                              ? null
                              : () async {
                                  await provider.loadTodayData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Data synced from Google Fit'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                        )
                      else
                        ElevatedButton(
                          onPressed: provider.isConnecting
                              ? null
                              : () async {
                                  final connected =
                                      await provider.connect();
                                  if (connected &&
                                      widget.onConnected != null) {
                                    widget.onConnected!();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: provider.isConnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Connect'),
                        ),
                    ],
                  ),

                  /// 🔹 DATA SECTION
                  if (provider.isConnected && provider.hasData) ...[
                    const SizedBox(height: 16),
                    const Divider(),

                    /// STATS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Steps',
                            '${provider.todaySummary?.totalSteps ?? 0}',
                            Icons.directions_walk,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Calories',
                            '${provider.todaySummary?.totalCalories ?? 0}',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Active',
                            '${provider.todaySummary?.totalActiveMinutes.round()} min',
                            Icons.timer,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    /// ACTIVITIES
                    if (provider.todayActivities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activities',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.todayActivities.length > 3
                              ? 3
                              : provider.todayActivities.length,
                          itemBuilder: (context, index) {
                            final activity =
                                provider.todayActivities[index];
                            return Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${activity.duration.toInt()} min',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${activity.calories} kcal',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    /// SYNC BUTTON
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: provider.isSyncing
                            ? null
                            : () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text('Data synced to app'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                        icon: provider.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          provider.isSyncing
                              ? 'Syncing...'
                              : 'Sync to App',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
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