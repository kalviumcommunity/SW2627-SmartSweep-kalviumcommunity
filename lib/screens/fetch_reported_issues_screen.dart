import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class FetchReportedIssuesScreen extends StatefulWidget {
  const FetchReportedIssuesScreen({super.key});

  @override
  State<FetchReportedIssuesScreen> createState() =>
      _FetchReportedIssuesScreenState();
}

class _FetchReportedIssuesScreenState
    extends State<FetchReportedIssuesScreen> {
  final FirestoreService _firestoreService =
      FirestoreService();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  @override
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
  // DELETE ISSUE
  // --------------------------------------------------

  Future<void> _deleteIssue(
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

    if (shouldDelete != true) {
      return;
    }

    try {
      await _firestoreService
          .deleteReportedIssue(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Issue deleted successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete the issue.',
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reported Issues',
        ),
      ),
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
      ),
    );
  }
}