import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StorageStatusScreen extends StatefulWidget {
  const StorageStatusScreen({super.key});

  @override
  State<StorageStatusScreen> createState() => _StorageStatusScreenState();
}

class _StorageStatusScreenState extends State<StorageStatusScreen> {
  // Created inside initState so a bad Firebase setup shows a message
  // on screen instead of crashing the whole app.
  StorageService? _storage;
  String? _setupError;

  bool isLoading = false;
  String? errorMessage;

  // Results of the last test run
  bool? uploadOk;
  int? sizeBytes;
  String? contentType;
  String? downloadUrl;

  @override
  void initState() {
    super.initState();
    try {
      _storage = StorageService(); // uses FirebaseStorage.instance
    } catch (_) {
      _setupError =
          'Could not connect to Firebase Storage. Re-run "flutterfire configure" '
          'after enabling Storage in the console.';
    }
  }

  String _friendlyError(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'unauthenticated':
        return 'Storage rules blocked this. Sign in and check the rules are published.';
      case 'bucket-not-found':
      case 'no-default-bucket':
        return 'No Storage bucket found. Enable Storage in the console, then re-run "flutterfire configure".';
      case 'project-not-found':
        return 'Firebase project not found. Check your Firebase configuration.';
      case 'quota-exceeded':
        return 'Storage quota exceeded for this project.';
      case 'retry-limit-exceeded':
      case 'unavailable':
        return 'Could not reach Storage. Check your connection and try again.';
      default:
        return 'Storage test failed (${e.code}). Please try again.';
    }
  }

  Future<void> _runTest() async {
    final storage = _storage;
    if (storage == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      uploadOk = null;
      sizeBytes = null;
      contentType = null;
      downloadUrl = null;
    });

    try {
      await storage.uploadTestFile(); // write
      final meta = await storage.getTestMetadata(); // read back
      final url = await storage.getTestDownloadUrl(); // serve

      if (!mounted) return;
      setState(() {
        uploadOk = true;
        sizeBytes = meta.size;
        contentType = meta.contentType;
        downloadUrl = url;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = _friendlyError(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _row(IconData icon, String label, String value, {Color? color}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = _storage;
    final ok = Colors.green.shade700;

    return Scaffold(
      appBar: AppBar(title: const Text('Storage connection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_setupError != null)
            Card(
              color: Colors.red.withAlpha(25),
              child: ListTile(
                leading: Icon(Icons.error_outline, color: Colors.red.shade700),
                title: Text(_setupError!),
              ),
            )
          else if (storage != null) ...[
            Card(
              child: Column(
                children: [
                  _row(Icons.cloud_outlined, 'Connected bucket', storage.bucket),
                  _row(Icons.folder_outlined, 'Reference path',
                      storage.testRef.fullPath),
                  _row(Icons.insert_drive_file_outlined, 'File name',
                      storage.testRef.name),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _runTest,
                icon: const Icon(Icons.cloud_upload),
                label: Text(isLoading ? 'Testing...' : 'Run connection test'),
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.withAlpha(25),
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red.shade700),
                  title: Text(errorMessage!),
                ),
              ),
            ],
            if (uploadOk == true) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.withAlpha(25),
                child: Column(
                  children: [
                    _row(Icons.check_circle, 'Upload', 'Succeeded', color: ok),
                    _row(Icons.check_circle, 'Metadata read back',
                        '$sizeBytes bytes, $contentType',
                        color: ok),
                    _row(Icons.check_circle, 'Download URL created',
                        downloadUrl ?? '',
                        color: ok),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}