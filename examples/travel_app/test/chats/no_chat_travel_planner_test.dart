// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_genui/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/chats/no_chat_travel_planner.dart';
import 'package:travel_app/src/controllers/travel_planner_canvas_controller.dart';

void main() {
  group('NoChatTravelPlanner', () {
    testWidgets('renders correctly with empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: NoChatTravelPlanner()));

      // Should show the app bar with correct title
      expect(find.text('Travel Inc. - Canvas'), findsOneWidget);

      // Should show empty state message
      expect(find.text('Where do you want to go?'), findsOneWidget);
      expect(
        find.text('Tell me about your dream trip and I\'ll help you plan it'),
        findsOneWidget,
      );

      // Should show suggestion chips
      expect(find.text('Plan a weekend in Paris'), findsOneWidget);
      expect(find.text('Family trip to Japan'), findsOneWidget);
      expect(find.text('Backpacking through Europe'), findsOneWidget);
      expect(find.text('Romantic getaway ideas'), findsOneWidget);
    });

    testWidgets('can tap suggestion chips', (WidgetTester tester) async {
      final mockAiClient = FakeAiClient();
      mockAiClient.response = {'result': true};

      await tester.pumpWidget(
        MaterialApp(home: NoChatTravelPlanner(aiClient: mockAiClient)),
      );

      // Tap a suggestion chip
      await tester.tap(find.text('Plan a weekend in Paris'));
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
        MaterialApp(home: NoChatTravelPlanner(aiClient: mockAiClient)),
      );

      // Tap a suggestion chip to trigger thinking state
      await tester.tap(find.text('Plan a weekend in Paris'));
      await tester.pump();

      // Should show thinking indicator when thinking
      expect(find.text('Planning...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Suggestion chips should be disabled
      final chip = tester.widget<ActionChip>(find.byType(ActionChip).first);
      expect(chip.onPressed, isNull);

      // Complete the response
      completer.complete({'result': true});
      await tester.pumpAndSettle();

      // Should hide thinking indicator
      expect(find.text('Planning...'), findsNothing);

      // Suggestion chips should be enabled again
      final chipAfter = tester.widget<ActionChip>(
        find.byType(ActionChip).first,
      );
      expect(chipAfter.onPressed, isNotNull);
    });

    testWidgets('has proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NoChatTravelPlanner()));

      // Should have a drawer
      expect(
        find.byType(Drawer),
        findsNothing,
      ); // Drawer is not open by default

      // Should have app bar with drawer button
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Should show the travel icon in empty state
      expect(find.byIcon(Icons.flight_takeoff), findsOneWidget);
    });

    testWidgets('opens drawer when menu is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: NoChatTravelPlanner()));

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Should show drawer
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('creates controller with chat output disabled by default', (
      WidgetTester tester,
    ) async {
      // This test verifies the widget can be created without errors
      // The actual enableChatOutput behavior is tested in the controller tests
      await tester.pumpWidget(const MaterialApp(home: NoChatTravelPlanner()));

      // Should show empty state indicating no chat functionality
      expect(find.text('Where do you want to go?'), findsOneWidget);

      // Should not show any chat-related UI
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('suggestion chips have proper styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: NoChatTravelPlanner()));

      // Should find ActionChip widgets
      expect(find.byType(ActionChip), findsNWidgets(4));

      // All chips should be enabled by default
      final chips = tester.widgetList<ActionChip>(find.byType(ActionChip));
      for (final chip in chips) {
        expect(chip.onPressed, isNotNull);
      }
    });

    testWidgets('accepts external controller for testing', (
      WidgetTester tester,
    ) async {
      final mockAiClient = FakeAiClient();
      mockAiClient.response = {'result': true};

      final testController = TravelPlannerCanvasController(
        enableChatOutput: false,
        aiClient: mockAiClient,
      );

      await tester.pumpWidget(
        MaterialApp(home: NoChatTravelPlanner(controller: testController)),
      );

      // Should work with external controller
      expect(find.text('Travel Inc. - Canvas'), findsOneWidget);

      // Clean up
      testController.dispose();
    });
  });
}
