// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/ai_client/generative_model_interface.dart';
import 'package:flutter_genui/src/ai_client/tools.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/main.dart';

class MockLlmConnection implements LlmConnection {
  final Completer<Map<String, Object?>> _completer = Completer();
  final StreamController<bool> _loadingStreamController =
      StreamController<bool>.broadcast();

  @override
  Future<T?> generateContent<T extends Object>(
    List<Content> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
    Content? systemInstruction,
  }) async {
    _loadingStreamController.add(true);
    final result = await _completer.future;
    _loadingStreamController.add(false);
    return result as T?;
  }

  void complete() {
    _completer.complete({'responseText': 'Test response'});
  }
}

void main() {
  testWidgets('Loading scrim shows during inference', (
    WidgetTester tester,
  ) async {
    final mockLlmConnection = MockLlmConnection();
    final aiClient = AiClient.test(
      modelCreator:
          ({
            required AiClient configuration,
            Content? systemInstruction,
            List<Tool>? tools,
            ToolConfig? toolConfig,
          }) {
            return MockGenerativeModel(mockLlmConnection);
          },
    );

    await tester.pumpWidget(MaterialApp(home: MyHomePage(aiClient: aiClient)));

    // Verify the loading scrim is not visible initially
    expect(find.byType(LoadingScrim), findsOneWidget);
    final loadingScrim = tester.widget<LoadingScrim>(find.byType(LoadingScrim));
    expect(loadingScrim.isLoading, isFalse);

    // Enter a prompt and send it
    await tester.enterText(find.byType(TextField), 'test prompt');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify the loading scrim is now visible
    final loadingScrimInProgress = tester.widget<LoadingScrim>(
      find.byType(LoadingScrim),
    );
    expect(loadingScrimInProgress.isLoading, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the inference
    mockLlmConnection.complete();
    await tester.pump();

    // Verify the loading scrim is hidden again
    final loadingScrimFinished = tester.widget<LoadingScrim>(
      find.byType(LoadingScrim),
    );
    expect(loadingScrimFinished.isLoading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class MockGenerativeModel implements GenerativeModelInterface {
  final MockLlmConnection _llmConnection;

  MockGenerativeModel(this._llmConnection);

  @override
  Future<GenerateContentResponse> generateContent(
    Iterable<Content> content,
  ) async {
    final result = await _llmConnection.generateContent(
      content.toList(),
      Schema.object(properties: {}),
    );
    return GenerateContentResponse([
      Candidate(Content.text(result.toString()), null, null, null, null),
    ], null);
  }
}
