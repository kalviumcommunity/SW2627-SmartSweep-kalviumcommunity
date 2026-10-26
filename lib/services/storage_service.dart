import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Small wrapper around FirebaseStorage.instance so screens never
/// touch Firebase directly (same pattern as AuthService).
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// The bucket this app is connected to, e.g. "gs://my-project.firebasestorage.app"
  String get bucket => _storage.bucket;

  /// A reference points at a path in the bucket. It does not upload or
  /// download anything by itself.
  Reference get testRef => _storage.ref('connection_test/hello.txt');

  /// Uploads a tiny text file to prove writes work.
  Future<void> uploadTestFile() async {
    final bytes = Uint8List.fromList(
      utf8.encode('SmartSweep storage test at ${DateTime.now().toIso8601String()}'),
    );
    await testRef.putData(bytes, SettableMetadata(contentType: 'text/plain'));
  }

  /// Reads the file's metadata back to prove the upload landed.
  Future<FullMetadata> getTestMetadata() => testRef.getMetadata();

  /// The URL a client can use to serve the file.
  Future<String> getTestDownloadUrl() => testRef.getDownloadURL();
}