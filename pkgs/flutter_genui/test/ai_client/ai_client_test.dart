// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:firebase_ai/firebase_ai.dart'
    show Candidate, Content, FunctionCall, GenerateContentResponse;
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_genui/src/ai_client/ai_client.dart';
import 'package:flutter_genui/src/ai_client/firebase_ai_client.dart';
import 'package:flutter_genui/src/model/chat_message.dart';
import 'package:flutter_genui/src/model/tools.dart';
import 'package:flutter_genui/src/primitives/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../test_infra/utils.dart';

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

    test('generateText returns text data', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([
        Candidate(
          Content.model([firebase_ai.TextPart('response text')]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      final result = await client.generateText([
        UserMessage.text('user prompt'),
      ]);

      expect(result, 'response text');
    });

    test('generateText handles tool calls', () async {
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
            Content.model([firebase_ai.TextPart('final result')]),
            [],
            null,
            null,
            null,
          ),
        ], null),
      ];

      final result = await client.generateText([
        UserMessage.text('do something'),
      ]);

      expect(toolCalled, isTrue);
      expect(result, 'final result');
      expect(fakeModel.generateContentCallCount, 2);
    });

    test('generateText handles tool exception', () async {
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
            Content.model([firebase_ai.TextPart('final result')]),
            [],
            null,
            null,
            null,
          ),
        ], null),
      ];

      final result = await client.generateText([
        UserMessage.text('do something'),
      ]);

      expect(result, 'final result');
    });

    test('generateText returns empty string if no candidates', () async {
      client = createClient();
      fakeModel.response = GenerateContentResponse([], null);

      final result = await client.generateText([
        UserMessage.text('user prompt'),
      ]);

      expect(result, '');
    });

    test('generateText throws on unknown tool call', () async {
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
        () => client.generateText([UserMessage.text('user prompt')]),
        throwsA(isA<AiClientException>()),
      );
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
          Content.model([firebase_ai.TextPart('response')]),
          [],
          null,
          null,
          null,
        ),
      ], null);

      await client.generateText([UserMessage.text('user prompt')]);

      expect(logMessages, isNotEmpty);
    });
  });
}
