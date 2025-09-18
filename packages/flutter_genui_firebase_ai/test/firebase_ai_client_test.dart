// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:firebase_ai/firebase_ai.dart'
    show
        Candidate,
        Content,
        FinishReason,
        FunctionCall,
        GenerateContentResponse;
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'test_infra/utils.dart';

void main() {
  group('AiClient', () {
    late FakeGenerativeModel fakeModel;
    late FirebaseAiClient client;

    setUp(() {
      fakeModel = FakeGenerativeModel();
    });

    FirebaseAiClient createClient({List<AiTool> tools = const []}) {
      return FirebaseAiClient(
        modelCreator:
            ({required configuration, systemInstruction, tools, toolConfig}) {
              return fakeModel;
            },
        tools: tools,
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
            const FunctionCall('provideFinalOutput', {
              'output': {'key': 'value'},
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
            Content.model([const FunctionCall('myTool', {})]),
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
              const FunctionCall('provideFinalOutput', {
                'output': {'final': 'result'},
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
            Content.model([const FunctionCall('badTool', {})]),
            [],
            null,
            null,
            null,
          ),
        ], null),
        GenerateContentResponse([
          Candidate(
            Content.model([
              const FunctionCall('provideFinalOutput', {
                'output': {'final': 'result'},
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
          Content.model([const FunctionCall('unknownTool', {})]),
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
          Content.model([const firebase_ai.TextPart('unexpected text')]),
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
          Content.model([const FunctionCall('loopTool', {})]),
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

    test('logging callback is called', () async {
      final logMessages = <String>[];
      client = createClient();
      configureGenUiLogging(
        level: Level.ALL,
        logCallback: (_, message) => logMessages.add(message),
      );
      addTearDown(() {
        configureGenUiLogging(level: Level.OFF);
      });

      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([
            const FunctionCall('provideFinalOutput', {
              'output': {'key': 'value'},
            }),
          ]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      await client.generateContent<Map<String, Object?>>([
        UserMessage.text('user prompt'),
      ], S.object(properties: {'key': S.string()}));

      expect(logMessages, isNotEmpty);
    });

    test('activeRequests increments and decrements correctly', () async {
      client = createClient();

      fakeModel.response = GenerateContentResponse(
        [],
        firebase_ai.PromptFeedback(firebase_ai.BlockReason.other, '', []),
      );
      final future = client.generateText([]);
      expect(client.activeRequests.value, 1);

      await future;

      expect(client.activeRequests.value, 0);
    });

    test('activeRequests decrements on error', () async {
      client = createClient();

      final exception = Exception('Test Exception');
      fakeModel.exception = exception;

      expect(client.activeRequests.value, 0);

      final future = client.generateText([]);

      expect(client.activeRequests.value, 1);

      await expectLater(future, throwsA(isA<Exception>()));

      expect(client.activeRequests.value, 0);
    });
  });
}
