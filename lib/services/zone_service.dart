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

  /// Write: create (Firestore generates the id)
  Future<void> addZone(Zone zone) async {
    await _zones.add(zone);
  }

  /// Write: update the existing document using the model's id
  Future<void> updateZone(Zone zone) async {
    await _zones.doc(zone.id).set(zone);
  }

  Future<void> deleteZone(String id) async {
    await _zones.doc(id).delete();
  }
}