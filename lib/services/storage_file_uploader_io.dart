import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<void> upload(Reference reference, XFile imageFile) =>
    reference.putFile(File(imageFile.path));
