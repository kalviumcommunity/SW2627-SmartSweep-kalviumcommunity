import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../services/zone_service.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final _service = ZoneService();
  late final Stream<List<Zone>> _zones = _service.watchZones();

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addZone() async {
    final zone = await showDialog<Zone>(
      context: context,
      builder: (_) => const _AddZoneDialog(),
    );
    if (zone == null) return;

    try {
      await _service.addZone(zone);
      if (mounted) _snack('Zone added');
    } catch (_) {
      if (mounted) _snack('Could not save. Check your connection and Firestore rules.');
    }
  }

  Future<void> _onAction(String action, Zone zone) async {
    try {
      switch (action) {
        case 'missed':
          await _service.updateZone(zone.copyWith(missedCount: zone.missedCount + 1));
          break;
        case 'serviced':
          await _service.updateZone(zone.copyWith(lastServicedAt: DateTime.now()));
          break;
        case 'delete':
          await _service.deleteZone(zone.id);
          break;
      }
    } catch (_) {
      if (mounted) _snack('Action failed. Please try again.');
    }
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addZone,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add zone'),
      ),
      body: StreamBuilder<List<Zone>>(
        stream: _zones,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load zones.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final zones = snapshot.data!;
          if (zones.isEmpty) {
            return const Center(child: Text('No zones yet. Tap "Add zone".'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final z = zones[i];
              final color = z.hasRecurringMisses ? Colors.red.shade700 : Colors.green.shade700;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(30),
                    child: Icon(Icons.location_city, color: color),
                  ),
                  title: Text(z.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${z.area} | ${z.scheduleDay}\n'
                    'Missed: ${z.missedCount}'
                    '${z.hasRecurringMisses ? '  (recurring issue)' : ''}\n'
                    'Last serviced: ${z.lastServicedAt == null ? 'never' : _date(z.lastServicedAt!)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (a) => _onAction(a, z),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'missed', child: Text('Record missed collection')),
                      PopupMenuItem(value: 'serviced', child: Text('Mark serviced now')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Owns its controllers, so they are disposed safely with the dialog.
class _AddZoneDialog extends StatefulWidget {
  const _AddZoneDialog();

  @override
  State<_AddZoneDialog> createState() => _AddZoneDialogState();
}

class _AddZoneDialogState extends State<_AddZoneDialog> {
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _area = TextEditingController();
  String _day = _days.first;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Zone(
        id: '', // Firestore generates the real id
        name: _name.text.trim(),
        area: _area.text.trim(),
        scheduleDay: _day,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add zone'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Zone name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(labelText: 'Area / locality'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _day,
              decoration: const InputDecoration(labelText: 'Collection day'),
              items: _days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _day = v ?? _day),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}