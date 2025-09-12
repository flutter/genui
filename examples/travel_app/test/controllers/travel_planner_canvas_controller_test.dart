// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_app/src/controllers/travel_planner_canvas_controller.dart';

import 'travel_planner_canvas_controller_test.mocks.dart';

@GenerateMocks([AiClient, GenUiManager])
void main() {
  group('TravelPlannerCanvasController', () {
    late MockAiClient mockAiClient;
    late MockGenUiManager mockGenUiManager;

    setUp(() {
      mockAiClient = MockAiClient();
      mockGenUiManager = MockGenUiManager();
      when(mockGenUiManager.onSubmit).thenAnswer((_) => const Stream.empty());
      when(
        mockGenUiManager.surfaceUpdates,
      ).thenAnswer((_) => const Stream.empty());
      when(mockGenUiManager.getTools()).thenReturn([]);
    });

    test('sendUserTextMessage sends a message and gets a response', () async {
      final controller = TravelPlannerCanvasController(
        aiClient: mockAiClient,
        genUiManager: mockGenUiManager,
      );

      when(mockAiClient.generateContent(any, any)).thenAnswer(
        (_) async => {'result': true, 'message': 'Hello from the AI!'},
      );

      // Test that text messages are updated
      var textMessageCount = 0;
      controller.textMessages.listen((messages) {
        textMessageCount = messages.length;
      });

      // Test thinking state
      var isThinking = false;
      controller.isThinking.listen((thinking) {
        isThinking = thinking;
      });

      expect(controller.currentIsThinking, false);

      controller.sendUserTextMessage('Hello');

      // Allow async operations to complete
      // ignore: inference_failure_on_instance_creation
      await Future.delayed(const Duration(milliseconds: 50));

      expect(textMessageCount, 2); // user message + AI response
      expect(isThinking, false); // should be false after completion

      controller.dispose();
    });

    test('enableChatOutput false does not produce AI text messages', () async {
      final controller = TravelPlannerCanvasController(
        enableChatOutput: false,
        aiClient: mockAiClient,
        genUiManager: mockGenUiManager,
      );

      when(
        mockAiClient.generateContent(any, any),
      ).thenAnswer((_) async => {'result': true});

      var textMessageCount = 0;
      controller.textMessages.listen((messages) {
        textMessageCount = messages.length;
      });

      controller.sendUserTextMessage('Hello');

      // ignore: inference_failure_on_instance_creation
      await Future.delayed(const Duration(milliseconds: 50));

      expect(textMessageCount, 1); // only user message, no AI response

      controller.dispose();
    });

    test('exposes GenUiManager correctly', () {
      final controller = TravelPlannerCanvasController(
        aiClient: mockAiClient,
        genUiManager: mockGenUiManager,
      );

      expect(controller.genUiManager, mockGenUiManager);

      controller.dispose();
    });
  });
}
