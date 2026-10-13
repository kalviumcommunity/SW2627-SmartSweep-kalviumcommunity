import 'package:flutter/material.dart';
import '../widgets/loading_overlay.dart';

class RouteSyncScreen extends StatefulWidget {
  const RouteSyncScreen({super.key});

  @override
  State<RouteSyncScreen> createState() => _RouteSyncScreenState();
}

class _RouteSyncScreenState extends State<RouteSyncScreen> {
  // Task 1: loading flag in state
  bool isLoading = false;
  bool simulateFailure = false;
  String? resultMessage;
  bool resultIsError = false;

  Future<void> _syncRouteData() async {
    // Task 2: flag set and indicator shown BEFORE the operation begins
    setState(() {
      isLoading = true;
      resultMessage = null;
    });

    try {
      // Long-running operation (replace with a real Firestore call later)
      await Future.delayed(const Duration(seconds: 3));

      if (simulateFailure) {
        throw Exception('Network timeout while syncing routes');
      }

      if (!mounted) return;
      setState(() {
        resultMessage = 'Synced 12 routes successfully';
        resultIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        resultMessage = e.toString().replaceFirst('Exception: ', '');
        resultIsError = true;
      });
    } finally {
      // Task 3: runs on success AND failure, so the indicator always clears
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = resultIsError ? Colors.red.shade700 : Colors.green.shade700;

    return Scaffold(
      appBar: AppBar(title: const Text('SmartSweep - Route Sync')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Pull the latest route and zone data from the server.'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Simulate failure'),
                subtitle: const Text('Shows the loader clears even on error'),
                value: simulateFailure,
                onChanged:
                    isLoading ? null : (v) => setState(() => simulateFailure = v),
              ),
              const SizedBox(height: 16),
              // Task 4: onPressed is null while loading, so no double-fire
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : _syncRouteData,
                  icon: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync),
                  label: Text(isLoading ? 'Syncing...' : 'Sync route data'),
                ),
              ),
              if (resultMessage != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: resultColor.withAlpha(25),
                  child: ListTile(
                    leading: Icon(
                      resultIsError ? Icons.error_outline : Icons.check_circle_outline,
                      color: resultColor,
                    ),
                    title: Text(
                      resultIsError ? 'Sync failed' : 'Sync complete',
                      style:
                          TextStyle(color: resultColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(resultMessage!),
                  ),
                ),
              ],
            ],
          ),
          if (isLoading) const LoadingOverlay(message: 'Syncing route data...'),
        ],
      ),
    );
  }
}