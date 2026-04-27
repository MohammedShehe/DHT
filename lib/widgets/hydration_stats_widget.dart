import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';

class HydrationStatsWidget extends StatelessWidget {
  const HydrationStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HydrationProvider>(context);
    final todayGoal = provider.todayGoal;
    final todayTotal = provider.todayTotalMl;
    final percentage = provider.todayPercentage;
    final remaining = provider.todayRemaining;
    final completed = provider.todayCompleted;

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
                  'Hydration Goal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showGoalDialog(context, provider),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Set Goal'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Goal display
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${(todayTotal / 250).toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const Text('Glasses Today', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${(todayGoal / 250).round()}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const Text('Daily Goal', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              color: completed ? Colors.green : Colors.blue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentage.round()}% Complete',
                  style: TextStyle(
                    color: completed ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!completed)
                  Text(
                    '${(remaining / 250).round()} glasses left',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
            
            if (completed)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Goal completed!', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, HydrationProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: (provider.todayGoal / 250).round().toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Hydration Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many glasses of water do you want to drink daily?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Glasses per day',
                border: OutlineInputBorder(),
                suffixText: 'glasses',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final glasses = int.tryParse(controller.text);
              if (glasses != null && glasses > 0) {
                Navigator.pop(dialogContext);
                await provider.setGoal(glasses * 250); // Convert to ml
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}