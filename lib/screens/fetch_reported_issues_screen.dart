import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class FetchReportedIssuesScreen extends StatefulWidget {
  const FetchReportedIssuesScreen({super.key});

  @override
  State<FetchReportedIssuesScreen> createState() =>
      _FetchReportedIssuesScreenState();
}

class _FetchReportedIssuesScreenState
    extends State<FetchReportedIssuesScreen> 
  final FirestoreService _firestoreService =
      FirestoreService();

<<<<<<< HEAD
  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';
=======
  late Future<List<Map<String, dynamic>>> _issuesFuture;

  final Set<String> _deletingIssueIds = <String>{};
>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';
  String _urgencyFilter = 'all';

  @override
<<<<<<< HEAD
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // SEARCH MATCHING
  // --------------------------------------------------

  bool _matchesSearch(
    Map<String, dynamic> issue,
  ) {
    if (_searchText.isEmpty) {
      return true;
    }

    final driverName =
        issue['driverName']
            ?.toString()
            .toLowerCase() ??
        '';

    final phoneNumber =
        issue['phoneNumber']
            ?.toString()
            .toLowerCase() ??
        '';

    final description =
        issue['issueDescription']
            ?.toString()
            .toLowerCase() ??
        '';

    final isUrgent =
        issue['isUrgent'] == true;

    final urgency =
        isUrgent ? 'urgent' : 'normal';

    return driverName.contains(_searchText) ||
        phoneNumber.contains(_searchText) ||
        description.contains(_searchText) ||
        urgency.contains(_searchText);
  }

  // --------------------------------------------------
=======
  void initState() {
    super.initState();

    _issuesFuture =
        _firestoreService.fetchReportedIssues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // RETRY FIRESTORE FETCH
  // --------------------------------------------------

  void _retry() {
    setState(() {
      _issuesFuture =
          _firestoreService.fetchReportedIssues();
    });
  }

  // --------------------------------------------------
  // LIVE SEARCH
  // --------------------------------------------------

  bool _matchesSearch(
    Map<String, dynamic> issue,
  ) {
    if (_searchText.isEmpty) {
      return true;
    }

    final driverName =
        issue['driverName']
            ?.toString()
            .toLowerCase() ??
        '';

    final phoneNumber =
        issue['phoneNumber']
            ?.toString()
            .toLowerCase() ??
        '';

    final issueDescription =
        issue['issueDescription']
            ?.toString()
            .toLowerCase() ??
        '';

    final urgency =
        issue['isUrgent'] == true
            ? 'urgent'
            : 'normal';

    return driverName.contains(_searchText) ||
        phoneNumber.contains(_searchText) ||
        issueDescription.contains(_searchText) ||
        urgency.contains(_searchText);
  }

  // --------------------------------------------------
  // URGENCY FILTER
  // --------------------------------------------------

  bool _matchesUrgency(
    Map<String, dynamic> issue,
  ) {
    if (_urgencyFilter == 'all') {
      return true;
    }

    final isUrgent =
        issue['isUrgent'] == true;

    if (_urgencyFilter == 'urgent') {
      return isUrgent;
    }

    if (_urgencyFilter == 'normal') {
      return !isUrgent;
    }

    return true;
  }

  // --------------------------------------------------
>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e
  // DELETE ISSUE
  // --------------------------------------------------

  Future<void> _deleteIssue(
<<<<<<< HEAD
    Map<String, dynamic> issue,
  ) async {
    final id = issue['id']?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Issue',
          ),
          content: const Text(
            'Are you sure you want to delete this reported issue?',
=======
    String id,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete issue?'),
        content: const Text(
          'Are you sure you want to delete this issue? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text(
              'Cancel',
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text(
              'Delete',
            ),
>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

<<<<<<< HEAD
    if (shouldDelete != true) {
      return;
    }

=======
    if (!mounted ||
        confirmed != true ||
        _deletingIssueIds.contains(id)) {
      return;
    }

    setState(
      () => _deletingIssueIds.add(id),
    );

>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e
    try {
      await _firestoreService
          .deleteReportedIssue(id);

      if (!mounted) return;

<<<<<<< HEAD
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Issue deleted successfully.',
          ),
        ),
=======
      setState(() {
        _deletingIssueIds.remove(id);

        _issuesFuture =
            _firestoreService
                .fetchReportedIssues();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reported issue deleted.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() => _deletingIssueIds.remove(id));
      final message = switch (error.code) {
        'permission-denied' => 'You do not have permission to delete this issue.',
        'unavailable' => 'No connection. Check your network and try again.',
        _ => 'Could not delete the issue. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e
      );
    } catch (_) {
      if (!mounted) return;

<<<<<<< HEAD
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete the issue.',
          ),
        ),
=======
      setState(() => _deletingIssueIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the issue. Please try again.')),
>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e
      );
    }
  }

  // --------------------------------------------------
<<<<<<< HEAD
  // UI
  // --------------------------------------------------
=======
  // CREATED AT
  // --------------------------------------------------

  DateTime? _createdAt(
    Map<String, dynamic> issue,
  ) {
    final value = issue['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // --------------------------------------------------
  // FIELD TEXT HELPER
  // --------------------------------------------------

  String _fieldText(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    final text =
        value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }

  // --------------------------------------------------
  // ISSUE CARD
  // --------------------------------------------------

  Widget _buildIssueCard(
    BuildContext context,
    Map<String, dynamic> issue,
  ) {
    final issueId =
        issue['id']?.toString() ?? '';

    final isDeleting =
        _deletingIssueIds
            .contains(issueId);

    final isUrgent =
        issue['isUrgent'] == true;

    final createdAt =
        _createdAt(issue)?.toLocal();

    final createdAtText =
        createdAt == null
            ? 'Not available'
            : '${MaterialLocalizations.of(context).formatMediumDate(createdAt)} '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(createdAt))}';

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.all(16),

            leading: Icon(
              isUrgent
                  ? Icons.warning_amber_rounded
                  : Icons.report_outlined,
              color: isUrgent
                  ? Colors.red
                  : Theme.of(context)
                      .colorScheme
                      .primary,
            ),

            title: Text(
              _fieldText(
                issue['driverName'],
                'Unknown driver',
              ),
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            subtitle: Padding(
              padding:
                  const EdgeInsets.only(
                top: 8,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone: ${_fieldText(issue['phoneNumber'], 'Not provided')}',
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Issue: ${_fieldText(issue['issueDescription'], 'No description provided')}',
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Urgency: ${isUrgent ? 'Urgent' : 'Not urgent'}',
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Created: $createdAtText',
                  ),
                ],
              ),
            ),

            isThreeLine: true,

            trailing: IconButton(
              tooltip:
                  'Delete reported issue',
              onPressed:
                  issueId.isEmpty ||
                          isDeleting
                      ? null
                      : () =>
                          _deleteIssue(
                            issueId,
                          ),
              icon: isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline,
                    ),
            ),
          ),

          if (issue['imageUrl']
                  is String &&
              (issue['imageUrl']
                      as String)
                  .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              child:
                  ReportedIssueImage(
                imageUrl:
                    issue['imageUrl']
                        as String,
              ),
            ),
        ],
      ),
    );
  }
>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e

  // --------------------------------------------------
  // SCREEN
  // --------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reported Issues',
        ),
      ),
<<<<<<< HEAD
      body: Column(
        children: [
          // ------------------------------------------------
          // SEARCH FIELD
          // ------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.all(16),
            child: TextField(
              controller:
                  _searchController,
              decoration:
                  InputDecoration(
                labelText:
                    'Search reported issues',
                hintText:
                    'Search by driver, phone or issue',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _searchText.isEmpty
                        ? null
                        : IconButton(
                            tooltip:
                                'Clear Search',
                            icon:
                                const Icon(
                              Icons.clear,
                            ),
                            onPressed:
                                () {
                              _searchController
                                  .clear();

                              setState(
                                () {
                                  _searchText =
                                      '';
                                },
                              );
                            },
                          ),
                border:
                    const OutlineInputBorder(),
              ),

              // Search updates on every character.
              onChanged: (value) {
                setState(() {
                  _searchText =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
            ),
          ),

          // ------------------------------------------------
          // FIRESTORE STREAM
          // ------------------------------------------------

          Expanded(
            child: StreamBuilder<
                List<
                    Map<String,
                        dynamic>>>(
              stream:
                  _firestoreService
                      .streamReportedIssues(),
              builder:
                  (context, snapshot) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(
                        24,
                      ),
                      child: Text(
                        'Unable to load reported issues.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  );
                }

                final allIssues =
                    snapshot.data ?? [];

                // No Firestore data at all.
                if (allIssues.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .inbox_outlined,
                          size: 70,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                          'No reported issues found.',
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ------------------------------------------------
                // LIVE FILTER
                // ------------------------------------------------

                final filteredIssues =
                    allIssues
                        .where(
                          _matchesSearch,
                        )
                        .toList();

                // Search exists but nothing matches.
                if (filteredIssues
                    .isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(24),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Icon(
                            Icons
                                .search_off,
                            size: 70,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          const Text(
                            'No matches found',
                            style:
                                TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            'No reported issues match "${_searchController.text}".',
                            textAlign:
                                TextAlign
                                    .center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ------------------------------------------------
                // MATCHING RESULTS
                // ------------------------------------------------

                return Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${filteredIssues.length} result${filteredIssues.length == 1 ? '' : 's'}',
                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade700,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Expanded(
                      child:
                          ListView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        itemCount:
                            filteredIssues
                                .length,
                        itemBuilder:
                            (context,
                                index) {
                          final issue =
                              filteredIssues[
                                  index];

                          final driverName =
                              issue['driverName']
                                      ?.toString() ??
                                  'Unknown Driver';

                          final phoneNumber =
                              issue['phoneNumber']
                                      ?.toString() ??
                                  'No phone number';

                          final description =
                              issue['issueDescription']
                                      ?.toString() ??
                                  'No description';

                          final isUrgent =
                              issue['isUrgent'] ==
                                  true;

                          return Card(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                ListTile(
                              leading:
                                  CircleAvatar(
                                child: Icon(
                                  isUrgent
                                      ? Icons
                                          .warning_amber
                                      : Icons
                                          .check_circle_outline,
                                ),
                              ),
                              title: Text(
                                driverName,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              subtitle:
                                  Text(
                                '$description\n'
                                'Phone: $phoneNumber',
                              ),
                              isThreeLine:
                                  true,
                              trailing:
                                  PopupMenuButton<
                                      String>(
                                onSelected:
                                    (value) {
                                  if (value ==
                                      'delete') {
                                    _deleteIssue(
                                      issue,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (context) =>
                                        const [
                                  PopupMenuItem(
                                    value:
                                        'delete',
                                    child:
                                        Text(
                                      'Delete',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
=======

      body: FutureBuilder<
          List<Map<String, dynamic>>>(
        future: _issuesFuture,

        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load reported issues. Check your connection and try again.',
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label:
                          const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final issues =
              snapshot.data ??
                  const <
                      Map<String,
                          dynamic>>[];

          if (issues.isEmpty) {
            return const Center(
              child: Text(
                'No reported issues yet.',
              ),
            );
          }

          // --------------------------------------------
          // SEARCH + FILTER RESULTS
          // --------------------------------------------

          final filteredIssues =
              issues.where((issue) {
            return _matchesSearch(issue) &&
                _matchesUrgency(issue);
          }).toList();

          return Column(
            children: [
              // ----------------------------------------
              // SEARCH FIELD
              // ----------------------------------------

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: TextField(
                  controller:
                      _searchController,

                  decoration:
                      InputDecoration(
                    labelText:
                        'Search reported issues',

                    hintText:
                        'Driver, phone, issue or urgency',

                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),

                    suffixIcon:
                        _searchText.isEmpty
                            ? null
                            : IconButton(
                                tooltip:
                                    'Clear search',
                                icon:
                                    const Icon(
                                  Icons.clear,
                                ),
                                onPressed:
                                    () {
                                  _searchController
                                      .clear();

                                  setState(
                                    () {
                                      _searchText =
                                          '';
                                    },
                                  );
                                },
                              ),

                    border:
                        const OutlineInputBorder(),
                  ),

                  onChanged: (value) {
                    setState(() {
                      _searchText =
                          value
                              .trim()
                              .toLowerCase();
                    });
                  },
                ),
              ),

              // ----------------------------------------
              // URGENCY FILTER
              // ----------------------------------------

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label:
                            const Text(
                          'All',
                        ),
                        selected:
                            _urgencyFilter ==
                                'all',
                        onSelected: (_) {
                          setState(() {
                            _urgencyFilter =
                                'all';
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: ChoiceChip(
                        label:
                            const Text(
                          'Urgent',
                        ),
                        selected:
                            _urgencyFilter ==
                                'urgent',
                        onSelected: (_) {
                          setState(() {
                            _urgencyFilter =
                                'urgent';
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: ChoiceChip(
                        label:
                            const Text(
                          'Normal',
                        ),
                        selected:
                            _urgencyFilter ==
                                'normal',
                        onSelected: (_) {
                          setState(() {
                            _urgencyFilter =
                                'normal';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ----------------------------------------
              // RESULT COUNT
              // ----------------------------------------

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    '${filteredIssues.length} result${filteredIssues.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors
                          .grey
                          .shade700,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ----------------------------------------
              // NO MATCHES
              // ----------------------------------------

              if (filteredIssues.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          const Text(
                            'No matches found',
                            style:
                                TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            _searchController
                                    .text
                                    .isEmpty
                                ? 'No issues match the selected filter.'
                                : 'No reported issues match "${_searchController.text}".',
                            textAlign:
                                TextAlign
                                    .center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // ----------------------------------------
              // FILTERED LIST
              // ----------------------------------------

              else
                Expanded(
                  child:
                      ListView.separated(
                    padding:
                        const EdgeInsets
                            .all(16),

                    itemCount:
                        filteredIssues
                            .length,

                    separatorBuilder:
                        (
                      context,
                      index,
                    ) =>
                            const SizedBox(
                      height: 12,
                    ),

                    itemBuilder:
                        (
                      context,
                      index,
                    ) =>
                            _buildIssueCard(
                      context,
                      filteredIssues[
                          index],
                    ),
                  ),
                ),
            ],
          );
        },
>>>>>>> 1bb40b734af6b7db1b1571bb366651ed7f4b039e
      ),
    );
  }
}