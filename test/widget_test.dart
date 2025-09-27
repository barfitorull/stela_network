// Basic Flutter widget test for Stela Network app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stela_network/main.dart';

void main() {
  testWidgets('Stela Network app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
