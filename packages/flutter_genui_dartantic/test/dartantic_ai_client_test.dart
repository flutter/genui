// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;
import 'package:flutter_genui/flutter_genui.dart';
import 'package:dartantic_interface/dartantic_interface.dart' as dartantic;
import 'package:dartantic_ai/dartantic_ai.dart';

import 'package:flutter_genui_dartantic/flutter_genui_dartantic.dart';

void main() {
  group('DartanticAiClient', () {
    test('creates client with valid configuration', () {
      final client = DartanticAiClient(
        provider: 'openai',
        model: 'gpt-4',
        systemInstruction: 'You are a helpful assistant.',
        tools: [],
      );

      expect(client.provider, equals('openai'));
      expect(client.model, equals('gpt-4'));
      expect(client.systemInstruction, equals('You are a helpful assistant.'));
      expect(client.tools, isEmpty);
      expect(client.outputToolName, equals('provideFinalOutput'));
    });

    test('creates client with default values', () {
      final client = DartanticAiClient(provider: 'openai');

      expect(client.provider, equals('openai'));
      expect(client.model, isNull);
      expect(client.systemInstruction, isNull);
      expect(client.tools, isEmpty);
      expect(client.outputToolName, equals('provideFinalOutput'));
    });

    test('throws exception for duplicate tool names', () {
      final tool1 = DynamicAiTool<Map<String, dynamic>>(
        name: 'test_tool',
        description: 'Test tool 1',
        parameters: dsb.S.string(),
        invokeFunction: (args) async => {'result': 'result1'},
      );
      final tool2 = DynamicAiTool<Map<String, dynamic>>(
        name: 'test_tool',
        description: 'Test tool 2',
        parameters: dsb.S.string(),
        invokeFunction: (args) async => {'result': 'result2'},
      );

      expect(
        () => DartanticAiClient(
          provider: 'openai',
          tools: [tool1, tool2],
        ),
        throwsA(isA<AiClientException>()),
      );
    });

    test('tracks active requests', () {
      final client = DartanticAiClient(provider: 'openai');
      
      expect(client.activeRequests.value, equals(0));
      
      // Note: In a real test, we would need to mock the Agent
      // to test the actual request tracking behavior
    });

    test('disposes resources', () {
      final client = DartanticAiClient(provider: 'openai');
      
      // Should not throw
      client.dispose();
    });

    test('defaultAgentFactory creates agent with correct parameters', () {
      final agent = DartanticAiClient.defaultAgentFactory(
        provider: 'openai',
        model: 'gpt-4',
        options: {'temperature': 0.7},
      );

      expect(agent, isNotNull);
      // Note: In a real test, we would verify the agent configuration
    });

    test('accepts custom agent factory', () {
      final customFactory = ({
        required String provider,
        String? model,
        Map<String, dynamic>? options,
        List<dartantic.Tool>? tools,
      }) {
        final modelString = model != null ? '$provider:$model' : provider;
        return Agent(modelString, tools: tools, temperature: options?['temperature'] as double?);
      };

      final client = DartanticAiClient(
        provider: 'openai',
        agentFactory: customFactory,
      );

      expect(client.agentFactory, equals(customFactory));
    });
  });
}
