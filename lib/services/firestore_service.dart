import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Previous Firestore connection test
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

    return data['message']?.toString() ?? 'Firestore record found.';
  }

  // NEW: Add a real record from user input
  Future<String> addReportedIssue({
    required String driverName,
    required String phoneNumber,
    required String issueDescription,
    required bool isUrgent,
  }) async {
    final document = await _firestore.collection('reported_issues').add({
      'driverName': driverName,
      'phoneNumber': phoneNumber,
      'issueDescription': issueDescription,
      'isUrgent': isUrgent,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<List<Map<String, dynamic>>> fetchReportedIssues() async {
    final snapshot = await _firestore.collection('reported_issues').get();
    final issues = snapshot.docs
        .map(
          (document) => <String, dynamic>{
            ...document.data(),
            'id': document.id,
          },
        )
        .toList();

    DateTime? createdAtOf(Map<String, dynamic> issue) {
      final value = issue['createdAt'];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    issues.sort((left, right) {
      final leftCreatedAt = createdAtOf(left);
      final rightCreatedAt = createdAtOf(right);

      if (leftCreatedAt == null) return rightCreatedAt == null ? 0 : 1;
      if (rightCreatedAt == null) return -1;
      return rightCreatedAt.compareTo(leftCreatedAt);
    });

    return issues;
  }
}
