import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class AddIssueRecordScreen extends StatefulWidget {
  const AddIssueRecordScreen({super.key});

  @override
  State<AddIssueRecordScreen> createState() =>
      _AddIssueRecordScreenState();
}

class _AddIssueRecordScreenState
    extends State<AddIssueRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _driverController =
      TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController();
  final TextEditingController _issueController =
      TextEditingController();

  final FirestoreService _firestoreService =
      FirestoreService();

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

    final driverName = _driverController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final issueDescription = _issueController.text.trim();
    final urgent = _isUrgent;

    setState(() {
      _isSaving = true;
    });

    try {
      final documentId =
          await _firestoreService.addReportedIssue(
        driverName: driverName,
        phoneNumber: phoneNumber,
        issueDescription: issueDescription,
        isUrgent: urgent,
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
        });

        _driverController.clear();
        _phoneController.clear();
        _issueController.clear();
        _isUrgent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Issue saved successfully to Firestore.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save the issue. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Firestore Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report New Issue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                  if (value == null ||
                      value.trim().isEmpty) {
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
                  if (value == null ||
                      value.trim().isEmpty) {
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
                  prefixIcon:
                      Icon(Icons.report_problem_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
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
                  _isUrgent
                      ? 'Urgent priority'
                      : 'Normal priority',
                ),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _addIssue,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Add Issue to Firestore',
                ),
              ),

              const SizedBox(height: 30),

              if (_addedIssues.isNotEmpty) ...[
                const Text(
                  'Recently Added',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                      title: Text(
                        issue['driverName'].toString(),
                      ),
                      subtitle: Text(
                        '${issue['issueDescription']}\n'
                        'Phone: ${issue['phoneNumber']}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        issue['isUrgent'] == true
                            ? 'Urgent'
                            : 'Normal',
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