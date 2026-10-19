import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Task 4: protected screen is only built when a user exists
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        // Task 3: signed out (or never signed in) always lands here
        return const LoginScreen();
      },
    );
  }
}