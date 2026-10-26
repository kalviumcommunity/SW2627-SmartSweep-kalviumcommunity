import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // --------------------------------------------------
  // CURRENT USER
  // --------------------------------------------------

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'A signed-in user is required to access Firestore.',
      );
    }

    return user;
  }

  // --------------------------------------------------
  // FIRESTORE CONNECTION TEST
  // --------------------------------------------------

  Future<void> addConnectionTest() async {
    final user = _currentUser;

    await _firestore
        .collection('connection_tests')
        .add({
      'message':
          'SmartSweep connected to Cloud Firestore',
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --------------------------------------------------
  // READ LATEST CONNECTION TEST
  // --------------------------------------------------

  Future<String> readLatestTest() async {
    final user = _currentUser;

    final snapshot = await _firestore
        .collection('connection_tests')
        .where(
          'ownerId',
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'No Firestore records found.';
    }

    final data = snapshot.docs.first.data();

    return data['message']?.toString() ??
        'Firestore record found.';
  }

  // --------------------------------------------------
  // ADD REPORTED ISSUE
  // --------------------------------------------------

  Future<String> addReportedIssue({
    required String driverName,
    required String phoneNumber,
    required String issueDescription,
    required bool isUrgent,
  }) async {
    final user = _currentUser;

    final document = await _firestore
        .collection('reported_issues')
        .add({
      'driverName': driverName,
      'phoneNumber': phoneNumber,
      'issueDescription': issueDescription,
      'isUrgent': isUrgent,

      // Used by Firestore Security Rules.
      'ownerId': user.uid,

      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // --------------------------------------------------
  // FETCH CURRENT USER'S REPORTED ISSUES
  // --------------------------------------------------

  Future<List<Map<String, dynamic>>>
      fetchReportedIssues() async {
    final user = _currentUser;

    final snapshot = await _firestore
        .collection('reported_issues')
        .where(
          'ownerId',
          isEqualTo: user.uid,
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

  // --------------------------------------------------
  // FILTER REPORTED ISSUES BY URGENCY
  // --------------------------------------------------

  Future<List<Map<String, dynamic>>>
      getReportedIssuesByUrgency({
    required bool isUrgent,
  }) async {
    final user = _currentUser;

    final snapshot = await _firestore
        .collection('reported_issues')
        .where(
          'ownerId',
          isEqualTo: user.uid,
        )
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

  // --------------------------------------------------
  // DELETE REPORTED ISSUE
  // --------------------------------------------------

  Future<void> deleteReportedIssue(
    String documentId,
  ) async {
    final user = _currentUser;

    final documentReference =
        _firestore
            .collection('reported_issues')
            .doc(documentId);

    final document =
        await documentReference.get();

    if (!document.exists) {
      throw StateError(
        'Reported issue does not exist.',
      );
    }

    final data = document.data();

    if (data == null) {
      throw StateError(
        'Reported issue data is unavailable.',
      );
    }

    if (data['ownerId'] != user.uid) {
      throw StateError(
        'You are not allowed to delete this reported issue.',
      );
    }

    await documentReference.delete();
  }
}