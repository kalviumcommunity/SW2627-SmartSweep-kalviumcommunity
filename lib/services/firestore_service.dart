import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addConnectionTest() async {
    await _firestore.collection('connection_tests').add({
      'message': 'SmartSweep connected to Cloud Firestore',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> readLatestTest() async {
    final snapshot = await _firestore
        .collection('connection_tests')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'No Firestore records found.';
    }

    final data = snapshot.docs.first.data();

    return data['message']?.toString() ??
        'Firestore record found.';
  }
}