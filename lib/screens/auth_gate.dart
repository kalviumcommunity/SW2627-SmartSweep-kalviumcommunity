import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Single source of truth for "is the user allowed in?".
/// Rebuilds automatically whenever Firebase's auth state changes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Created once so the stream is not re-subscribed on every rebuild
  late final Stream<User?> _authStream = AuthService().authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // Firebase is restoring the persisted session.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Restoring your session...',
                  ),
                ],
              ),
            ),
          );
        }

        // Authentication initialization error.
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to restore your session. '
                  'Please restart the application.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // Persisted authenticated session exists.
        if (snapshot.data != null) {
          return const HomeScreen();
        }

        // No authenticated session.
        return const LoginScreen();
      },
    );
  }
}