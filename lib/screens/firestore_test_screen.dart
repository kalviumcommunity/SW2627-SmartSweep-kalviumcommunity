import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() =>
      _FirestoreTestScreenState();
}

class _FirestoreTestScreenState
    extends State<FirestoreTestScreen> {
  final FirestoreService _firestoreService =
      FirestoreService();

  bool _isLoading = false;
  String _message = 'Firestore is ready to test.';

  Future<void> _writeRecord() async {
    setState(() {
      _isLoading = true;
      _message = 'Writing to Firestore...';
    });

    try {
      await _firestoreService.addConnectionTest();

      if (!mounted) return;

      setState(() {
        _message =
            'Success! Record written to Firestore.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message =
            'Unable to write to Firestore. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _readRecord() async {
    setState(() {
      _isLoading = true;
      _message = 'Reading from Firestore...';
    });

    try {
      final result =
          await _firestoreService.readLatestTest();

      if (!mounted) return;

      setState(() {
        _message = 'Latest record: $result';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message =
            'Unable to read Firestore data.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.cloud_done,
              size: 80,
            ),

            const SizedBox(height: 24),

            const Text(
              'Cloud Firestore Integration',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _message,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed:
                  _isLoading ? null : _writeRecord,
              icon: const Icon(Icons.cloud_upload),
              label: const Text(
                'Write Test Record',
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed:
                  _isLoading ? null : _readRecord,
              icon: const Icon(Icons.cloud_download),
              label: const Text(
                'Read Latest Record',
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 30),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}