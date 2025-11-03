// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_genui/test/fake_content_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/main.dart' as app;

void main() {
  testWidgets('Can send a prompt', (WidgetTester tester) async {
    final mockContentGenerator = FakeContentGenerator();
    await tester.pumpWidget(
      app.TravelApp(contentGenerator: mockContentGenerator),
    );

    await tester.enterText(find.byType(TextField), 'test prompt');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    mockContentGenerator.addTextResponse('AI response');
    await tester.pumpAndSettle();

    expect(mockContentGenerator.sendRequestCallCount, 1);
    expect(find.text('test prompt'), findsOneWidget);
    expect(find.text('AI response'), findsOneWidget);
  });

  testWidgets('Shows spinner while thinking', (WidgetTester tester) async {
    final mockContentGenerator = FakeContentGenerator();
    final completer = Completer<void>();
    mockContentGenerator.sendRequestCompleter = completer;
    await tester.pumpWidget(
      app.TravelApp(contentGenerator: mockContentGenerator),
    );

    await tester.enterText(find.byType(TextField), 'test prompt');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    // The spinner should be showing.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.send), findsNothing);
    var textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);

    // Complete the response.
    completer.complete();
    mockContentGenerator.addTextResponse('AI response');
    await tester.pumpAndSettle();

    // The spinner should be gone.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.send), findsOneWidget);
    textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isTrue);
    expect(find.text('AI response'), findsOneWidget);
  });
}
