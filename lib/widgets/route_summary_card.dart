import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/waste_collection_route.dart';
import 'status_chip.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({super.key, required this.route});

  final WasteCollectionRoute route;

  Color _statusColor() {
    if (route.isCompleted) {
      return const Color(0xFF0F8A5F);
    }

    switch (route.status.toLowerCase()) {
      case 'in progress':
      case 'in_progress':
        return const Color(0xFF0284C7);
      case 'delayed':
        return const Color(0xFFD97706);
      case 'missed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final progress = route.zonesTotal == 0
        ? 0.0
        : route.zonesDone / route.zonesTotal;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.outline, width: 1.2),
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
                    route.routeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF132B22),
                        ),
                  ),
                ),
                StatusChip(route.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF5A6E63)),
                const SizedBox(width: 4),
                Text(
                  'Driver: ${route.driverName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5A6E63), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: color,
                backgroundColor: color.withAlpha(25),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              route.label(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B6056), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
