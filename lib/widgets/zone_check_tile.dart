import 'package:flutter/material.dart';

class ZoneCheckTile extends StatefulWidget {
  const ZoneCheckTile({
    super.key,
    required this.zoneName,
    required this.address,
    this.initiallyServiced = false,
    this.onChanged,
  });

  final String zoneName;
  final String address;
  final bool initiallyServiced;
  final ValueChanged<bool>? onChanged;

  @override
  State<ZoneCheckTile> createState() => _ZoneCheckTileState();
}

class _ZoneCheckTileState extends State<ZoneCheckTile> {
  late bool _serviced = widget.initiallyServiced;
  TimeOfDay? _servicedAt;

  void _toggle(bool? value) {
    setState(() {
      _serviced = value ?? false;
      _servicedAt = _serviced ? TimeOfDay.now() : null;
    });
    widget.onChanged?.call(_serviced);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = !_serviced
        ? widget.address
        : _servicedAt == null
            ? 'Serviced'
            : 'Serviced at ${_servicedAt!.format(context)}';

    return Card(
      elevation: 0,
      color: _serviced ? Colors.green.withAlpha(20) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _serviced
              ? Colors.green.shade300
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: CheckboxListTile(
        value: _serviced,
        onChanged: _toggle,
        controlAffinity: ListTileControlAffinity.trailing,
        secondary: Icon(
          _serviced ? Icons.check_circle : Icons.location_on_outlined,
          color: _serviced ? Colors.green.shade700 : null,
        ),
        title: Text(widget.zoneName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}