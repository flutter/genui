// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_genui/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/chats/inline_chat_travel_planner.dart';
import 'package:travel_app/src/controllers/travel_planner_canvas_controller.dart';

void main() {
  group('InlineChatTravelPlanner', () {
    testWidgets('renders correctly with empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: InlineChatTravelPlanner()),
      );

      // Should show the app bar with correct title
      expect(find.text('Travel Inc. - Inline Chat'), findsOneWidget);

      // Should show the text input field
      expect(find.byType(TextField), findsOneWidget);

      // Should show send button
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('can send a message with fake client', (
      WidgetTester tester,
    ) async {
      final mockAiClient = FakeAiClient();
      mockAiClient.response = {'result': true, 'message': 'Hello from AI!'};

      await tester.pumpWidget(
        MaterialApp(home: InlineChatTravelPlanner(aiClient: mockAiClient)),
      );

      // Enter text and send
      await tester.enterText(find.byType(TextField), 'plan a trip to Paris');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Wait for AI response
      await mockAiClient.responseCompleter.future;

      // Verify the AI client was called
      expect(mockAiClient.generateContentCallCount, 1);
    });

    testWidgets('shows thinking state correctly', (WidgetTester tester) async {
      final mockAiClient = FakeAiClient();
      final completer = Completer<dynamic>();
      mockAiClient.generateContentFuture = completer.future;

      await tester.pumpWidget(
        MaterialApp(home: InlineChatTravelPlanner(aiClient: mockAiClient)),
      );

      // Send a message to trigger thinking state
      await tester.enterText(find.byType(TextField), 'test prompt');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Should disable the text field and show spinner when thinking
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the response
      completer.complete({'result': true, 'message': 'Response!'});
      await tester.pumpAndSettle();

      // Should re-enable text field
      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.enabled, isTrue);
    });

    testWidgets('has proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: InlineChatTravelPlanner()),
      );

      // Should have a drawer
      expect(
        find.byType(Drawer),
        findsNothing,
      ); // Drawer is not open by default

      // Should have app bar with drawer button
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Should have chat input
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('opens drawer when menu is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: InlineChatTravelPlanner()),
      );

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should show drawer
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('accepts external controller for testing', (
      WidgetTester tester,
    ) async {
      final mockAiClient = FakeAiClient();
      mockAiClient.response = {'result': true, 'message': 'Test response'};

      final testController = TravelPlannerCanvasController(
        enableChatOutput: true,
        aiClient: mockAiClient,
      );

      await tester.pumpWidget(
        MaterialApp(home: InlineChatTravelPlanner(controller: testController)),
      );

      // Should work with external controller
      expect(find.text('Travel Inc. - Inline Chat'), findsOneWidget);

      // Clean up
      testController.dispose();
    });
  });
}
