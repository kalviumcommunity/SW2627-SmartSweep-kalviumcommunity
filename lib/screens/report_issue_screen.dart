import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController issueController = TextEditingController();

  @override
  void dispose() {
    driverNameController.dispose();
    phoneController.dispose();
    issueController.dispose();
    super.dispose();
  }

  void submitIssue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String driverName = driverNameController.text.trim();
    final String phone = phoneController.text.trim();
    final String issue = issueController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Issue submitted successfully!\n'
          'Driver: $driverName\n'
          'Phone: $phone\n'
          'Issue: $issue',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report Collection Issue',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              // DRIVER NAME
              TextFormField(
                controller: driverNameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  hintText: 'Enter driver name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the driver name';
                  }

                  if (value.trim().length < 2) {
                    return 'Driver name must be at least 2 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // PHONE NUMBER
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter 10-digit contact number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the phone number';
                  }

                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                    return 'Enter a valid 10-digit phone number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ISSUE DESCRIPTION
              TextFormField(
                controller: issueController,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Issue Description',
                  hintText: 'Describe the route or vehicle issue',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.report_problem),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue';
                  }

                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: submitIssue,
                icon: const Icon(Icons.send),
                label: const Text('Submit Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
