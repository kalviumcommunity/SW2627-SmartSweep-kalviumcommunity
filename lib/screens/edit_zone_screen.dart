import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../services/zone_service.dart';

class EditZoneScreen extends StatefulWidget {
  const EditZoneScreen({super.key, required this.zone});

  /// Task 2: the tapped zone carries its Firestore document id
  final Zone zone;

  @override
  State<EditZoneScreen> createState() => _EditZoneScreenState();
}

class _EditZoneScreenState extends State<EditZoneScreen> {
  static const _baseDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  final _service = ZoneService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.zone.name);
  late final TextEditingController _area = TextEditingController(text: widget.zone.area);
  late String _day = widget.zone.scheduleDay;
  late bool _isActive = widget.zone.isActive;

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Task 3: build a map of ONLY the fields that actually changed
    final changes = <String, Object?>{};
    final name = _name.text.trim();
    final area = _area.text.trim();
    if (name != widget.zone.name) changes['name'] = name;
    if (area != widget.zone.area) changes['area'] = area;
    if (_day != widget.zone.scheduleDay) changes['scheduleDay'] = _day;
    if (_isActive != widget.zone.isActive) changes['isActive'] = _isActive;

    if (changes.isEmpty) {
      setState(() => errorMessage = 'No changes to save.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Task 1 + 2: update() on the document with this zone's id
      await _service.updateZoneFields(widget.zone.id, changes);
      if (!mounted) return;
      Navigator.pop(context, true); // tell the list the update succeeded
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = switch (e.code) {
          'not-found' => 'This zone no longer exists. It may have been deleted.',
          'permission-denied' => 'You do not have permission to edit this zone.',
          'unavailable' => 'No connection. Check your network and try again.',
          _ => 'Could not save changes. Please try again.',
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'Something went wrong. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the current day selectable even if it isn't in the base list
    final days = {..._baseDays, if (widget.zone.scheduleDay.isNotEmpty) widget.zone.scheduleDay}
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit zone')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Document ID: ${widget.zone.id}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                      labelText: 'Zone name', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _area,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                      labelText: 'Area / locality', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _day,
                  decoration: const InputDecoration(
                      labelText: 'Collection day', border: OutlineInputBorder()),
                  items: days
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: isLoading ? null : (v) => setState(() => _day = v ?? _day),
                ),
                SwitchListTile(
                  title: const Text('Zone is active'),
                  value: _isActive,
                  onChanged: isLoading ? null : (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(errorMessage!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : _save,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}