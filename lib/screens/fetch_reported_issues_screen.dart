import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/reported_issue_image.dart';

class FetchReportedIssuesScreen extends StatefulWidget {
  const FetchReportedIssuesScreen({super.key});

  @override
  State<FetchReportedIssuesScreen> createState() =>
      _FetchReportedIssuesScreenState();
}

class _FetchReportedIssuesScreenState extends State<FetchReportedIssuesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> _issuesFuture;
  final Set<String> _deletingIssueIds = <String>{};

  @override
  void initState() {
    super.initState();
    _issuesFuture = _firestoreService.fetchReportedIssues();
  }

  void _retry() {
    setState(() {
      _issuesFuture = _firestoreService.fetchReportedIssues();
    });
  }

  Future<void> _deleteIssue(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete reported issue?'),
        content: const Text('This issue will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _deletingIssueIds.contains(id)) return;

    setState(() => _deletingIssueIds.add(id));
    try {
      await _firestoreService.deleteReportedIssue(id);
      if (!mounted) return;

      setState(() {
        _deletingIssueIds.remove(id);
        _issuesFuture = _firestoreService.fetchReportedIssues();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reported issue deleted.')));
    } catch (_) {
      if (!mounted) return;

      setState(() => _deletingIssueIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete reported issue. Please try again.'),
        ),
      );
    }
  }

  DateTime? _createdAt(Map<String, dynamic> issue) {
    final value = issue['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _fieldText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Widget _buildIssueCard(BuildContext context, Map<String, dynamic> issue) {
    final issueId = issue['id']?.toString() ?? '';
    final isDeleting = _deletingIssueIds.contains(issueId);
    final isUrgent = issue['isUrgent'] == true;
    final createdAt = _createdAt(issue)?.toLocal();
    final createdAtText = createdAt == null
        ? 'Not available'
        : '${MaterialLocalizations.of(context).formatMediumDate(createdAt)} '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(createdAt))}';

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.report_outlined,
              color: isUrgent
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              _fieldText(issue['driverName'], 'Unknown driver'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone: ${_fieldText(issue['phoneNumber'], 'Not provided')}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issue: ${_fieldText(issue['issueDescription'], 'No description provided')}',
                  ),
                  const SizedBox(height: 4),
                  Text('Urgency: ${isUrgent ? 'Urgent' : 'Not urgent'}'),
                  const SizedBox(height: 4),
                  Text('Created: $createdAtText'),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Delete reported issue',
              onPressed: issueId.isEmpty || isDeleting
                  ? null
                  : () => _deleteIssue(issueId),
              icon: isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
          ),
          if (issue['imageUrl'] is String &&
              (issue['imageUrl'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ReportedIssueImage(imageUrl: issue['imageUrl'] as String),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reported Issues')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _issuesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load reported issues. Check your connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final issues = snapshot.data ?? const <Map<String, dynamic>>[];
          if (issues.isEmpty) {
            return const Center(child: Text('No reported issues yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildIssueCard(context, issues[index]),
          );
        },
      ),
    );
  }
}
