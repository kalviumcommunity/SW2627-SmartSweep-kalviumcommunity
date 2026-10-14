import 'package:flutter/material.dart';
import '../models/route_report.dart';
import '../services/route_service.dart';

class RouteStatusScreen extends StatefulWidget {
  const RouteStatusScreen({super.key});

  @override
  State<RouteStatusScreen> createState() => _RouteStatusScreenState();
}

class _RouteStatusScreenState extends State<RouteStatusScreen> {
  List<RouteReport> reports = [];
  bool isLoading = false;
  bool simulateFailure = false;
  String? error;
  int tapCount = 0; // proves the UI stays responsive while loading
  String? withoutAwaitNote;

  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Task 2: await pauses THIS function only, not the UI thread,
      // and gives back the real result (a List<RouteReport>).
      final result = await RouteService.fetchRouteReports(fail: simulateFailure);

      if (!mounted) return;
      // Task 4: completion updates the UI
      setState(() => reports = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Follow-up demo: calling an async function WITHOUT await.
  void _callWithoutAwait() {
    final pending = RouteService.fetchRouteReports(); // no await
    setState(() {
      withoutAwaitNote =
          'Got ${pending.runtimeType} immediately, not the list. '
          'The data is not ready yet.';
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade700;
      case 'Delayed':
        return Colors.orange.shade800;
      case 'Missed':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartSweep - Route Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Task 3: this stays tappable while the async call is running
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Responsiveness check\nTaps: $tapCount',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => setState(() => tapCount++),
                    child: const Text('Tap me'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Simulate failure'),
            value: simulateFailure,
            onChanged: isLoading ? null : (v) => setState(() => simulateFailure = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _loadReports,
              icon: const Icon(Icons.cloud_download),
              label: Text(isLoading ? 'Loading...' : 'Load route status'),
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 4),
            const Text('Fetching data... you can still use the app.'),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.red.withAlpha(25),
              child: ListTile(
                leading: Icon(Icons.error_outline, color: Colors.red.shade700),
                title: Text(error!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final r in reports)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(r.status).withAlpha(30),
                  child: Icon(Icons.local_shipping, color: _statusColor(r.status)),
                ),
                title: Text('${r.routeName} - ${r.zone}'),
                subtitle: Text('${r.zonesDone} of ${r.zonesTotal} zones serviced'),
                trailing: Text(
                  r.status,
                  style: TextStyle(
                    color: _statusColor(r.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const Divider(height: 32),
          OutlinedButton(
            onPressed: _callWithoutAwait,
            child: const Text('Demo: call without await'),
          ),
          if (withoutAwaitNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(withoutAwaitNote!),
            ),
        ],
      ),
    );
  }
}