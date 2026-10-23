import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/zone.dart';

class ZoneService {
  ZoneService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const collection = 'zones';
  final FirebaseFirestore _db;

  /// A typed collection: reads give Zone, writes accept Zone.
  CollectionReference<Zone> get _zones => _db.collection(collection).withConverter<Zone>(
        fromFirestore: (snap, options) => Zone.fromFirestore(snap, options),
        toFirestore: (zone, _) => zone.toFirestore(),
      );

  /// Real-time: live list of typed zones
  Stream<List<Zone>> watchZones() {
    return _zones
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Real-time: the full snapshot, including which documents were
  /// added, modified or removed (docChanges) and whether it came from cache.
  Stream<QuerySnapshot<Zone>> watchZoneSnapshots() {
    return _zones.orderBy('name').snapshots();
  }

  /// One-time read: a single fetch that never updates afterwards.
  Future<List<Zone>> fetchZonesOnce() async {
    final snap = await _zones.orderBy('name').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Create (Firestore generates the id)
  Future<void> addZone(Zone zone) async {
    await _zones.add(zone);
  }

  /// Update ONLY the given fields on the document with this id.
  Future<void> updateZoneFields(String id, Map<String, Object?> fields) async {
    if (fields.isEmpty) return;
    await _db.collection(collection).doc(id).update(fields);
  }

  Future<void> recordMissed(String id) =>
      updateZoneFields(id, {'missedCount': FieldValue.increment(1)});

  Future<void> markServiced(String id) =>
      updateZoneFields(id, {'lastServicedAt': Timestamp.now()});

  Future<void> deleteZone(String id) async {
    await _zones.doc(id).delete();
  }
}