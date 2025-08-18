// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/ai_client.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:firebase_ai/firebase_ai.dart'
    show
        Candidate,
        Content,
        FinishReason,
        FirebaseAIException,
        FunctionCall,
        GenerateContentResponse;
import 'package:flutter_test/flutter_test.dart';

import 'test_infra/utils.dart';

void main() {
  group('AiClient', () {
    late FakeGenerativeModel fakeModel;
    late GeminiAiClient client;

    setUp(() {
      fakeModel = FakeGenerativeModel();
    });

    GeminiAiClient createClient({
      List<AiTool> tools = const [],
      AiClientLoggingCallback? loggingCallback,
    }) {
      return GeminiAiClient.test(
        modelCreator:
            ({required configuration, systemInstruction, tools, toolConfig}) {
              return fakeModel;
            },
        tools: tools,
        loggingCallback: loggingCallback,
      );
    }

    test('constructor throws on duplicate tool names', () {
      final tool1 = DynamicAiTool(
        name: 'tool',
        description: 'd',
        invokeFunction: (_) async => <String, Object?>{},
      );
      final tool2 = DynamicAiTool(
        name: 'tool',
        description: 'd',
        invokeFunction: (_) async => <String, Object?>{},
      );
      try {
        createClient(tools: [tool1, tool2]);
        fail('should throw');
      } catch (e) {
        expect(e, isA<AiClientException>());
        expect((e as AiClientException).message, contains('Duplicate tool(s)'));
      }
    });

    test('generateContent returns structured data', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([
            FunctionCall('provideFinalOutput', {
              'parameters': {
                'output': {'key': 'value'},
              },
            }),
          ]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      final result = await client.generateContent<Map<String, Object?>>([
        UserMessage.text('user prompt'),
      ], S.object(properties: {'key': S.string()}));

      expect(result, isNotNull);
      expect(result!['key'], 'value');
    });

    test('generateContent handles tool calls', () async {
      var toolCalled = false;
      final tool = DynamicAiTool(
        name: 'myTool',
        description: 'd',
        invokeFunction: (_) async {
          toolCalled = true;
          return {'status': 'ok'};
        },
        parameters: S.object(properties: {}),
      );
      client = createClient(tools: [tool]);

      fakeModel.responses = [
        // First response: model calls the tool
        GenerateContentResponse([
          Candidate(
            Content.model([FunctionCall('myTool', {})]),
            [],
            null,
            null,
            null,
          ),
        ], null),
        // Second response: model returns final output
        GenerateContentResponse([
          Candidate(
            Content.model([
              FunctionCall('provideFinalOutput', {
                'parameters': {
                  'output': {'final': 'result'},
                },
              }),
            ]),
            [],
            null,
            null,
            null,
          ),
        ], null),
      ];

      final result = await client.generateContent<Map<String, Object?>>([
        UserMessage.text('do something'),
      ], S.object(properties: {'final': S.string()}));

      expect(toolCalled, isTrue);
      expect(result, isNotNull);
      expect(result!['final'], 'result');
      expect(fakeModel.generateContentCallCount, 2);
    });

    test('generateContent retries on failure', () async {
      client = createClient();
      fakeModel.exception = FirebaseAIException('transient error');
      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([
            FunctionCall('provideFinalOutput', {
              'parameters': {
                'output': {'key': 'value'},
              },
            }),
          ]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      final result = await client.generateContent<Map<String, Object?>>([
        UserMessage.text('user prompt'),
      ], S.object(properties: {'key': S.string()}));

      expect(result, isNotNull);
      expect(fakeModel.generateContentCallCount, 2);
    });

    test('generateContent handles tool exception', () async {
      final tool = DynamicAiTool(
        name: 'badTool',
        description: 'd',
        invokeFunction: (_) async => throw Exception('tool error'),
        parameters: S.object(properties: {}),
      );
      client = createClient(tools: [tool]);

      fakeModel.responses = [
        GenerateContentResponse([
          Candidate(
            Content.model([FunctionCall('badTool', {})]),
            [],
            null,
            null,
            null,
          ),
        ], null),
        GenerateContentResponse([
          Candidate(
            Content.model([
              FunctionCall('provideFinalOutput', {
                'parameters': {
                  'output': {'final': 'result'},
                },
              }),
            ]),
            [],
            null,
            null,
            null,
          ),
        ], null),
      ];

      final result = await client.generateContent<Map<String, Object?>>([
        UserMessage.text('do something'),
      ], S.object(properties: {'final': S.string()}));

      expect(result, isNotNull);
      expect(result!['final'], 'result');
    });

    test('generateContent returns null if no candidates', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([], null);

      final result = await client.generateContent<Map<String, Object?>>([
        UserMessage.text('user prompt'),
      ], S.object(properties: {}));

      expect(result, isNull);
    });

    test('generateContent throws on unknown tool call', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([FunctionCall('unknownTool', {})]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      expect(
        () => client.generateContent<Map<String, Object?>>([
          UserMessage.text('user prompt'),
        ], S.object(properties: {})),
        throwsA(isA<AiClientException>()),
      );
    });

    test('generateContent returns null on direct text response', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([firebase_ai.TextPart('unexpected text')]),
          [],
          null,
          FinishReason.stop,
          null,
        ),
      ], null);

      final result = await client.generateContent<Map<String, Object?>>([
        UserMessage.text('user prompt'),
      ], S.object(properties: {}));

      expect(result, isNull);
    });

    test('generateContent returns null on max tool cycles', () async {
      final tool = DynamicAiTool(
        name: 'loopTool',
        description: 'd',
        invokeFunction: (_) async => <String, Object?>{},
        parameters: S.object(properties: {}),
      );
      client = createClient(tools: [tool]);

      // Make the model call the tool repeatedly
      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([FunctionCall('loopTool', {})]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      final result = await client.generateContent<Map<String, Object?>>([
        UserMessage.text('user prompt'),
      ], S.object(properties: {}));

      expect(result, isNull);
    });

    test('switchModel updates the current model', () {
      client = createClient();
      final newModel = GeminiModel(GeminiModelType.pro);
      client.switchModel(newModel);
      expect(client.model.value, newModel);
    });

    test('constructor throws on duplicate tool fullNames', () {
      final tool1 = DynamicAiTool(
        name: 'tool',
        prefix: 'prefix',
        description: 'd',
        invokeFunction: (_) async => <String, Object?>{},
      );
      final tool2 = DynamicAiTool(
        name: 'tool',
        prefix: 'prefix',
        description: 'd',
        invokeFunction: (_) async => <String, Object?>{},
      );
      expect(
        () => createClient(tools: [tool1, tool2]),
        throwsA(
          isA<AiClientException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate tool'),
          ),
        ),
      );
    });

    test('system instruction is passed to model creator', () async {
      String? passedSystemInstruction;
      client = GeminiAiClient.test(
        systemInstruction: 'Be a helpful assistant.',
        modelCreator:
            ({required configuration, systemInstruction, tools, toolConfig}) {
              passedSystemInstruction = systemInstruction?.parts
                  .whereType<firebase_ai.TextPart>()
                  .first
                  .text;
              return fakeModel;
            },
      );

      fakeModel.response = GenerateContentResponse([], null);
      await client.generateContent<Map<String, Object?>>(
        [],
        S.object(properties: {}),
      );

      expect(passedSystemInstruction, 'Be a helpful assistant.');
    });
  });
}
