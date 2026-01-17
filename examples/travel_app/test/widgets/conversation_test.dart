// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:travel_app/src/widgets/conversation.dart';

void main() {
  group('Conversation', () {
    late A2uiMessageProcessor manager;

    setUp(() {
      manager = A2uiMessageProcessor(catalogs: [CoreCatalogItems.asCatalog()]);
    });

    testWidgets('renders a list of messages', (WidgetTester tester) async {
      const surfaceId = 's1';
      final List<ChatMessage> messages = [
        UserMessage.text('Hello'),
        AiUiMessage(
          surfaceId: surfaceId,
          definition: UiDefinition(surfaceId: surfaceId),
        ),
      ];
      final components = [
        const Component(
          id: 'r1',
          componentProperties: {
            'Text': {
              'text': {'literalString': 'Hi there!'},
            },
          },
        ),
      ];
      manager.handleMessage(
        SurfaceUpdate(surfaceId: surfaceId, components: components),
      );
      manager.handleMessage(
        const BeginRendering(surfaceId: surfaceId, root: 'r1'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Conversation(messages: messages, manager: manager),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Hi there!'), findsOneWidget);
    });
    testWidgets('renders UserPrompt correctly', (WidgetTester tester) async {
      final messages = [
        UserMessage([const TextPart('Hello')]),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Conversation(messages: messages, manager: manager),
          ),
        ),
      );
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders UiResponse correctly', (WidgetTester tester) async {
      const surfaceId = 's1';
      final messages = [
        AiUiMessage(
          surfaceId: surfaceId,
          definition: UiDefinition(surfaceId: surfaceId),
        ),
      ];
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'Text': {
              'text': {'literalString': 'UI Content'},
            },
          },
        ),
      ];
      manager.handleMessage(
        SurfaceUpdate(surfaceId: surfaceId, components: components),
      );
      manager.handleMessage(
        const BeginRendering(surfaceId: surfaceId, root: 'root'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Conversation(messages: messages, manager: manager),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GenUiSurface), findsOneWidget);
      expect(find.text('UI Content'), findsOneWidget);
    });

    testWidgets('uses custom userPromptBuilder', (WidgetTester tester) async {
      final messages = [
        UserMessage(const [TextPart('Hello')]),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Conversation(
              messages: messages,
              manager: manager,
              userPromptBuilder: (context, message) =>
                  const Text('Custom User Prompt'),
            ),
          ),
        ),
      );
      expect(find.text('Custom User Prompt'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);
    });
  });
}
