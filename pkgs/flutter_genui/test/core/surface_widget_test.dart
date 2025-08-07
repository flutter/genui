// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/core/core_catalog.dart';
import 'package:flutter_genui/src/core/widgets/conversation_widget.dart';
import 'package:flutter_genui/src/model/chat_message.dart';
import 'package:flutter_genui/src/model/surface_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationWidget', () {
    testWidgets('renders UserPrompt correctly', (WidgetTester tester) async {
      final messages = [const UserPrompt(text: 'Hello')];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              catalog: coreCatalog,
              onEvent: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders SystemMessage correctly', (WidgetTester tester) async {
      final messages = [const SystemMessage(text: 'Hi there')];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              catalog: coreCatalog,
              onEvent: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Hi there'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    });

    testWidgets('renders UiResponse correctly', (WidgetTester tester) async {
      final messages = [
        UiResponse(
          surfaceId: 's1',
          definition: {
            'surfaceId': 's1',
            'root': 'root',
            'widgets': [
              {
                'id': 'root',
                'widget': {
                  'text': {'text': 'UI Content'},
                },
              },
            ],
          },
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              catalog: coreCatalog,
              onEvent: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(SurfaceWidget), findsOneWidget);
      expect(find.text('UI Content'), findsOneWidget);
    });

    testWidgets('uses custom userPromptBuilder', (WidgetTester tester) async {
      final messages = [const UserPrompt(text: 'Hello')];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              catalog: coreCatalog,
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

    testWidgets('uses custom systemMessageBuilder', (
      WidgetTester tester,
    ) async {
      final messages = [const SystemMessage(text: 'Error')];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              catalog: coreCatalog,
              onEvent: (_) {},
              systemMessageBuilder: (context, message) =>
                  const Text('Custom System Message'),
            ),
          ),
        ),
      );
      expect(find.text('Custom System Message'), findsOneWidget);
      expect(find.text('Error'), findsNothing);
    });
  });
}
