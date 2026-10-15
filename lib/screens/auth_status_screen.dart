import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthStatusScreen extends StatefulWidget {
  const AuthStatusScreen({super.key});

  @override
  State<AuthStatusScreen> createState() => _AuthStatusScreenState();
}

class _AuthStatusScreenState extends State<AuthStatusScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool isLoading = false;
  String? message;
  bool messageIsError = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in the Firebase console.';
      case 'email-already-in-use':
        return 'That email already has an account.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        return '${e.code}: ${e.message ?? 'Authentication failed.'}';
    }
  }

  Future<void> _run(Future<void> Function() action, String successText) async {
    setState(() {
      isLoading = true;
      message = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {
        message = successText;
        messageIsError = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        message = _friendlyError(e);
        messageIsError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = 'Something went wrong. Please try again.';
        messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartSweep - Auth Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Reads the current user live from FirebaseAuth via AuthService
          StreamBuilder<User?>(
            stream: _auth.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final signedIn = user != null;
              return Card(
                color: (signedIn ? Colors.green : Colors.blueGrey).withAlpha(25),
                child: ListTile(
                  leading: Icon(
                    signedIn ? Icons.verified_user : Icons.person_off_outlined,
                    color: signedIn ? Colors.green.shade700 : Colors.blueGrey,
                  ),
                  title: Text(signedIn ? 'Signed in' : 'Not signed in'),
                  subtitle: Text(
                    signedIn
                        ? '${user.email}\nUID: ${user.uid}'
                        : 'currentUser is null',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Connection test (full sign-up and login screens come next)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () => _run(
                            () => _auth.signUp(_email.text, _password.text),
                            'Account created and signed in.',
                          ),
                  child: const Text('Test sign up'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => _run(
                            () => _auth.signOut(),
                            'Signed out.',
                          ),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (message != null) ...[
            const SizedBox(height: 16),
            Card(
              color: (messageIsError ? Colors.red : Colors.green).withAlpha(25),
              child: ListTile(
                leading: Icon(
                  messageIsError ? Icons.error_outline : Icons.check_circle_outline,
                  color: messageIsError ? Colors.red.shade700 : Colors.green.shade700,
                ),
                title: Text(message!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}