// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'package:genai_primitives/genai_primitives.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main({void Function(Object?)? output}) {
  void print(Object? object) {
    if (output != null) {
      output(object);
    } else {
      core.print(object);
    }
  }

  print('--- GenAI Primitives Example ---');

  // 1. Define a Tool
  final ToolDefinition<Object> getWeatherTool = ToolDefinition(
    name: 'get_weather',
    description: 'Get the current weather for a location',
    inputSchema: Schema.object(
      properties: {
        'location': Schema.string(
          description: 'The city and state, e.g. San Francisco, CA',
        ),
        'unit': Schema.string(
          enumValues: ['celsius', 'fahrenheit'],
          description: 'The unit of temperature',
        ),
      },
      required: ['location'],
    ),
  );

  print('\n[Tool Definition]');
  print(const JsonEncoder.withIndent('  ').convert(getWeatherTool.toJson()));

  // 2. Create a conversation history
  final history = <ChatMessage>[
    // System message
    ChatMessage.system(
      'You are a helpful weather assistant. '
      'Use the get_weather tool when needed.',
    ),

    // User message asking for weather
    ChatMessage.user('What is the weather in London?'),
  ];

  print('\n[Initial Conversation]');
  for (final msg in history) {
    print('${msg.role.name}: ${msg.text}');
  }

  // 3. Simulate Model Response with Tool Call
  final modelResponse = ChatMessage.model(
    '', // Empty text for tool call
    parts: [
      const TextPart('Thinking: User wants weather for London...'),
      const ToolPart.call(
        callId: 'call_123',
        toolName: 'get_weather',
        arguments: {'location': 'London', 'unit': 'celsius'},
      ),
    ],
  );
  history.add(modelResponse);

  print('\n[Model Response with Tool Call]');
  if (modelResponse.hasToolCalls) {
    for (final ToolPart call in modelResponse.toolCalls) {
      print('Tool Call: ${call.toolName}(${call.arguments})');
    }
  }

  // 4. Simulate Tool Execution & Result
  final toolResult = ChatMessage.user(
    '', // User role is typically used for tool results in many APIs
    parts: [
      const ToolPart.result(
        callId: 'call_123',
        toolName: 'get_weather',
        result: {'temperature': 15, 'condition': 'Cloudy'},
      ),
    ],
  );
  history.add(toolResult);

  print('\n[Tool Result]');
  print('Result: ${toolResult.toolResults.first.result}');

  // 5. Simulate Final Model Response with Data (e.g. an image generated or
  //    returned)
  final finalResponse = ChatMessage.model(
    'Here is a chart of the weather trend:',
    parts: [
      DataPart(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]), // Fake PNG header
        mimeType: 'image/png',
        name: 'weather_chart.png',
      ),
    ],
  );
  history.add(finalResponse);

  print('\n[Final Model Response with Data]');
  print('Text: ${finalResponse.text}');
  if (finalResponse.parts.any((p) => p is DataPart)) {
    final DataPart dataPart = finalResponse.parts.whereType<DataPart>().first;
    print(
      'Attachment: ${dataPart.name} '
      '(${dataPart.mimeType}, ${dataPart.bytes.length} bytes)',
    );
  }

  // 6. Demonstrate JSON serialization of the whole history
  print('\n[Full History JSON]');
  print(
    const JsonEncoder.withIndent(
      '  ',
    ).convert(history.map((m) => m.toJson()).toList()),
  );
}
