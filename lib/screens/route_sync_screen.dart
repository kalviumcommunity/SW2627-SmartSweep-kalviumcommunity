import 'package:flutter/material.dart';

class RouteSyncScreen extends StatefulWidget {
  const RouteSyncScreen({super.key});

  @override
  State<RouteSyncScreen> createState() => _RouteSyncScreenState();
}

class _RouteSyncScreenState extends State<RouteSyncScreen> {
  final TextEditingController routeNumberController =
      TextEditingController();

  bool isProcessing = false;
  bool resultIsError = false;
  String? resultMessage;

  @override
  void dispose() {
    routeNumberController.dispose();
    super.dispose();
  }

  Future<void> processRoute() async {
    setState(() {
      isProcessing = true;
      resultMessage = null;
      resultIsError = false;
    });

    try {
      // Risky operation:
      // int.parse throws FormatException for invalid input.
      final int routeNumber =
          int.parse(routeNumberController.text.trim());

      // Simulates an asynchronous operation.
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        return;
      }

      setState(() {
        resultMessage =
            'Route $routeNumber processed successfully.';
        resultIsError = false;
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        resultMessage =
            'Please enter a valid route number, for example 101.';
        resultIsError = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        resultMessage =
            'Something went wrong while processing the route. Please try again.';
        resultIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void retry() {
    setState(() {
      resultMessage = null;
      resultIsError = false;
    });

    processRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Processing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Process Route',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter a route number to process the route.',
            ),

            const SizedBox(height: 24),

            TextField(
              controller: routeNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Route Number',
                hintText: 'Example: 101',
                prefixIcon: Icon(Icons.route),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: isProcessing ? null : processRoute,
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                isProcessing
                    ? 'Processing...'
                    : 'Process Route',
              ),
            ),

            const SizedBox(height: 24),

            if (resultMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: resultIsError
                        ? Colors.red
                        : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      resultIsError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 40,
                      color: resultIsError
                          ? Colors.red
                          : Colors.green,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      resultMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    if (resultIsError) ...[
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: isProcessing ? null : retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}