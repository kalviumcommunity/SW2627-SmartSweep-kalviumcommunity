import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
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
    final String driverName = driverNameController.text.trim();
    final String phone = phoneController.text.trim();
    final String issue = issueController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Driver: $driverName\nPhone: $phone\nIssue: $issue',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Report Collection Issue',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: driverNameController,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(
                labelText: 'Driver Name',
                hintText: 'Enter driver name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter contact number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
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
    );
  }
}