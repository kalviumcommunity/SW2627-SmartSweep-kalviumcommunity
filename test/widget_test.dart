import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sweep/main.dart';

void main() {
  testWidgets('Operational login starts without Firebase or a network request', (tester) async {
    await tester.pumpWidget(const SmartSweepApp());
    expect(find.text('Sign in to local operations'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
