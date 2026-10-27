import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'storage_file_uploader_stub.dart'
    if (dart.library.io) 'storage_file_uploader_io.dart'
    as uploader;

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
      utf8.encode(
        'SmartSweep storage test at ${DateTime.now().toIso8601String()}',
      ),
    );
    await testRef.putData(bytes, SettableMetadata(contentType: 'text/plain'));
  }

  /// Reads the file's metadata back to prove the upload landed.
  Future<FullMetadata> getTestMetadata() => testRef.getMetadata();

  /// The URL a client can use to serve the file.
  Future<String> getTestDownloadUrl() => testRef.getDownloadURL();

  Future<String> uploadReportedIssueImage({
    required XFile imageFile,
    required String userId,
  }) async {
    final extension = imageFile.path.split('.').last.toLowerCase();
    final safeExtension = RegExp(r'^[a-z0-9]+$').hasMatch(extension)
        ? extension
        : 'jpg';
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
    final imageRef = _storage.ref('reportedIssues/$userId/$fileName');

    try {
      await uploader.upload(imageRef, imageFile);
      return await imageRef.getDownloadURL();
    } on FirebaseException catch (error) {
      throw StateError(
        'Unable to upload issue image: ${error.message ?? error.code}',
      );
    }
  }
}
