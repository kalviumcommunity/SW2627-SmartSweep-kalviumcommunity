import 'package:flutter/material.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.routeName,
    required this.driverName,
    required this.zonesDone,
    required this.zonesTotal,
    required this.status,
  });

  final String routeName;
  final String driverName;
  final int zonesDone;
  final int zonesTotal;
  final String status; // completed, in progress, delayed, missed

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'in progress':
        return Colors.blue.shade700;
      case 'delayed':
        return Colors.orange.shade800;
      case 'missed':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final progress = zonesTotal == 0 ? 0.0 : zonesDone / zonesTotal;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    routeName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Driver: $driverName', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: color,
                backgroundColor: color.withAlpha(30),
              ),
            ),
            const SizedBox(height: 8),
            Text('$zonesDone of $zonesTotal zones serviced'),
          ],
        ),
      ),
    );
  }
}