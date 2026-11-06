import 'package:flutter/material.dart';

class StatusColors {
  static Color of(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'completed':
      case 'success':
      case 'active':
      case 'available':
        return const Color(0xFF0F8A5F); // Emerald Green
      case 'claimed':
      case 'pending':
      case 'review':
        return const Color(0xFF7C3AED); // Royal Violet / Verification pending
      case 'in progress':
      case 'in_progress':
      case 'started':
        return const Color(0xFF0284C7); // Deep Sky Blue
      case 'scheduled':
        return const Color(0xFF4B5563); // Cool Slate Gray
      case 'delayed':
      case 'warning':
        return const Color(0xFFD97706); // Amber Warning
      case 'missed':
      case 'failed':
      case 'cancelled':
      case 'breakdown':
      case 'interrupted':
      case 'broken down':
      case 'unresolved':
        return const Color(0xFFDC2626); // Crimson Red
      case 'resolved':
        return const Color(0xFF059669); // Muted Emerald
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  static Color backgroundOf(String status) {
    return of(status).withAlpha(24);
  }

  static Color borderOf(String status) {
    return of(status).withAlpha(80);
  }

  static IconData iconOf(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'completed':
      case 'success':
        return Icons.verified_rounded;
      case 'claimed':
      case 'pending':
      case 'review':
        return Icons.hourglass_top_rounded;
      case 'in progress':
      case 'in_progress':
      case 'started':
        return Icons.play_circle_filled_rounded;
      case 'scheduled':
        return Icons.calendar_today_rounded;
      case 'delayed':
      case 'warning':
        return Icons.access_time_filled_rounded;
      case 'breakdown':
      case 'interrupted':
      case 'broken down':
        return Icons.car_crash_rounded;
      case 'missed':
      case 'failed':
      case 'cancelled':
      case 'unresolved':
        return Icons.cancel_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'active':
      case 'available':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
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
