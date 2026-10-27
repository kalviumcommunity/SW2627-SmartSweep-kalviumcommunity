import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onOpenTab});

  /// Asks the shell to switch to another tab (1 = Zones, 2 = Live, 3 = Storage)
  final ValueChanged<int>? onOpenTab;

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use SmartSweep.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Close any screens pushed on top so none stay reachable
    navigator.popUntil((route) => route.isFirst);

    try {
      await AuthService().signOut();
      // No Navigator call: AuthGate sees the null user and shows the login screen
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSweep'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 64, color: Colors.green.shade700),
              const SizedBox(height: 16),
              Text('Protected dashboard',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(user?.email ?? 'Unknown user'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => onOpenTab?.call(1),
                icon: const Icon(Icons.location_city),
                label: const Text('Go to Zones'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => onOpenTab?.call(2),
                icon: const Icon(Icons.sensors),
                label: const Text('Go to Live monitor'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => onOpenTab?.call(3),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Go to Storage'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}