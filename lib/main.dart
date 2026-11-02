import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'operations/operations_screen.dart';

const legacyFirebase = bool.fromEnvironment('LEGACY_FIREBASE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (legacyFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  runApp(const SmartSweepApp());
}

class SmartSweepApp extends StatelessWidget {
  const SmartSweepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSweep',
      builder: (context, child) => legacyFirebase
          ? Banner(message: 'LEGACY PROTOTYPE', location: BannerLocation.topEnd, child: child!)
          : child!,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: legacyFirebase ? const AuthGate() : const OperationsScreen(),
    );
  }
}