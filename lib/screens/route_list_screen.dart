import 'package:flutter/material.dart';

import '../models/waste_collection_route.dart';
import '../widgets/route_summary_card.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  final List<WasteCollectionRoute> routes = [
    const WasteCollectionRoute(
      id: 'route-01',
      routeName: 'Route 01 - Vijay Nagar',
      driverName: 'Rahul',
      zonesDone: 8,
      zonesTotal: 10,
      status: 'In Progress',
    ),
    const WasteCollectionRoute(
      id: 'route-02',
      routeName: 'Route 02 - Palasia',
      driverName: 'Aman',
      zonesDone: 3,
      zonesTotal: 8,
      status: 'Delayed',
    ),
    const WasteCollectionRoute(
      id: 'route-03',
      routeName: 'Route 03 - Rau',
      driverName: 'Neha',
      zonesDone: 10,
      zonesTotal: 10,
      status: 'Completed',
    ),
    const WasteCollectionRoute(
      id: 'route-04',
      routeName: 'Route 04 - Arera Colony',
      driverName: 'Priya',
      zonesDone: 0,
      zonesTotal: 6,
      status: 'Missed',
    ),
  ];

  void addSampleRoute() {
    setState(() {
      final routeNumber = routes.length + 1;
      routes.add(
        WasteCollectionRoute(
          id: 'route-${routeNumber.toString().padLeft(2, '0')}',
          routeName: 'Route $routeNumber',
          driverName: 'New Driver',
          zonesDone: 0,
          zonesTotal: 5,
          status: 'In Progress',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection Routes')),
      body: routes.isEmpty
          ? const Center(child: Text('No routes available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];

                return RouteSummaryCard(route: route);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addSampleRoute,
        tooltip: 'Add sample route',
        child: const Icon(Icons.add),
      ),
    );
  }
}
