// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencer): Remove this dependency on firebase_ai once we have generic
// replacements for TextPart.
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/main.dart' as app;

import 'test_infra/fake_ai_client.dart';

void main() {
  testWidgets('Can switch models', (WidgetTester tester) async {
    final mockAiClient = FakeAiClient();
    await tester.pumpWidget(app.TravelApp(aiClient: mockAiClient));

    expect(find.text('mock1'), findsNothing);
    expect(find.text('mock2'), findsNothing);

    await tester.tap(find.byIcon(Icons.psychology_outlined));
    await tester.pumpAndSettle();

    expect(find.text('mock1'), findsOneWidget);
    expect(find.text('mock2'), findsOneWidget);

    await tester.tap(find.text('mock2'));
    await tester.pumpAndSettle();

    expect(mockAiClient.model.value.displayName, 'mock2');
  });

  testWidgets('Can send a prompt', (WidgetTester tester) async {
    final mockAiClient = FakeAiClient();
    await tester.pumpWidget(app.TravelApp(aiClient: mockAiClient));

    await tester.enterText(find.byType(TextField), 'test prompt');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Wait for the AI client to be called.
    await mockAiClient.responseFinished;

    expect(mockAiClient.generateContentCallCount, 1);
    expect(
      (mockAiClient.lastConversation.last.parts.last as TextPart).text,
      'test prompt',
    );
  });
}
