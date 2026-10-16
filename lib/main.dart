import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartSweepApp());
}

class SmartSweepApp extends StatelessWidget {
  const SmartSweepApp({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthService().currentUser != null;
    return MaterialApp(
      title: 'SmartSweep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: signedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}