
import 'package:flutter/material.dart';
import 'report_issue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  late final List<Widget> pages = [
    DashboardPage(
      onViewRoutes: () {
        setState(() {
          selectedIndex = 1;
        });
      },
    ),
    const RoutesPage(),
    const AlertsPage(),
    const ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartSweep',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: pages[selectedIndex],
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

// --------------------------------------------------
// DASHBOARD
// --------------------------------------------------

class DashboardPage extends StatelessWidget {
  final VoidCallback onViewRoutes;

  const DashboardPage({
    super.key,
    required this.onViewRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Overview",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monitor waste collection activity at a glance.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // KPI CARDS
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: const [
              KpiCard(
                title: 'Active Routes',
                value: '12',
                icon: Icons.route,
                color: Colors.green,
              ),
              KpiCard(
                title: 'Pending Routes',
                value: '5',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              KpiCard(
                title: 'Completed',
                value: '18',
                icon: Icons.check_circle_outline,
                color: Colors.blue,
              ),
              KpiCard(
                title: 'Alerts',
                value: '3',
                icon: Icons.warning_amber,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'Route Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          const RouteStatusCard(
            route: 'Route 01',
            area: 'Vijay Nagar',
            driver: 'Rahul',
            status: 'Active',
          ),
          const RouteStatusCard(
            route: 'Route 02',
            area: 'Palasia',
            driver: 'Aman',
            status: 'Pending',
          ),
          const RouteStatusCard(
            route: 'Route 03',
            area: 'Rau',
            driver: 'Neha',
            status: 'Completed',
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewRoutes,
              icon: const Icon(Icons.route),
              label: const Text('View All Routes'),
            ),
          ),

          const SizedBox(height: 12),

          // LU 3.16: REPORT ISSUE FORM
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportIssueScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report an Issue'),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// KPI CARD
// --------------------------------------------------

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// ROUTE STATUS CARD
// --------------------------------------------------

class RouteStatusCard extends StatelessWidget {
  final String route;
  final String area;
  final String driver;
  final String status;

  const RouteStatusCard({
    super.key,
    required this.route,
    required this.area,
    required this.driver,
    required this.status,
  });

  Color get statusColor {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(30),
          child: Icon(Icons.local_shipping_outlined, color: statusColor),
        ),
        title: Text(
          route,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$area • Driver: $driver'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// ROUTES
// --------------------------------------------------

class RoutesPage extends StatelessWidget {
  const RoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'All Routes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        RouteStatusCard(
          route: 'Route 01',
          area: 'Vijay Nagar',
          driver: 'Rahul',
          status: 'Active',
        ),
        RouteStatusCard(
          route: 'Route 02',
          area: 'Palasia',
          driver: 'Aman',
          status: 'Pending',
        ),
        RouteStatusCard(
          route: 'Route 03',
          area: 'Rau',
          driver: 'Neha',
          status: 'Completed',
        ),
      ],
    );
  }
}

// --------------------------------------------------
// ALERTS
// --------------------------------------------------

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Alerts',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.warning_amber, color: Colors.orange),
            title: Text('Collection pending'),
            subtitle: Text('Route 02 • Palasia'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.red),
            title: Text('Collection alert'),
            subtitle: Text('Review the reported collection issue.'),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// REPORTS
// --------------------------------------------------

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Reports',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.assessment_outlined, color: Colors.green),
            title: Text('Collection Summary'),
            subtitle: Text('View waste collection activity.'),
          ),
        ),
      ],
    );
  }
}
