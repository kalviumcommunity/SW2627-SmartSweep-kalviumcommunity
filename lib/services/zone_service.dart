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

  /// Read: live list of typed zones
  Stream<List<Zone>> watchZones() {
    return _zones
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Create (Firestore generates the id)
  Future<void> addZone(Zone zone) async {
    await _zones.add(zone);
  }

  /// Task 1 + 2 + 3: update ONLY the given fields on the document with this id.
  /// Every field not in [fields] is left exactly as it is.
  /// Throws FirebaseException(code: 'not-found') if the document no longer exists.
  Future<void> updateZoneFields(String id, Map<String, Object?> fields) async {
    if (fields.isEmpty) return;
    await _db.collection(collection).doc(id).update(fields);
  }

  /// Changes just missedCount, atomically on the server
  Future<void> recordMissed(String id) =>
      updateZoneFields(id, {'missedCount': FieldValue.increment(1)});

  /// Changes just lastServicedAt
  Future<void> markServiced(String id) =>
      updateZoneFields(id, {'lastServicedAt': Timestamp.now()});

  Future<void> deleteZone(String id) async {
    await _zones.doc(id).delete();
  }
}