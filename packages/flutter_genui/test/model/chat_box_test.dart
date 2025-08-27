// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/model/chat_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatBox', () {
    late ChatBoxController controller;
    String? lastInput;

    setUp(() {
      lastInput = null;
      controller = ChatBoxController((input) {
        lastInput = input;
      });
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> pumpChatBox(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ChatBox(controller))),
      );
    }

    testWidgets('renders TextField and Send button', (tester) async {
      await pumpChatBox(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('does not submit when input is empty', (tester) async {
      await pumpChatBox(tester);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(lastInput, isNull);
    });

    testWidgets('submits text when send button is tapped', (tester) async {
      await pumpChatBox(tester);
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(lastInput, 'Hello');
      expect(find.text('Hello'), findsNothing); // text field should be cleared
    });

    testWidgets('submits text on keyboard action', (tester) async {
      await pumpChatBox(tester);
      await tester.enterText(find.byType(TextField), 'Hello again');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(lastInput, 'Hello again');
      expect(find.text('Hello again'), findsNothing);
    });

    testWidgets('shows progress indicator when waiting', (tester) async {
      await pumpChatBox(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      controller.setRequested();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.setResponded();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ChatBoxController', () {
    test('isWaiting updates correctly', () {
      final controller = ChatBoxController((_) {});
      final notifications = <bool>[];
      controller.isWaiting.addListener(() {
        notifications.add(controller.isWaiting.value);
      });

      expect(controller.isWaiting.value, isFalse);

      controller.setRequested();
      expect(controller.isWaiting.value, isTrue);
      expect(notifications, [true]);

      controller.setResponded();
      expect(controller.isWaiting.value, isFalse);
      expect(notifications, [true, false]);

      controller.dispose();
    });
  });
}
