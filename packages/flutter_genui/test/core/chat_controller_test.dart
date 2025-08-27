// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenUiChatController', () {
    late GenUiManager manager;
    late GenUiChatController controller;

    setUp(() {
      manager = GenUiManager();
      controller = GenUiChatController(manager: manager);
    });

    tearDown(() {
      controller.dispose();
      manager.dispose();
    });

    test('initial conversation is empty', () {
      expect(controller.conversation.value.length, 0);
    });

    test('addMessage adds a message to the conversation', () {
      final message = UserMessage.text('Hello');
      controller.addMessage(message);
      expect(controller.conversation.value.length, 1);
      expect(controller.conversation.value.last, message);
    });

    testWidgets('manager SurfaceAdded update adds a new surface message', (
      WidgetTester tester,
    ) async {
      manager.addOrUpdateSurface('s2', {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'text': {'text': 'Surface 2'},
            },
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(controller.conversation.value.length, 1);
      final lastMessage = controller.conversation.value.last;
      expect(lastMessage, isA<AiUiMessage>());
      expect((lastMessage as AiUiMessage).surfaceId, 's2');
    });

    testWidgets('manager SurfaceRemoved update removes a surface message', (
      WidgetTester tester,
    ) async {
      manager.addOrUpdateSurface('main_surface', {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'text': {'text': 'Hello!'},
            },
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(controller.conversation.value.length, 1);
      manager.deleteSurface('main_surface');
      await tester.pumpAndSettle();
      expect(controller.conversation.value.length, 0);
    });

    testWidgets('manager SurfaceUpdated update modifies a surface message', (
      WidgetTester tester,
    ) async {
      manager.addOrUpdateSurface('main_surface', {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'text': {'text': 'Hello!'},
            },
          },
        ],
      });
      await tester.pumpAndSettle();
      manager.addOrUpdateSurface('main_surface', {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'text': {'text': 'Updated'},
            },
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(controller.conversation.value.length, 1);
      final message = controller.conversation.value.first as AiUiMessage;
      final widget = message.definition['widgets'] as List<Object?>;
      final root = widget.first as Map<String, Object?>;
      final textWidget = root['widget'] as Map<String, Object?>;
      final text = textWidget['text'] as Map<String, Object?>;
      expect(text['text'], 'Updated');
    });
  });
}
