import 'package:flutter/material.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Routes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Zone A Route'),
              subtitle: const Text('Morning collection route'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RouteDetailScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}