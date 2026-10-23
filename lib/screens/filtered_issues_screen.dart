import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class FilteredIssuesScreen extends StatefulWidget {
  const FilteredIssuesScreen({super.key});

  @override
  State<FilteredIssuesScreen> createState() =>
      _FilteredIssuesScreenState();
}

class _FilteredIssuesScreenState
    extends State<FilteredIssuesScreen> {
  final FirestoreService _firestoreService =
      FirestoreService();

  bool _showUrgent = true;
  bool _isLoading = false;

  String? _errorMessage;

  List<Map<String, dynamic>> _issues = [];

  @override
  void initState() {
    super.initState();
    _loadFilteredIssues();
  }

  Future<void> _loadFilteredIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results =
          await _firestoreService.getReportedIssuesByUrgency(
        isUrgent: _showUrgent,
      );

      if (!mounted) return;

      setState(() {
        _issues = results;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _issues = [];
        _errorMessage =
            'Unable to load filtered issues. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeFilter(bool urgent) {
    if (_showUrgent == urgent) {
      return;
    }

    setState(() {
      _showUrgent = urgent;
    });

    _loadFilteredIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Filtered Firestore Issues',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFilteredIssues,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Firestore Query',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Only records matching the selected urgency '
              'condition are retrieved from Firestore.',
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text(
                      'Urgent Issues',
                    ),
                    selected: _showUrgent,
                    onSelected: (_) {
                      _changeFilter(true);
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ChoiceChip(
                    label: const Text(
                      'Normal Issues',
                    ),
                    selected: !_showUrgent,
                    onSelected: (_) {
                      _changeFilter(false);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              _showUrgent
                  ? 'Urgent Issues'
                  : 'Normal Issues',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 50,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadFilteredIssues,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_issues.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 60,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _showUrgent
                            ? 'No urgent issues found.'
                            : 'No normal issues found.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'No Firestore documents match '
                        'the selected condition.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._issues.map(
                (issue) {
                  final driverName =
                      issue['driverName']?.toString() ??
                          'Unknown Driver';

                  final phoneNumber =
                      issue['phoneNumber']?.toString() ??
                          'No phone number';

                  final description =
                      issue['issueDescription']
                              ?.toString() ??
                          'No description';

                  final urgent =
                      issue['isUrgent'] == true;

                  return Card(
                    margin:
                        const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          urgent
                              ? Icons.warning_amber
                              : Icons.check_circle_outline,
                        ),
                      ),
                      title: Text(
                        driverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '$description\n'
                        'Phone: $phoneNumber',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        urgent
                            ? 'Urgent'
                            : 'Normal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: urgent
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _loadFilteredIssues,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Refresh Query',
              ),
            ),
          ],
        ),
      ),
    );
  }
}