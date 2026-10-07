import 'package:flutter/material.dart';

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
  const DashboardPage({super.key});

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
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
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
                icon: Icons.local_shipping,
              ),
              KpiCard(
                title: 'Pending Routes',
                value: '5',
                icon: Icons.pending_actions,
              ),
              KpiCard(
                title: 'Completed',
                value: '18',
                icon: Icons.check_circle,
              ),
              KpiCard(
                title: 'Alerts',
                value: '3',
                icon: Icons.warning,
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
              onPressed: () {},
              icon: const Icon(Icons.route),
              label: const Text('View All Routes'),
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

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.local_shipping),
        ),
        title: Text(
          route,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('$area • Driver: $driver'),
        trailing: Text(
          status,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search routes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Chip(
                avatar: Icon(Icons.filter_list, size: 18),
                label: Text('Filter'),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              RouteTile(
                route: 'Route 01',
                area: 'Vijay Nagar',
                driver: 'Rahul',
                status: 'Active',
              ),
              RouteTile(
                route: 'Route 02',
                area: 'Palasia',
                driver: 'Aman',
                status: 'Pending',
              ),
              RouteTile(
                route: 'Route 03',
                area: 'Rau',
                driver: 'Neha',
                status: 'Completed',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RouteTile extends StatelessWidget {
  final String route;
  final String area;
  final String driver;
  final String status;

  const RouteTile({
    super.key,
    required this.route,
    required this.area,
    required this.driver,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.route),
        title: Text(route),
        subtitle: Text('$area • $driver'),
        trailing: Text(status),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailsPage(
                route: route,
                area: area,
                driver: driver,
                status: status,
              ),
            ),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------
// ROUTE DETAILS
// --------------------------------------------------

class RouteDetailsPage extends StatelessWidget {
  final String route;
  final String area;
  final String driver;
  final String status;

  const RouteDetailsPage({
    super.key,
    required this.route,
    required this.area,
    required this.driver,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(route),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            DetailRow(
              label: 'Area',
              value: area,
            ),

            DetailRow(
              label: 'Driver',
              value: driver,
            ),

            DetailRow(
              label: 'Current Status',
              value: status,
            ),

            const SizedBox(height: 30),

            const Text(
              'Collection Stops',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Stop 1'),
              subtitle: Text('Completed'),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Stop 2'),
              subtitle: Text('Completed'),
            ),

            const ListTile(
              leading: Icon(Icons.radio_button_unchecked),
              title: Text('Stop 3'),
              subtitle: Text('Pending'),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Update Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
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
        AlertTile(
          title: 'Route 02 delayed',
          description: 'Collection is running 20 minutes late.',
          icon: Icons.warning,
        ),
        AlertTile(
          title: 'Vehicle maintenance',
          description: 'Truck 12 requires maintenance.',
          icon: Icons.build,
        ),
        AlertTile(
          title: 'Route completed',
          description: 'Route 03 has been completed.',
          icon: Icons.check_circle,
        ),
      ],
    );
  }
}

class AlertTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const AlertTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              'Reports',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Collection performance reports will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}