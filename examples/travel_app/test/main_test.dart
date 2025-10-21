// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/main.dart' as app;

void main() {
  testWidgets('Can send a prompt', (WidgetTester tester) async {
    final mockAiClient = FakeAiClient();
    // The main app expects a JSON response from generateContent.
    mockAiClient.response = {'result': true};
    await tester.pumpWidget(app.TravelApp(aiClient: mockAiClient));

    await tester.enterText(find.byType(TextField), 'test prompt');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Wait for the AI client to be called.
    await mockAiClient.responseCompleter.future;

    expect(mockAiClient.generateContentCallCount, 1);
    final lastMessage = mockAiClient.lastConversation.last;
    expect(lastMessage, isA<UserMessage>());
    expect(
      ((lastMessage as UserMessage).parts.last as TextPart).text,
      'test prompt',
    );
  });

  testWidgets('Shows spinner while thinking', (WidgetTester tester) async {
    final mockAiClient = FakeAiClient();
    final completer = Completer<dynamic>();
    mockAiClient.generateContentFuture = completer.future;
    await tester.pumpWidget(app.TravelApp(aiClient: mockAiClient));

    await tester.enterText(find.byType(TextField), 'test prompt');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // The spinner should be showing.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.send), findsNothing);
    var textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);

    // Complete the response.
    completer.complete({'result': true});
    await tester.pumpAndSettle();

    // The spinner should be gone.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.send), findsOneWidget);
    textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isTrue);
  });
}
