import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore document: zones/{id}
///
/// Fields stored (keys must match exactly):
///   name           string
///   area           string
///   scheduleDay    string
///   missedCount    number
///   isActive       boolean
///   lastServicedAt timestamp (nullable)
///   createdAt      timestamp
///
/// The document id is NOT a field. It is the document's address,
/// so it lives on the model but is never written by toFirestore().
class Zone {
  final String id;
  final String name;
  final String area;
  final String scheduleDay;
  final int missedCount;
  final bool isActive;
  final DateTime? lastServicedAt;
  final DateTime createdAt;

  const Zone({
    required this.id,
    required this.name,
    required this.area,
    required this.scheduleDay,
    required this.createdAt,
    this.missedCount = 0,
    this.isActive = true,
    this.lastServicedAt,
  });

  /// Derived value: 3 or more misses flags a recurring problem zone.
  bool get hasRecurringMisses => missedCount >= 3;

  /// Task 2: document snapshot -> typed object
  factory Zone.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, [
    SnapshotOptions? options,
  ]) {
    final data = doc.data() ?? {};
    return Zone(
      id: doc.id,
      name: data['name'] as String? ?? '',
      area: data['area'] as String? ?? '',
      scheduleDay: data['scheduleDay'] as String? ?? '',
      missedCount: (data['missedCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      lastServicedAt: (data['lastServicedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Task 3: typed object -> map for Firestore (no id)
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'area': area,
        'scheduleDay': scheduleDay,
        'missedCount': missedCount,
        'isActive': isActive,
        'lastServicedAt':
            lastServicedAt == null ? null : Timestamp.fromDate(lastServicedAt!),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Zone copyWith({
    String? name,
    String? area,
    String? scheduleDay,
    int? missedCount,
    bool? isActive,
    DateTime? lastServicedAt,
  }) {
    return Zone(
      id: id,
      name: name ?? this.name,
      area: area ?? this.area,
      scheduleDay: scheduleDay ?? this.scheduleDay,
      missedCount: missedCount ?? this.missedCount,
      isActive: isActive ?? this.isActive,
      lastServicedAt: lastServicedAt ?? this.lastServicedAt,
      createdAt: createdAt,
    );
  }
}