import 'package:flutter/material.dart';

import '../widgets/loading_overlay.dart';

class RouteSyncScreen extends StatefulWidget {
  const RouteSyncScreen({super.key});

  @override
  State<RouteSyncScreen> createState() => _RouteSyncScreenState();
}

class _RouteSyncScreenState extends State<RouteSyncScreen> {
  bool isLoading = false;
  bool simulateFailure = false;
  String? resultMessage;
  bool resultIsError = false;

  // Simulated asynchronous data operation.
  // Replace this with a real API or database call later.
  Future<void> _performSync() async {
    await Future.delayed(const Duration(seconds: 3));

    if (simulateFailure) {
      throw Exception('Simulated network timeout');
    }
  }

  // Task 1 & 3: Handle asynchronous errors using try/catch.
  Future<void> _syncRouteData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      resultMessage = null;
      resultIsError = false;
    });

    try {
      await _performSync();

      if (!mounted) return;

      setState(() {
        resultMessage = 'Route data synced successfully (demo).';
        resultIsError = false;
      });
    } catch (_) {
      // Task 2: Never display a raw exception to users.
      if (!mounted) return;

      setState(() {
        resultMessage =
            'Unable to sync route data. '
            'Please try again.';
        resultIsError = true;
      });
    } finally {
      // Always clear the loader on success or failure.
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = resultIsError
        ? Colors.red.shade700
        : Colors.green.shade700;

    return Scaffold(
      appBar: AppBar(title: const Text('SmartSweep - Route Sync')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Demonstration of route data synchronization '
                'with asynchronous error handling.',
              ),

              const SizedBox(height: 16),

              // Simulate an operation failure for testing.
              SwitchListTile(
                title: const Text('Simulate failure'),
                subtitle: const Text(
                  'Enable to test error handling and retry.',
                ),
                value: simulateFailure,
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          simulateFailure = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              // Disable repeated requests during loading.
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(isLoading ? 'Syncing...' : 'Sync route data'),
                ),
              ),

              // Success or error message.
              if (resultMessage != null) ...[
                const SizedBox(height: 24),

                Card(
                  color: resultColor.withAlpha(25),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(
                            resultIsError
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: resultColor,
                          ),
                          title: Text(
                            resultIsError ? 'Sync failed' : 'Sync complete',
                            style: TextStyle(
                              color: resultColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(resultMessage!),
                        ),

                        // Task 4: Allow the user to retry.
                        if (resultIsError) ...[
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _syncRouteData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry Sync'),
                            ),
                          ),
                        ],
                      ],
                    ),
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
