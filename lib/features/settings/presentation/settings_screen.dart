import 'package:flutter/material.dart';

/// Placeholder screen — akan diisi dengan implementasi penuh di Step 2.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text(
          '⚙️ Settings\nSegera hadir...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, height: 1.6),
        ),
      ),
    );
  }
}
