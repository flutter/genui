// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_genui/src/ai_client/ai_client.dart';
import 'package:flutter_genui/src/ai_client/gemini_ai_client.dart';
import 'package:flutter_genui/src/ai_client/gemini_generative_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockGeminiGenerativeModel extends Mock
    implements GeminiGenerativeModelInterface {}

void main() {
  group('GeminiAiClient', () {
    test('activeRequests increments and decrements correctly', () async {
      final mockModel = MockGeminiGenerativeModel();
      final client = GeminiAiClient(
        modelCreator:
            ({
              required GeminiAiClient configuration,
              Content? systemInstruction,
              List<Tool>? tools,
              ToolConfig? toolConfig,
            }) => mockModel,
      );

      final completer = Completer<GenerateContentResponse>();
      when(mockModel.generateContent(any)).thenAnswer((_) => completer.future);

      expect(client.activeRequests.value, 0);

      final future = client.generateText([]);

      expect(client.activeRequests.value, 1);

      completer.complete(
        GenerateContentResponse([], PromptFeedback(BlockReason.other, '', [])),
      );

      await future;

      expect(client.activeRequests.value, 0);
    });

    test('activeRequests decrements on error', () async {
      final mockModel = MockGeminiGenerativeModel();
      final client = GeminiAiClient(
        modelCreator:
            ({
              required GeminiAiClient configuration,
              Content? systemInstruction,
              List<Tool>? tools,
              ToolConfig? toolConfig,
            }) => mockModel,
      );

      final completer = Completer<GenerateContentResponse>();
      when(mockModel.generateContent(any)).thenAnswer((_) => completer.future);

      expect(client.activeRequests.value, 0);

      final future = client.generateText([]);

      expect(client.activeRequests.value, 1);

      final exception = Exception('Test Exception');
      completer.completeError(exception);

      await expectLater(future, throwsA(isA<AiClientException>()));

      expect(client.activeRequests.value, 0);
    });
  });
}
