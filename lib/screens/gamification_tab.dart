import 'package:flutter/material.dart';

class GamificationTab extends StatelessWidget {
  const GamificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gamification & Analytics')),
      body: const Center(
        child: Text(
          'Earn points, view stats and achievements.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
