import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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

  Future<String> addReportedIssue({
    required String driverName,
    required String phoneNumber,
    required String issueDescription,
    required bool isUrgent,
  }) async {
    final document =
        await _firestore.collection('reported_issues').add({
      'driverName': driverName,
      'phoneNumber': phoneNumber,
      'issueDescription': issueDescription,
      'isUrgent': isUrgent,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // NEW: Firestore query using where()
  Future<List<Map<String, dynamic>>>
      getReportedIssuesByUrgency({
    required bool isUrgent,
  }) async {
    final snapshot = await _firestore
        .collection('reported_issues')
        .where(
          'isUrgent',
          isEqualTo: isUrgent,
        )
        .get();

    return snapshot.docs.map((document) {
      final data = document.data();

      return {
        'id': document.id,
        ...data,
      };
    }).toList();
  }
}