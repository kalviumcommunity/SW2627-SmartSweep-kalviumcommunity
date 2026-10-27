import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class AddIssueRecordScreen extends StatefulWidget {
  const AddIssueRecordScreen({super.key});

  @override
  State<AddIssueRecordScreen> createState() => _AddIssueRecordScreenState();
}

class _AddIssueRecordScreenState extends State<AddIssueRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUrgent = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _addedIssues = [];

  @override
  void dispose() {
    _driverController.dispose();
    _phoneController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _addIssue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final driverName = _driverController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final issueDescription = _issueController.text.trim();
      final urgent = _isUrgent;
      String? imageUrl;
      if (_selectedImage != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw StateError('A signed-in user is required to upload images.');
        }
        imageUrl = await _storageService.uploadReportedIssueImage(
          imageFile: _selectedImage!,
          userId: userId,
        );
      }

      final documentId = await _firestoreService.addReportedIssue(
        driverName: driverName,
        phoneNumber: phoneNumber,
        issueDescription: issueDescription,
        isUrgent: urgent,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      // Update UI immediately after Firestore add succeeds.
      setState(() {
        _addedIssues.insert(0, {
          'id': documentId,
          'driverName': driverName,
          'phoneNumber': phoneNumber,
          'issueDescription': issueDescription,
          'isUrgent': urgent,
          'imageUrl': ?imageUrl,
        });

        _driverController.clear();
        _phoneController.clear();
        _issueController.clear();
        _selectedImage = null;
        _selectedImageBytes = null;
        _isUrgent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue added.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      final message = switch (error.code) {
        'permission-denied' => 'You do not have permission to save this issue.',
        'unavailable' => 'No connection. Check your network and try again.',
        _ => 'Could not save the issue. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the issue. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedImage == null || !mounted) return;
      final imageBytes = await pickedImage.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = pickedImage;
        _selectedImageBytes = imageBytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select the image.')),
      );
    }
  }

  Future<void> _showImageSourceOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null && mounted) {
      await _pickImage(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Firestore Record')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report New Issue',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'The submitted issue will be stored in the '
                'reported_issues Firestore collection.',
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _driverController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  hintText: 'Enter driver name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the driver name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter contact number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _issueController,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Issue Description',
                  hintText: 'Describe the collection issue',
                  prefixIcon: Icon(Icons.report_problem_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Urgent Issue'),
                subtitle: Text(
                  _isUrgent ? 'Urgent priority' : 'Normal priority',
                ),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              if (_selectedImage == null)
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _showImageSourceOptions,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add issue photo'),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _selectedImageBytes!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      alignment: Alignment.center,
                      child: const Text('Preview unavailable'),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _isSaving ? null : _showImageSourceOptions,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Replace'),
                      ),
                      TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => setState(() {
                                _selectedImage = null;
                                _selectedImageBytes = null;
                              }),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                ),
              ],

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _addIssue,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSaving ? 'Saving...' : 'Add Issue to Firestore'),
              ),

              const SizedBox(height: 30),

              if (_addedIssues.isNotEmpty) ...[
                const Text(
                  'Recently Added',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ..._addedIssues.map(
                  (issue) => Card(
                    child: ListTile(
                      leading: Icon(
                        issue['isUrgent'] == true
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                      ),
                      title: Text(issue['driverName'].toString()),
                      subtitle: Text(
                        '${issue['issueDescription']}\n'
                        'Phone: ${issue['phoneNumber']}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        issue['isUrgent'] == true ? 'Urgent' : 'Normal',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
