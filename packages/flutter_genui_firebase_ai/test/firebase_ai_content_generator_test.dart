// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_genui/flutter_genui.dart' as genui;
import 'package:flutter_genui_firebase_ai/src/firebase_ai_content_generator.dart';
import 'package:flutter_genui_firebase_ai/src/gemini_generative_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

void main() {
  group('FirebaseAiContentGenerator', () {
    test('isProcessing is true during request', () async {
      final generator = FirebaseAiContentGenerator(
        catalog: const genui.Catalog({}),
        modelCreator:
            ({required configuration, systemInstruction, tools, toolConfig}) {
              return FakeGeminiGenerativeModel([
                GenerateContentResponse([
                  Candidate(
                    Content.model([const TextPart('Hello')]),
                    [],
                    null,
                    FinishReason.stop,
                    '',
                  ),
                ], null),
              ]);
            },
      );

      expect(generator.isProcessing.value, isFalse);
      final future = generator.sendRequest([
        genui.UserMessage([const genui.TextPart('Hi')]),
      ]);
      expect(generator.isProcessing.value, isTrue);
      await future;
      expect(generator.isProcessing.value, isFalse);
    });

    test('can call a tool and return a result', () async {
      final generator = FirebaseAiContentGenerator(
        catalog: const genui.Catalog({}),
        additionalTools: [
          genui.DynamicAiTool<Map<String, Object?>>(
            name: 'testTool',
            description: 'A test tool',
            parameters: dsb.Schema.object(),
            invokeFunction: (args) async => {'result': 'tool result'},
          ),
        ],
        modelCreator:
            ({required configuration, systemInstruction, tools, toolConfig}) {
              return FakeGeminiGenerativeModel([
                GenerateContentResponse([
                  Candidate(
                    Content.model([const FunctionCall('testTool', {})]),
                    [],
                    null,
                    FinishReason.stop,
                    '',
                  ),
                ], null),
                GenerateContentResponse([
                  Candidate(
                    Content.model([const TextPart('Tool called')]),
                    [],
                    null,
                    FinishReason.stop,
                    '',
                  ),
                ], null),
              ]);
            },
      );

      final hi = genui.UserMessage([const genui.TextPart('Hi')]);
      final completer = Completer<String>();
      unawaited(generator.textResponseStream.first.then(completer.complete));
      await generator.sendRequest([hi]);
      final response = await completer.future;
      expect(response, 'Tool called');
    });

    test('returns a simple text response', () async {
      final generator = FirebaseAiContentGenerator(
        catalog: const genui.Catalog({}),
        modelCreator:
            ({required configuration, systemInstruction, tools, toolConfig}) {
              return FakeGeminiGenerativeModel([
                GenerateContentResponse([
                  Candidate(
                    Content.model([const TextPart('Hello')]),
                    [],
                    null,
                    FinishReason.stop,
                    '',
                  ),
                ], null),
              ]);
            },
      );

      final hi = genui.UserMessage([const genui.TextPart('Hi')]);
      final completer = Completer<String>();
      unawaited(generator.textResponseStream.first.then(completer.complete));
      await generator.sendRequest([hi]);
      final response = await completer.future;
      expect(response, 'Hello');
    });
  });
}

class FakeGeminiGenerativeModel implements GeminiGenerativeModelInterface {
  FakeGeminiGenerativeModel(this.responses);

  final List<GenerateContentResponse> responses;
  int callCount = 0;

  @override
  Future<GenerateContentResponse> generateContent(Iterable<Content> content) {
    return Future.delayed(Duration.zero, () => responses[callCount++]);
  }
}
