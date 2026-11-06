import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/status_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/status_chip.dart';
import 'api.dart';

/// Operational screens backed exclusively by persisted API records.
class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key, this.api});
  final OperationsApi? api;

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  late final OperationsApi api = widget.api ?? OperationsApi();
  final email = TextEditingController();
  final password = TextEditingController();
  Map<String, dynamic>? data;
  Timer? timer;
  String? error;
  bool busy = false;
  bool refreshing = false;
  bool obscurePassword = true;
  int tab = 0;
  int days = 30;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    email.dispose();
    password.dispose();
    if (widget.api == null) {
      api.close();
    }
    super.dispose();
  }

  Future<void> refresh() async {
    if (api.token == null || refreshing) {
      return;
    }
    refreshing = true;
    try {
      final result = await api.request('state?days=$days');
      if (mounted) {
        setState(() {
          data = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          if (api.token == null) {
            data = null;
          }
        });
      }
    } finally {
      refreshing = false;
    }
  }

  Future<void> run(Future<void> Function() operation) async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await operation();
      await refresh();
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  List<Map<String, dynamic>> rows(String key) =>
      (data?[key] as List? ?? []).cast<Map<String, dynamic>>();

  bool get supervisor => data?['user']?['role'] == 'supervisor';

  String date(dynamic value) {
    if (value == null) {
      return '—';
    }
    return DateTime.fromMillisecondsSinceEpoch((value as num).round() * 1000)
        .toLocal()
        .toString()
        .split('.')
        .first;
  }

  Future<void> action(String name, int id) async {
    final fields = <String, String>{
      if (name == 'collect') 'stop': 'Stop number',
      if (['collect', 'verify', 'breakdown', 'repair'].contains(name))
        'evidence': 'Evidence / incident details / review notes',
      if (name == 'resolve') 'resolution': 'Response and follow-up',
    };
    final result = await input(name, fields);
    if (result == null) {
      return;
    }
    if (result.containsKey('stop')) {
      result['stop'] = int.tryParse(result['stop']?.toString() ?? '');
    }
    await run(() async {
      await api.request(name, {'id': id, 'route_id': id, ...result});
    });
  }

  IconData _iconForAction(String action) {
    switch (action) {
      case 'start':
        return Icons.play_arrow_rounded;
      case 'collect':
        return Icons.add_task_rounded;
      case 'claim':
        return Icons.assignment_turned_in_rounded;
      case 'verify':
        return Icons.verified_user_rounded;
      case 'breakdown':
        return Icons.car_crash_rounded;
      case 'repair':
        return Icons.build_circle_rounded;
      case 'resolve':
        return Icons.check_circle_outline_rounded;
      case 'zones':
        return Icons.add_location_alt_rounded;
      case 'vehicles':
        return Icons.local_shipping_rounded;
      case 'drivers':
        return Icons.person_add_rounded;
      case 'routes':
        return Icons.alt_route_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  Future<Map<String, dynamic>?> input(
    String title,
    Map<String, String> fields, {
    Map<String, List<Map<String, dynamic>>> choices = const {},
  }) async {
    final controllers = {
      for (final key in fields.keys) key: TextEditingController()
    };
    final selections = <String, int?>{
      for (final key in choices.keys)
        key: choices[key]!.isEmpty ? null : choices[key]!.first['id'] as int
    };
    final form = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.outline, width: 1.4),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Icon(_iconForAction(title), color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Record: ${StatusColors.label(title)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title == 'verify')
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.security_rounded, color: Color(0xFF16A34A), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A separate supervisor must review collection records before verifying. This records formal supervisory audit.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF15803D), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final field in fields.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextFormField(
                        controller: controllers[field.key],
                        obscureText: field.key == 'password',
                        maxLines: field.key == 'evidence' || field.key == 'resolution' ? 3 : 1,
                        decoration: InputDecoration(
                          labelText: field.value,
                          hintText: field.key == 'stop' ? 'e.g. 1' : null,
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required field' : null,
                      ),
                    ),
                  for (final choice in choices.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DropdownButtonFormField<int>(
                        initialValue: selections[choice.key],
                        decoration: InputDecoration(
                          labelText: StatusColors.label(choice.key.replaceAll('_id', '')),
                        ),
                        items: choice.value
                            .map((v) => DropdownMenuItem<int>(
                                  value: v['id'] as int,
                                  child: Text(v['name'] as String),
                                ))
                            .toList(),
                        onChanged: (v) => selections[choice.key] = v,
                        validator: (v) =>
                            v == null ? 'Selection required' : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save record'),
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(
                  context,
                  <String, dynamic>{
                    for (final e in controllers.entries) e.key: e.value.text.trim(),
                    ...selections,
                  },
                );
              }
            },
          ),
        ],
      ),
    );

    // Wait for the dialog transition before disposing
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final c in controllers.values) {
      c.dispose();
    }
    return result;
  }

  Widget command(String label, String actionName, int id, {Color? color}) {
    final effectiveColor = color ?? AppTheme.primary;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveColor,
        side: BorderSide(color: effectiveColor, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: busy ? null : () => action(actionName, id),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForAction(actionName), size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> r) {
    final status = r['status']?.toString() ?? 'scheduled';
    final progress = (r['progress'] as num? ?? 0) / (r['stops'] as num? ?? 1);
    final borderColor = StatusColors.of(status);
    final isVerified = r['verified'] != null;
    final collections = rows('collections').where((c) => c['route_id'] == r['id']).toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isVerified
              ? const Color(0xFF86EFAC)
              : borderColor.withAlpha(120),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Route name, ID, status chip, demo tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              r['name'] ?? 'Route',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF132B22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.outlineVariant,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Text(
                              '#${r['id']}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B6056)),
                            ),
                          ),
                          if (r['demo'] == 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFCD34D)),
                              ),
                              child: const Text(
                                'DEMO',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                StatusChip(status),
              ],
            ),
            const SizedBox(height: 12),

            // Metadata pills with borders
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoPill(Icons.map_outlined, 'Zone', r['zone']?.toString() ?? '—'),
                _buildInfoPill(Icons.local_shipping_outlined, 'Vehicle', r['vehicle']?.toString() ?? '—'),
                _buildInfoPill(Icons.group_outlined, 'Driver', r['driver']?.toString() ?? '—'),
              ],
            ),
            const SizedBox(height: 12),

            // Schedule box with border
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF476355)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Starts ${date(r['starts'])}  •  Deadline ${date(r['deadline'])}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334B3F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${r['progress']}/${r['stops']} stops reported (${(progress.clamp(0.0, 1.0) * 100).toInt()}%)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A2E)),
                ),
                if (isVerified)
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        'Verified ${date(r['verified'])}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFE2EBE5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isVerified ? const Color(0xFF16A34A) : AppTheme.primary,
                ),
              ),
            ),

            // Collection reports list
            if (collections.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collection Stop Logs:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF436052)),
                    ),
                    const SizedBox(height: 4),
                    for (final c in collections)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Stop ${c['stop']}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${c['evidence'] ?? 'Reported'} (by operator #${c['actor']})',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF2E483C)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Contextual Actions
            if (r['verified'] == null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (r['started'] == null && (data!['now'] as num) >= (r['starts'] as num))
                    command('Start route', 'start', r['id'], color: const Color(0xFF0F8A5F)),
                  if (r['started'] != null && r['interrupted'] == 0 && r['claimed'] == null)
                    command('Record collection', 'collect', r['id'], color: const Color(0xFF0284C7)),
                  if (r['progress'] == r['stops'] && r['claimed'] == null && r['interrupted'] == 0)
                    command('Claim completion', 'claim', r['id'], color: const Color(0xFF7C3AED)),
                  if (supervisor && r['claimed'] != null && r['interrupted'] == 0)
                    command('Review & verify', 'verify', r['id'], color: const Color(0xFF0F5132)),
                  if (r['started'] != null && r['interrupted'] == 0)
                    command('Report breakdown', 'breakdown', r['id'], color: const Color(0xFFDC2626)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B6056)),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF637B70)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2F)),
          ),
        ],
      ),
    );
  }

  Future<void> create(String kind, Map<String, String> fields) async {
    final result = await input(
      'Create $kind',
      fields,
      choices: kind == 'routes'
          ? {
              'zone_id': rows('zones').where((z) => z['active'] == 1).toList(),
              'vehicle_id': rows('vehicles').where((v) => v['available'] == 1).toList(),
              'driver_id': rows('drivers'),
            }
          : const {},
    );
    if (result == null) {
      return;
    }
    await run(() async {
      if (kind == 'routes') {
        result['stops'] = int.tryParse(result['stops']?.toString() ?? '');
        for (final key in ['starts', 'deadline']) {
          final parsed = DateTime.tryParse(result[key]?.toString() ?? '');
          if (parsed == null) {
            throw const FormatException('Use date/time YYYY-MM-DD HH:MM');
          }
          result[key] = parsed.millisecondsSinceEpoch ~/ 1000;
        }
      }
      await api.request(kind, result);
    });
  }

  List<Widget> content() {
    if (tab == 0) {
      return [
        _buildNoticeBanner(
          Icons.verified_user_outlined,
          'Route Monitoring Policy',
          'Collection stop logs are driver field reports. Formal route completion requires independent review and verification by a separate supervisor.',
          const Color(0xFFE8F5EE),
          AppTheme.primary,
        ),
        const SizedBox(height: 12),
        for (final r in rows('routes')) _buildRouteCard(r),
        if (rows('routes').isEmpty)
          _buildEmptyState(
            Icons.route_outlined,
            'No routes scheduled yet',
            'Use the "Zones & fleet" tab to schedule new collection occurrences.',
          ),
      ];
    }
    if (tab == 1) {
      return [
        _buildNoticeBanner(
          Icons.notifications_active_outlined,
          'Incident Handling Policy',
          'Resolving an alert records administrative remediation. It documents the response without erasing past misses or replacing collection verification.',
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
        ),
        const SizedBox(height: 12),
        for (final i in rows('incidents'))
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: i['resolved'] == null
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFF86EFAC),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: i['resolved'] == null
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          i['resolved'] == null
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: i['resolved'] == null
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${StatusColors.label(i['kind']?.toString() ?? 'Alert')} • Route #${i['route_id']}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            Text(
                              date(i['occurred']),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(i['resolved'] == null ? 'unresolved' : 'resolved'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    i['detail'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937), height: 1.4),
                  ),
                  if (i['resolution'] != null && (i['resolution'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Remediation: ${i['resolution']}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (supervisor && i['resolved'] == null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: command('Respond & resolve', 'resolve', i['id'], color: AppTheme.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (rows('incidents').isEmpty)
          _buildEmptyState(
            Icons.verified_outlined,
            'No operational alerts',
            'All collection routes and vehicles are operating within target parameters.',
          ),
      ];
    }
    if (tab == 2) {
      return [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.outline, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recurrence Threshold Detection',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Flags zones exceeding ${data!['recurrence']} misses within the selected observation window.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B6056)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F7F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: DropdownButton<int>(
                    value: days,
                    underline: const SizedBox.shrink(),
                    items: [7, 30, 90, 365]
                        .map((v) => DropdownMenuItem(value: v, child: Text('$v days')))
                        .toList(),
                    onChanged: (v) {
                      setState(() => days = v!);
                      refresh();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final a in rows('analytics'))
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: a['recurring'] == true
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF86EFAC),
                width: a['recurring'] == true ? 2.0 : 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            a['recurring'] == true
                                ? Icons.warning_rounded
                                : Icons.check_circle_rounded,
                            color: a['recurring'] == true
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            a['zone'] ?? 'Zone',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: a['recurring'] == true
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: a['recurring'] == true
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Text(
                          a['recurring'] == true
                              ? 'RECURRING MISSES'
                              : 'ON TARGET',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: a['recurring'] == true
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricTile(
                        'Total Misses',
                        '${a['misses']}',
                        a['recurring'] == true ? const Color(0xFFDC2626) : const Color(0xFF1E3A2F),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricTile('Scheduled Due', '${a['scheduled']}', const Color(0xFF1E3A2F)),
                      const SizedBox(width: 12),
                      _buildMetricTile('Recent 7 Days', '${a['recent_7_days']}', const Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      _buildMetricTile('Preceding 7 Days', '${a['previous_7_days']}', const Color(0xFF4B6056)),
                    ],
                  ),
                  if (a['route_ids'] != null && (a['route_ids'] as List).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Affected route records: ${a['route_ids']}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Operational Event Log',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF132B22)),
        ),
        const SizedBox(height: 8),
        for (final e in rows('events'))
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${StatusColors.label(e['kind']?.toString() ?? 'Event')} • Route #${e['route_id']}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            date(e['occurred']),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e['detail'] ?? ''} (${e['actor_email'] ?? 'Automatic detector'})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ];
    }
    return [
      // Tab 3: Zones & Fleet
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.outline, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_city_rounded, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Service Zones', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              for (final z in rows('zones'))
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(z['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '${z['schedule']}  •  ${z['active'] == 1 ? 'Active' : 'Inactive'}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5A6E63)),
                          ),
                        ],
                      ),
                      if (supervisor)
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => run(() async {
                                    await api.request(
                                      'zone-active',
                                      {'id': z['id'], 'active': z['active'] == 1 ? 0 : 1},
                                    );
                                  }),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: Text(z['active'] == 1 ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.outline, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_rounded, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Fleet Vehicles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              for (final v in rows('vehicles'))
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: v['available'] == 1
                          ? AppTheme.outlineVariant
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fire_truck_rounded,
                            color: v['available'] == 1
                                ? AppTheme.primary
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                v['available'] == 1 ? 'Available for service' : 'Vehicle broken down',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: v['available'] == 1
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (supervisor && v['available'] == 0)
                        command('Record repair', 'repair', v['id'], color: const Color(0xFF16A34A)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.outline, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_rounded, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Collection Teams', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              for (final d in rows('drivers'))
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.person, size: 16, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      Text('Team #${d['id']}', style: const TextStyle(fontSize: 12, color: Color(0xFF5A6E63))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      if (supervisor) ...[
        const SizedBox(height: 14),
        const Text(
          'Fleet & Route Provisioning',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF132B22)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: const Text('Create zone'),
              onPressed: busy
                  ? null
                  : () => create('zones', {
                        'name': 'Zone name',
                        'schedule': 'Schedule description (e.g. Daily 07:00–09:00)',
                      }),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.local_shipping_rounded, size: 16),
              label: const Text('Add vehicle'),
              onPressed: busy ? null : () => create('vehicles', {'name': 'Vehicle name'}),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Add driver'),
              onPressed: busy
                  ? null
                  : () => create('drivers', {
                        'name': 'Team name',
                        'email': 'Email address',
                        'password': 'Password (12+ characters)',
                      }),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.alt_route_rounded, size: 16),
              label: const Text('Schedule route'),
              onPressed: busy
                  ? null
                  : () => create('routes', {
                        'name': 'Route name',
                        'starts': 'Start: YYYY-MM-DD HH:MM',
                        'deadline': 'Deadline: YYYY-MM-DD HH:MM',
                        'stops': 'Number of stops (1–100)',
                      }),
            ),
          ],
        ),
      ],
    ];
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBanner(IconData icon, String title, String body, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withAlpha(120), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: border),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E35), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildSignInView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppTheme.outline, width: 1.4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Brand Icon
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D5238), Color(0xFF198754)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D5238).withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 38),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'SMARTSWEEP',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Waste Operations Portal',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF132B22)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Real-time route monitoring, breakdown tracking, and recurring failure analytics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF5A6E63), height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email input
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: 'Operator Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Password input
                  TextField(
                    controller: password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    obscureText: obscurePassword,
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error!,
                              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Sign in to Operations',
                    icon: Icons.login_rounded,
                    loading: busy,
                    fullWidth: true,
                    onPressed: () => run(() async {
                      await api.login(email.text.trim(), password.text);
                      password.clear();
                    }),
                  ),

                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'QUICK DEMO CREDENTIALS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7B8D83)),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Demo Accounts
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.security_rounded, size: 15),
                          label: const Text('Supervisor', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              email.text = 'supervisor@smartsweep.local';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.local_shipping_rounded, size: 15),
                          label: const Text('Driver Team', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              email.text = 'driver@smartsweep.local';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to auto-fill email. Enter password created during local setup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF7B8D83)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('SmartSweep Operations'),
          ],
        ),
        actions: [
          if (data != null) ...[
            IconButton(
              tooltip: 'Refresh operational status',
              onPressed: refreshing ? null : refresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Log out',
              onPressed: busy
                  ? null
                  : () => run(() async {
                        await api.request('logout', {});
                        api.token = null;
                        if (mounted) {
                          setState(() => data = null);
                        }
                      }),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ],
      ),
      body: data == null
          ? _buildSignInView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outline, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: supervisor
                                ? const Color(0xFF0F5132).withAlpha(30)
                                : const Color(0xFF0284C7).withAlpha(30),
                            radius: 18,
                            child: Icon(
                              supervisor ? Icons.verified_user_rounded : Icons.local_shipping_rounded,
                              size: 18,
                              color: supervisor ? const Color(0xFF0F5132) : const Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data!['user']?['email'] ?? 'User',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: supervisor
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: supervisor
                                              ? const Color(0xFF86EFAC)
                                              : const Color(0xFFBAE6FD),
                                        ),
                                      ),
                                      child: Text(
                                        supervisor ? 'SUPERVISOR' : 'COLLECTION DRIVER',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: supervisor
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF0369A1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  Clock: ${date(data!['now'])}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (supervisor && data!['demo'] == true)
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.fast_forward_rounded, size: 16),
                              label: const Text('+2 Hours', style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              onPressed: busy
                                  ? null
                                  : () => run(() async {
                                        await api.request('advance', {'seconds': 7200});
                                      }),
                            ),
                        ],
                      ),
                      if (data!['demo'] == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.science_rounded, size: 15, color: Color(0xFFD97706)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'DEMO SIMULATION: Clock and events are software-simulated. Records persist to local SQLite.',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // KPI Metric Cards Ribbon
                if (data!['metrics'] != null) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final metrics = (data!['metrics'] as Map<String, dynamic>).entries.toList();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in metrics)
                            Container(
                              width: (constraints.maxWidth - 24) / 4 > 90
                                  ? (constraints.maxWidth - 24) / 4
                                  : (constraints.maxWidth - 8) / 2,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    StatusColors.label(m.key).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${m.value}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                if (error != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],

                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(minHeight: 4),
                    ),
                  ),

                ...content(),
              ],
            ),
      bottomNavigationBar: data == null
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.outline, width: 1)),
              ),
              child: NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (i) => setState(() => tab = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.alt_route_rounded),
                    selectedIcon: Icon(Icons.alt_route_rounded, color: AppTheme.primary),
                    label: 'Routes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_none_rounded),
                    selectedIcon: Icon(Icons.notifications_rounded, color: AppTheme.primary),
                    label: 'Alerts',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insights_rounded),
                    selectedIcon: Icon(Icons.insights_rounded, color: AppTheme.primary),
                    label: 'Analytics',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.primary),
                    label: 'Zones & Fleet',
                  ),
                ],
              ),
            ),
    );
  }
}
