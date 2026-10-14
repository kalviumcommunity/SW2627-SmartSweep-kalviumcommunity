import 'package:flutter/material.dart';
import 'screens/route_status_screen.dart';

void main() {
  runApp(const SmartSweepApp());
}

class SmartSweepApp extends StatelessWidget {
  const SmartSweepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSweep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const RouteStatusScreen(),
    );
  }
}