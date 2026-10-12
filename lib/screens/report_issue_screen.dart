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

  // State variable for this assignment
  bool _isUrgent = false;

  @override
  void dispose() {
    driverNameController.dispose();
    phoneController.dispose();
    issueController.dispose();
    super.dispose();
  }

  void submitIssue() {
    if (_formKey.currentState!.validate()) {
      final String driverName = driverNameController.text.trim();
      final String phone = phoneController.text.trim();
      final String issue = issueController.text.trim();

      final String priority = _isUrgent ? 'Urgent' : 'Normal';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Driver: $driverName\n'
            'Phone: $phone\n'
            'Issue: $issue\n'
            'Priority: $priority',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
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

              TextFormField(
                controller: driverNameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  hintText: 'Enter driver name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter driver name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter contact number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: issueController,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Issue Description',
                  hintText: 'Describe the route or vehicle issue',
                  prefixIcon: Icon(Icons.report_problem),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Stateful feature for this assignment
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Urgent Issue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _isUrgent ? 'Urgent Priority' : 'Normal Priority',
                ),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isUrgent
                          ? Icons.warning_amber
                          : Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isUrgent
                            ? 'Status: This issue requires urgent attention.'
                            : 'Status: This issue has normal priority.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
      ),
    );
  }
}