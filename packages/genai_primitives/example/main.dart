// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:genai_primitives/genai_primitives.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

enum Role { system, user, model }

class ChatMessage {
  final Role role;
  final Message content;

  const ChatMessage({required this.role, required this.content});

  const ChatMessage.system(Message content)
    : this(role: Role.system, content: content);

  const ChatMessage.user(Message content)
    : this(role: Role.user, content: content);

  const ChatMessage.model(Message content)
    : this(role: Role.model, content: content);
}

void main({void Function(Object? object) output = print}) {
  output('--- GenAI Primitives Example ---');

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

  output('\n[Tool Definition]');
  output(const JsonEncoder.withIndent('  ').convert(getWeatherTool.toJson()));

  // 2. Create a conversation history
  final history = <ChatMessage>[
    // System message
    ChatMessage.system(
      Message(
        'You are a helpful weather assistant. '
        'Use the get_weather tool when needed.',
      ),
    ),

    // User message asking for weather
    ChatMessage.user(Message('What is the weather in London?')),
  ];

  output('\n[Initial Conversation]');
  for (final msg in history) {
    output('${msg.role.name}: ${msg.content.text}');
  }

  // 3. Simulate Model Response with Tool Call
  final modelResponse = ChatMessage.model(
    Message(
      '', // Empty text for tool call
      parts: [
        const TextPart('Thinking: User wants weather for London...'),
        const ToolPart.call(
          callId: 'call_123',
          toolName: 'get_weather',
          arguments: {'location': 'London', 'unit': 'celsius'},
        ),
      ],
    ),
  );
  history.add(modelResponse);

  output('\n[Model Response with Tool Call]');
  if (modelResponse.content.hasToolCalls) {
    for (final ToolPart call in modelResponse.content.toolCalls) {
      output('Tool Call: ${call.toolName}(${call.arguments})');
    }
  }

  // 4. Simulate Tool Execution & Result
  final toolResult = ChatMessage.user(
    Message(
      '', // User role is typically used for tool results in many APIs
      parts: [
        const ToolPart.result(
          callId: 'call_123',
          toolName: 'get_weather',
          result: {'temperature': 15, 'condition': 'Cloudy'},
        ),
      ],
    ),
  );
  history.add(toolResult);

  output('\n[Tool Result]');
  output('Result: ${toolResult.content.toolResults.first.result}');

  // 5. Simulate Final Model Response with Data (e.g. an image generated or
  //    returned)
  final finalResponse = ChatMessage.model(
    Message(
      'Here is a chart of the weather trend:',
      parts: [
        DataPart(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]), // Fake PNG header
          mimeType: 'image/png',
          name: 'weather_chart.png',
        ),
      ],
    ),
  );
  history.add(finalResponse);

  output('\n[Final Model Response with Data]');
  output('Text: ${finalResponse.content.text}');
  if (finalResponse.content.parts.any((p) => p is DataPart)) {
    final DataPart dataPart = finalResponse.content.parts
        .whereType<DataPart>()
        .first;
    output(
      'Attachment: ${dataPart.name} '
      '(${dataPart.mimeType}, ${dataPart.bytes.length} bytes)',
    );
  }

  // 6. Demonstrate JSON serialization of the whole history
  output('\n[Full History JSON]');
  output(
    const JsonEncoder.withIndent(
      '  ',
    ).convert(history.map((m) => m.content.toJson()).toList()),
  );
}
