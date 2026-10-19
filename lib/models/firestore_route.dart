import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines the consistent Firestore document structure for a waste collection route.
class FirestoreRoute {
  const FirestoreRoute({
    required this.routeName,
    required this.zone,
    required this.status,
    required this.zonesDone,
    required this.zonesTotal,
    required this.createdAt,
    required this.ownerId,
  });

  final String routeName;
  final String zone;
  final String status;
  final int zonesDone;
  final int zonesTotal;
  final Timestamp? createdAt;
  final String ownerId;

  /// Converts this route into a consistent Firestore document.
  Map<String, dynamic> toFirestore() {
    return {
      'routeName': routeName,
      'zone': zone,
      'status': status,
      'zonesDone': zonesDone,
      'zonesTotal': zonesTotal,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'ownerId': ownerId,
    };
  }

  /// Creates a route from a Firestore document.
  factory FirestoreRoute.fromFirestore(Map<String, dynamic> data) {
    return FirestoreRoute(
      routeName: data['routeName'] as String? ?? '',
      zone: data['zone'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
      zonesDone: (data['zonesDone'] as num?)?.toInt() ?? 0,
      zonesTotal: (data['zonesTotal'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      ownerId: data['ownerId'] as String? ?? '',
    );
  }
}
