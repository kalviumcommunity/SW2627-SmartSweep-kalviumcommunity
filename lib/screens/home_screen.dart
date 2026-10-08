import 'package:flutter/material.dart';
import 'routes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    RoutesPage(),
    AlertsPage(),
    ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartSweep',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),

      body: pages[selectedIndex],

      // Opens the new navigation assignment flow
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoutesScreen(),
            ),
          );
        },
        icon: const Icon(Icons.route),
        label: const Text('Routes'),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

// ---------------- Dashboard Page ----------------

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Monitor waste collection activities and route status.',
          ),
          SizedBox(height: 30),
          Card(
            child: ListTile(
              leading: Icon(Icons.local_shipping),
              title: Text('Active Routes'),
              subtitle: Text('Track ongoing waste collection routes'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber),
              title: Text('Incidents'),
              subtitle: Text('View reported route problems'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Routes Tab ----------------

class RoutesPage extends StatelessWidget {
  const RoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Routes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(Icons.route),
            title: Text('Zone A'),
            subtitle: Text('Morning waste collection route'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.route),
            title: Text('Zone B'),
            subtitle: Text('Afternoon waste collection route'),
          ),
        ),
      ],
    );
  }
}

// ---------------- Alerts Page ----------------

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Alerts',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(Icons.warning),
            title: Text('Vehicle Issue'),
            subtitle: Text('No active vehicle issues'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Route Status'),
            subtitle: Text('No missed routes reported'),
          ),
        ),
      ],
    );
  }
}

// ---------------- Reports Page ----------------

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Reports',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(Icons.analytics_outlined),
            title: Text('Collection Report'),
            subtitle: Text('View route completion statistics'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.history),
            title: Text('Route History'),
            subtitle: Text('Review previous collection activity'),
          ),
        ),
      ],
    );
  }
}