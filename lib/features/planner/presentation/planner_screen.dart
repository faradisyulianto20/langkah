import 'package:flutter/material.dart';

/// Placeholder screen — akan diisi dengan implementasi penuh di Step 3.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      body: const Center(
        child: Text(
          '📅 Planner\nSegera hadir...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, height: 1.6),
        ),
      ),
    );
  }
}
