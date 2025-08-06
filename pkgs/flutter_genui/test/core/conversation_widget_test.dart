// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/core/conversation_widget.dart';
import 'package:flutter_genui/src/model/catalog.dart';
import 'package:flutter_genui/src/model/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationWidget', () {
    testWidgets('renders a list of messages', (WidgetTester tester) async {
      final messages = [
        const UserPrompt(text: 'Hello'),
        const SystemMessage(text: 'Hi there!'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationWidget(
              messages: messages,
              catalog: const Catalog([]),
              onEvent: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
    });
  });
}
