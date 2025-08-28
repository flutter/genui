// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationWidget', () {
    late GenUiManager manager;

    setUp(() {
      manager = GenUiManager(catalog: coreCatalog);
    });

    testWidgets('renders a list of messages', (WidgetTester tester) async {
      final messages = [
        UserMessage.text('Hello'),
        AiUiMessage(
          surfaceId: 's1',
          definition: UiDefinition.fromMap({
            'surfaceId': 's1',
            'root': 'r1',
            'widgets': [
              {
                'id': 'r1',
                'widget': {
                  'Text': {'text': 'Hi there!'},
                },
              },
            ],
          }),
        ),
      ];
      manager.addOrUpdateSurface(
        's1',
        (messages[1] as AiUiMessage).definition.toMap(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              manager: manager,
              onEvent: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
    });
    testWidgets('renders UserPrompt correctly', (WidgetTester tester) async {
      final messages = [
        const UserMessage([TextPart('Hello')]),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              manager: manager,
              onEvent: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders UiResponse correctly', (WidgetTester tester) async {
      final messages = [
        AiUiMessage(
          surfaceId: 's1',
          definition: UiDefinition.fromMap({
            'surfaceId': 's1',
            'root': 'root',
            'widgets': [
              {
                'id': 'root',
                'widget': {
                  'Text': {'text': 'UI Content'},
                },
              },
            ],
          }),
        ),
      ];
      manager.addOrUpdateSurface('s1', messages[0].definition.toMap());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              manager: manager,
              onEvent: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(GenUiSurface), findsOneWidget);
      expect(find.text('UI Content'), findsOneWidget);
    });

    testWidgets('uses custom userPromptBuilder', (WidgetTester tester) async {
      final messages = [
        const UserMessage([TextPart('Hello')]),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              manager: manager,
              onEvent: (_) {},
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
