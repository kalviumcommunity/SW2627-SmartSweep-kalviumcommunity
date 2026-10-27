import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../services/zone_service.dart';

class LiveZonesScreen extends StatefulWidget {
  const LiveZonesScreen({super.key});

  @override
  State<LiveZonesScreen> createState() => _LiveZonesScreenState();
}

class _LiveZonesScreenState extends State<LiveZonesScreen> {
  final _service = ZoneService();

  // Task 1: the real-time listener. Created once so the StreamBuilder
  // keeps a single Firestore listener open. The .map() records what
  // changed in each snapshot for the activity log.
  late final Stream<QuerySnapshot<Zone>> _stream =
      _service.watchZoneSnapshots().map((snap) {
    _recordChanges(snap);
    return snap;
  });

  final List<String> _log = [];
  bool _firstSnapshot = true;
  DateTime? _lastUpdateAt;
  bool _lastFromCache = false;

  // One-time get() comparison
  int? _oneTimeCount;
  DateTime? _oneTimeAt;
  bool _fetching = false;

  String _t(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}';

  void _addLog(String text) {
    _log.insert(0, '${_t(DateTime.now())}  $text');
    if (_log.length > 20) _log.removeLast();
  }

  void _recordChanges(QuerySnapshot<Zone> snap) {
    _lastUpdateAt = DateTime.now();
    _lastFromCache = snap.metadata.isFromCache;

    if (_firstSnapshot) {
      _firstSnapshot = false;
      _addLog('Loaded ${snap.size} zones');
      return;
    }
    for (final change in snap.docChanges) {
      final name = change.doc.data()?.name ?? change.doc.id;
      switch (change.type) {
        case DocumentChangeType.added:
          _addLog('Added: $name');
          break;
        case DocumentChangeType.modified:
          _addLog('Updated: $name');
          break;
        case DocumentChangeType.removed:
          _addLog('Deleted: $name');
          break;
      }
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _fetchOnce() async {
    setState(() => _fetching = true);
    try {
      final list = await _service.fetchZonesOnce();
      if (!mounted) return;
      setState(() {
        _oneTimeCount = list.length;
        _oneTimeAt = DateTime.now();
      });
    } catch (_) {
      if (mounted) _snack('Could not fetch zones.');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _addSampleZone() async {
    final now = DateTime.now();
    try {
      await _service.addZone(Zone(
        id: '',
        name: 'Test zone ${_t(now)}',
        area: 'Sample area',
        scheduleDay: 'Monday',
        createdAt: now,
      ));
      if (mounted) _snack('Test zone added.');
    } catch (_) {
      if (mounted) _snack('Could not add zone.');
    }
  }

  Future<void> _onAction(String action, Zone zone) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete issue?'),
          content: const Text(
            'Are you sure you want to delete this issue? This action cannot be undone.',
          ),
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
      if (!mounted || confirmed != true) return;
    }

    try {
      if (action == 'missed') {
        await _service.recordMissed(zone.id);
        if (mounted) _snack('Missed collection recorded.');
      }
      if (action == 'delete') {
        await _service.deleteZone(zone.id);
        if (mounted) _snack('Record deleted.');
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'permission-denied' => 'You do not have permission to update this record.',
        'unavailable' => 'No connection. Check your network and try again.',
        'not-found' => 'This record no longer exists.',
        _ => 'Could not complete the action. Please try again.',
      };
      _snack(message);
    } catch (_) {
      if (mounted) _snack('Action failed. Please try again.');
    }
  }

  Widget _statusCard(int liveCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('LIVE', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$liveCount zones',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _lastUpdateAt == null
                  ? 'Waiting for first update...'
                  : 'Last update ${_t(_lastUpdateAt!)} '
                      '(${_lastFromCache ? 'from local cache' : 'from server'})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _oneTimeCard(int liveCount) {
    final stale = _oneTimeCount != null && _oneTimeCount != liveCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('One-time get() for comparison',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(_oneTimeCount == null
                ? 'Not fetched yet.'
                : 'get() returned $_oneTimeCount zones at ${_t(_oneTimeAt!)}. '
                    'This number never updates by itself.'),
            if (stale) ...[
              const SizedBox(height: 4),
              Text(
                'Out of date: the live list now has $liveCount.',
                style: TextStyle(
                    color: Colors.orange.shade800, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _fetching ? null : _fetchOnce,
              icon: const Icon(Icons.download),
              label: Text(_fetching ? 'Fetching...' : 'Fetch once with get()'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live activity', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_log.isEmpty)
              const Text('No changes yet.')
            else
              for (final line in _log.take(8)) Text(line),
          ],
        ),
      ),
    );
  }

  Widget _zoneTile(Zone z) {
    final color = !z.isActive
        ? Colors.blueGrey
        : z.hasRecurringMisses
            ? Colors.red.shade700
            : Colors.green.shade700;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(Icons.location_city, color: color),
        ),
        title: Text(z.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${z.area} | ${z.scheduleDay} | Missed: ${z.missedCount}'),
        trailing: PopupMenuButton<String>(
          onSelected: (a) => _onAction(a, z),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'missed', child: Text('Record missed collection')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live zone monitor')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSampleZone,
        icon: const Icon(Icons.add),
        label: const Text('Add test zone'),
      ),
      body: StreamBuilder<QuerySnapshot<Zone>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Live updates unavailable. Check your connection and Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tasks 2-4: this rebuilds on every add, update and delete
          final zones = snapshot.data!.docs.map((d) => d.data()).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _statusCard(zones.length),
              const SizedBox(height: 12),
              _oneTimeCard(zones.length),
              const SizedBox(height: 12),
              _logCard(),
              const SizedBox(height: 16),
              Text('Zones (${zones.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (zones.isEmpty) const Text('No zones yet. Tap "Add test zone".'),
              for (final z in zones) _zoneTile(z),
            ],
          );
        },
      ),
    );
  }
}