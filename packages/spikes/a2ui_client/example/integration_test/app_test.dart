// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('A2UI Example App', () {
    testWidgets('fetches agent card and checks for success', (tester) async {
      // User Journey:
      // 1. Start the app.
      // 2. Navigate to the settings page.
      // 3. Tap the "Fetch Agent Card" button.
      // 4. Verify that the agent card is displayed.

      app.main();
      await tester.pumpAndSettle();

      // Tap the settings icon.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Tap the "Fetch Agent Card" button.
      await tester.tap(find.text('Fetch Agent Card'));
      await tester.pumpAndSettle();

      // Verify that the agent card is displayed.
      expect(find.text('Name: A2UI Genkit Server'), findsOneWidget);
      expect(
        find.text(
          'Description: An agent that generates UIs using the A2UI protocol.',
        ),
        findsOneWidget,
      );
      expect(find.text('Version: 1.0.0'), findsOneWidget);
    });
  });
}
