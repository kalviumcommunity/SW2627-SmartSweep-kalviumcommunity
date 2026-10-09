
import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedRoute;
  String? _selectedIssue;

  final List<String> _routes = [
    'Route 01',
    'Route 02',
    'Route 03',
  ];

  final List<String> _issues = [
    'Missed collection',
    'Vehicle delay',
    'Overflowing bin',
    'Damaged vehicle',
    'Other',
  ];

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_selectedIssue reported for $_selectedRoute successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );

    _formKey.currentState!.reset();
    _descriptionController.clear();

    setState(() {
      _selectedRoute = null;
      _selectedIssue = null;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Collection Issue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide details so the team can investigate.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // ROUTE SELECTION
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Route',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.route),
                ),
                items: _routes.map((route) {
                  return DropdownMenuItem<String>(
                    value: route,
                    child: Text(route),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoute = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a route';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ISSUE TYPE
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                items: _issues.map((issue) {
                  return DropdownMenuItem<String>(
                    value: issue,
                    child: Text(issue),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIssue = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an issue type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ISSUE DESCRIPTION
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue';
                  }

                  if (value.trim().length < 10) {
                    return 'Enter at least 10 characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 28),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Report'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
