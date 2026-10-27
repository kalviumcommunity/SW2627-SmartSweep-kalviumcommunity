import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_issue_record_screen.dart';
import 'fetch_reported_issues_screen.dart';
import 'filtered_issues_screen.dart';
import 'firestore_test_screen.dart';
import 'report_issue_screen.dart';
import 'route_list_screen.dart';

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

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      // No Navigator.push is required here.
      // AuthGate automatically detects that the
      // Firebase user became null and displays LoginScreen.
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'Unable to log out. Please try again.',
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // LOGOUT CONFIRMATION
  // --------------------------------------------------

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out of SmartSweep?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

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
          // ------------------------------------------------
          // ADD FIRESTORE RECORD
          // ------------------------------------------------

          IconButton(
            tooltip: 'Add Firestore Record',
            icon: const Icon(
              Icons.add_circle_outline,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AddIssueRecordScreen(),
                ),
              );
            },
          ),

          // ------------------------------------------------
          // FILTER FIRESTORE RECORDS
          // ------------------------------------------------

          IconButton(
            tooltip: 'Filter Reported Issues',
            icon: const Icon(
              Icons.filter_alt_outlined,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FilteredIssuesScreen(),
                ),
              );
            },
          ),

          // ------------------------------------------------
          // FIRESTORE TEST
          // ------------------------------------------------

          IconButton(
            tooltip: 'Firestore Test',
            icon: const Icon(
              Icons.cloud_outlined,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FirestoreTestScreen(),
                ),
              );
            },
          ),

          // ------------------------------------------------
          // LOGOUT
          // ------------------------------------------------

          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),

      body: pages[selectedIndex],

      // --------------------------------------------------
      // BOTTOM NAVIGATION
      // --------------------------------------------------

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.route_outlined,
            ),
            selectedIcon: Icon(
              Icons.route,
            ),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.notifications_outlined,
            ),
            selectedIcon: Icon(
              Icons.notifications,
            ),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bar_chart_outlined,
            ),
            selectedIcon: Icon(
              Icons.bar_chart,
            ),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

// ==================================================
// DASHBOARD
// ==================================================

class DashboardPage extends StatelessWidget {
  final VoidCallback onViewRoutes;

  const DashboardPage({
    super.key,
    required this.onViewRoutes,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------
          // WELCOME
          // ------------------------------------------------

          const Text(
            "Today's Overview",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            user?.email != null
                ? 'Signed in as ${user!.email}'
                : 'Monitor waste collection activity at a glance.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------
          // KPI CARDS
          // ------------------------------------------------

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
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

          // ------------------------------------------------
          // ROUTE STATUS
          // ------------------------------------------------

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

          // ------------------------------------------------
          // VIEW ROUTES
          // ------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewRoutes,
              icon: const Icon(
                Icons.route,
              ),
              label: const Text(
                'View All Routes',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------
          // REPORT ISSUE
          // ------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ReportIssueScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.report_problem_outlined,
              ),
              label: const Text(
                'Report an Issue',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------
          // ADD ISSUE TO FIRESTORE
          // ------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddIssueRecordScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.cloud_upload_outlined,
              ),
              label: const Text(
                'Add Issue to Firestore',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------
          // VIEW FIRESTORE ISSUES
          // ------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FetchReportedIssuesScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.list_alt_outlined,
              ),
              label: const Text(
                'View Reported Issues',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------
          // FILTER FIRESTORE ISSUES
          // ------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FilteredIssuesScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.filter_alt_outlined,
              ),
              label: const Text(
                'Filter Reported Issues',
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ==================================================
// KPI CARD
// ==================================================

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
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),

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

// ==================================================
// ROUTE STATUS CARD
// ==================================================

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
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              statusColor.withAlpha(30),
          child: Icon(
            Icons.local_shipping_outlined,
            color: statusColor,
          ),
        ),
        title: Text(
          route,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$area • Driver: $driver',
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                statusColor.withAlpha(30),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================
// ROUTES PAGE
// ==================================================

class RoutesPage extends StatelessWidget {
  const RoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RouteListScreen();
  }
}

// ==================================================
// ALERTS PAGE
// ==================================================

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Alerts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 16),

        Card(
          child: ListTile(
            leading: Icon(
              Icons.warning_amber,
              color: Colors.orange,
            ),
            title: Text(
              'Collection pending',
            ),
            subtitle: Text(
              'Route 02 • Palasia',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: Icon(
              Icons.notifications_active,
              color: Colors.red,
            ),
            title: Text(
              'Collection alert',
            ),
            subtitle: Text(
              'Review the reported collection issue.',
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================
// REPORTS PAGE
// ==================================================

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Reports',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 16),

        Card(
          child: ListTile(
            leading: Icon(
              Icons.assessment_outlined,
              color: Colors.green,
            ),
            title: Text(
              'Collection Summary',
            ),
            subtitle: Text(
              'View waste collection activity.',
            ),
          ),
        ),
      ],
    );
  }
}