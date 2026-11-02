import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'live_zones_screen.dart';
import 'storage_status_screen.dart';
import 'zones_screen.dart';

/// The protected app shell: a bottom navigation bar plus one body per tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Task 3: the selected tab lives in state
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  // Built once, so each tab's State object survives tab switches
  late final List<Widget> _tabs = [
    DashboardScreen(onOpenTab: _select),
    const ZonesScreen(),
    const LiveZonesScreen(),
    const StorageStatusScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Task 2 + 4: IndexedStack shows the tab at _index and keeps the
      // others alive (hidden), so scroll position and data are preserved
      body: IndexedStack(index: _index, children: _tabs),

      // Task 1: the bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index, // Task 3: highlights the selected item
        onTap: _select,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city_outlined),
            activeIcon: Icon(Icons.location_city),
            label: 'Zones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors_outlined),
            activeIcon: Icon(Icons.sensors),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_outlined),
            activeIcon: Icon(Icons.cloud),
            label: 'Storage',
          ),
        ],
      ),
    );
  }
}