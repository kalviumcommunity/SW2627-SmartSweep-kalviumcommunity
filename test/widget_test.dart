import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_sweep/main.dart';

void main() {
  testWidgets('SmartSweep app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartSweepApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
