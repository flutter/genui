// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/turn.dart';
import 'package:travel_app/src/widgets/conversation.dart';

void main() {
  group('Conversation', () {
    late GenUiManager manager;

    setUp(() {
      manager = GenUiManager(catalog: coreCatalog);
    });

    testWidgets('renders a list of messages', (WidgetTester tester) async {
      final definition = UiDefinition.fromMap({
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
      });
      final messages = [
        const UserTurn('Hello'),
        GenUiTurn(
          surfaceId: 's1',
          definition: definition,
        ),
      ];
      manager.addOrUpdateSurface(
        's1',
        definition.toMap(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Conversation(
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
        const UserTurn('Hello'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Conversation(
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
      final definition = UiDefinition.fromMap({
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
      });
      final messages = [
        GenUiTurn(
          surfaceId: 's1',
          definition: definition,
        ),
      ];
      manager.addOrUpdateSurface('s1', definition.toMap());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Conversation(
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
  });
}
