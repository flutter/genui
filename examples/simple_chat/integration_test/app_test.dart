// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:simple_chat/main.dart';

// Import from ../test via relative path since it is not in lib
import '../test/fake_ai_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  group('Simple Chat Integration Tests', () {
    testWidgets('render hello world sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_1_hello.json',
          (tester) async {
            expect(find.textContaining('Hello, World!'), findsOneWidget);
          },
        );
      });
    });

    testWidgets('render button sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_2_button.json',
          (tester) async {
            // Button might be ElevatedButton, TextButton, or FilledButton.
            // Just finding text is safer for integration test unless we care
            // about specific styling.
            expect(find.text('Click Me'), findsOneWidget);
          },
        );
      });
    });

    testWidgets('render image sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_3_image.json',
          (tester) async {
            // Image widget should exist even if mocked.
            expect(find.byType(Image), findsOneWidget);
          },
        );
      });
    });

    testWidgets('render form sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_4_form.json',
          (tester) async {
            // Debug dump if fails
            expect(find.text('Type'), findsOneWidget);
            expect(find.text('Size'), findsOneWidget);
            expect(find.text('Submit Filters'), findsOneWidget);
          },
        );
      });
    });

    testWidgets('render mixed sample', (tester) async {
      await mockNetworkImagesFor(() async {
        await _runTestForSample(
          tester,
          'integration_test/samples/sample_5_mixed.json',
          (tester) async {
            expect(find.text('Do you want to proceed?'), findsOneWidget);
            expect(find.text('Yes, proceed'), findsOneWidget);
          },
        );
      });
    });
  });
}

Future<void> _runTestForSample(
  WidgetTester tester,
  String samplePath,
  Future<void> Function(WidgetTester) verify,
) async {
  // Read sample file
  final file = File(samplePath);
  if (!file.existsSync()) {
    fail('Sample file not found: $samplePath');
  }
  final String jsonString = await file.readAsString();

  // Initialize FakeAiClient
  final fakeAiClient = FakeAiClient();

  // Queue the response
  // GenUiController expects A2UI messages to be wrapped in markdown code blocks
  // or detectable as structured content. Standard LLM behavior using GenUi
  // is to return ```json ... ``` blocks.
  fakeAiClient.addResponse('Here is the UI:\n```json\n$jsonString\n```');

  // Pump the app
  // Using MaterialApp as wrapper to provide Theme, etc, if MyApp doesn't
  // allow injection.
  // But MyApp just creates ChatScreen, which we can instantiate directly.
  await tester.pumpWidget(
    MaterialApp(home: ChatScreen(aiClient: fakeAiClient)),
  );

  // Trigger a message to start the flow
  await tester.enterText(find.byType(TextField), 'Test Trigger');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pump(); // Start processing

  // Wait for response and rendering
  // The FakeAiClient splits it into chunks with delays.
  await tester.pumpAndSettle();

  // Run verification
  await verify(tester);
}
