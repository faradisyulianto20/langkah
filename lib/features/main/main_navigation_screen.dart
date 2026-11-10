import 'package:flutter/material.dart';
import 'package:langkah/features/home/presentation/home_screen.dart';
import 'package:langkah/features/planner/presentation/planner_screen.dart';
import 'package:langkah/features/settings/presentation/settings_screen.dart';

/// Sinyal sederhana: tiap tab me-refresh datanya saat dipilih kembali.
class _TabSignal extends ChangeNotifier {
  void ping() => notifyListeners();
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Urutan: Home, Planner, Settings.
  final _signals = List.generate(3, (_) => _TabSignal());
  late final List<Widget> _pages = [
    HomeScreen(refreshSignal: _signals[0]),
    PlannerScreen(refreshSignal: _signals[1]),
    SettingsScreen(refreshSignal: _signals[2]),
  ];

  @override
  void dispose() {
    for (final s in _signals) {
      s.dispose();
    }
    super.dispose();
  }

  void _onSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    // IndexedStack mempertahankan state tiap tab, jadi muat ulang manual
    // agar perubahan di tab lain (tugas, streak) langsung terlihat.
    _signals[index].ping();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
