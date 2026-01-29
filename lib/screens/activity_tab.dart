import 'package:flutter/material.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logging')),
      body: const Center(
        child: Text(
          'Track your daily activities here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
