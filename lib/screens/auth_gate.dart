import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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