import 'package:flutter/material.dart';

class StatusColors {
  static Color of(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'active':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'missed':
      case 'failed':
      case 'cancelled':
        return Colors.red;
      case 'in progress':
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  static String label(String status) {
    if (status.isEmpty) return 'Unknown';

    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
