import 'package:flutter/material.dart';

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Back to Routes'),
        ),
      ),
    );
  }
}