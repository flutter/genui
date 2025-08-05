// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/ai_client/ai_client.dart';
import 'package:flutter_genui/src/ai_client/tools.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_infra/utils.dart';

void main() {
  group('AiClient', () {
    late FakeGenerativeModel fakeModel;
    late AiClient client;

    setUp(() {
      fakeModel = FakeGenerativeModel();
    });

    AiClient createClient({
      List<AiTool> tools = const [],
      AiClientLoggingCallback? loggingCallback,
    }) {
      return AiClient.test(
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

      final result = await client.generateContent<Map<String, Object?>>(
        [],
        Schema.object(properties: {'key': Schema.string()}),
      );

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
        parameters: Schema.object(properties: {}),
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
        Content.text('do something'),
      ], Schema.object(properties: {'final': Schema.string()}));

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

      final result = await client.generateContent<Map<String, Object?>>(
        [],
        Schema.object(properties: {'key': Schema.string()}),
      );

      expect(result, isNotNull);
      expect(fakeModel.generateContentCallCount, 2);
    });

    test('generateContent handles tool exception', () async {
      final tool = DynamicAiTool(
        name: 'badTool',
        description: 'd',
        invokeFunction: (_) async => throw Exception('tool error'),
        parameters: Schema.object(properties: {}),
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
        Content.text('do something'),
      ], Schema.object(properties: {'final': Schema.string()}));

      expect(result, isNotNull);
      expect(result!['final'], 'result');
    });

    test('generateContent returns null if no candidates', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([], null);

      final result = await client.generateContent<Map<String, Object?>>(
        [],
        Schema.object(properties: {}),
      );

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
        () => client.generateContent<Map<String, Object?>>(
          [],
          Schema.object(properties: {}),
        ),
        throwsA(isA<AiClientException>()),
      );
    });

    test('generateContent returns null on direct text response', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([TextPart('unexpected text')]),
          [],
          null,
          FinishReason.stop,
          null,
        ),
      ], null);

      final result = await client.generateContent<Map<String, Object?>>(
        [],
        Schema.object(properties: {}),
      );

      expect(result, isNull);
    });

    test('generateContent returns null on max tool cycles', () async {
      final tool = DynamicAiTool(
        name: 'loopTool',
        description: 'd',
        invokeFunction: (_) async => <String, Object?>{},
        parameters: Schema.object(properties: {}),
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

      final result = await client.generateContent<Map<String, Object?>>(
        [],
        Schema.object(properties: {}),
      );

      expect(result, isNull);
    });

    test('logging callback is called', () async {
      final logMessages = <String>[];
      client = createClient(
        loggingCallback: (severity, message) {
          logMessages.add(message);
        },
      );

      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([
            FunctionCall('provideFinalOutput', {
              'output': {'key': 'value'},
            }),
          ]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      await client.generateContent<Map<String, Object?>>(
        [],
        Schema.object(properties: {'key': Schema.string()}),
      );

      expect(logMessages, isNotEmpty);
    });
  });
}
