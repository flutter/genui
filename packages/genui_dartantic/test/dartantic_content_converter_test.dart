// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui_dartantic/genui_dartantic.dart';

void main() {
  group('DartanticContentConverter', () {
    late DartanticContentConverter converter;

    setUp(() {
      converter = DartanticContentConverter();
    });

    group('toPromptAndParts', () {
      test('converts UserMessage with text to prompt string', () {
        final message = genui.UserMessage.text('Hello, world!');

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, 'Hello, world!');
        // Text parts are excluded from parts to avoid duplication (text is in
        // prompt)
        expect(result.parts, isEmpty);
      });

      test('converts UserMessage with multiple text parts', () {
        final message = genui.UserMessage([
          const genui.TextPart('First part'),
          const genui.TextPart('Second part'),
        ]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, 'First part\nSecond part');
        // Text parts are excluded from parts to avoid duplication (text is in
        // prompt)
        expect(result.parts, isEmpty);
      });

      test('converts UserUiInteractionMessage to prompt string', () {
        final message = genui.UserUiInteractionMessage.text('UI interaction');

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, 'UI interaction');
      });

      test('converts AiTextMessage to prompt string', () {
        final message = genui.AiTextMessage.text('AI response');

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, 'AI response');
      });

      test('converts InternalMessage to prompt string', () {
        const message = genui.InternalMessage('System instruction');

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, 'System instruction');
        // InternalMessage returns empty parts (text is in prompt only)
        expect(result.parts, isEmpty);
      });

      test('handles ToolResponseMessage', () {
        const message = genui.ToolResponseMessage([
          genui.ToolResultPart(callId: 'call1', result: '{"status": "ok"}'),
        ]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, contains('ToolResult(call1)'));
        expect(result.parts, isNotEmpty);
      });

      test('handles DataPart in message', () {
        final message = genui.UserMessage([
          const genui.TextPart('Check this data:'),
          const genui.DataPart({'key': 'value'}),
        ]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, contains('Check this data:'));
        expect(result.prompt, contains('Data:'));
        expect(
          result.parts.whereType<dartantic.DataPart>().length,
          greaterThanOrEqualTo(1),
        );
      });

      test('handles ImagePart with URL in message', () {
        final message = genui.UserMessage([
          const genui.TextPart('Look at this image:'),
          genui.ImagePart.fromUrl(
            Uri.parse('https://example.com/image.png'),
            mimeType: 'image/png',
          ),
        ]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, contains('Look at this image:'));
        expect(
          result.prompt,
          contains('Image at https://example.com/image.png'),
        );
        expect(result.parts.whereType<dartantic.LinkPart>(), isNotEmpty);
      });

      test('handles ThinkingPart in message', () {
        final message = genui.AiTextMessage([
          const genui.ThinkingPart('Let me think about this...'),
          const genui.TextPart('Here is my answer.'),
        ]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, contains('Thinking: Let me think about this...'));
        expect(result.prompt, contains('Here is my answer.'));
      });

      test('includes ToolCallPart in prompt', () {
        final message = genui.AiTextMessage([
          const genui.TextPart('Calling a tool'),
          const genui.ToolCallPart(
            id: 'call1',
            toolName: 'test_tool',
            arguments: {'arg': 'value'},
          ),
        ]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, contains('ToolCall(test_tool)'));
        expect(result.parts.whereType<dartantic.ToolPart>(), isNotEmpty);
      });

      test('includes ToolResultPart in prompt', () {
        final message = genui.AiTextMessage([
          const genui.TextPart('Got result'),
          const genui.ToolResultPart(callId: 'call1', result: '{}'),
        ]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, contains('ToolResult(call1)'));
        expect(result.parts.whereType<dartantic.ToolPart>(), isNotEmpty);
      });

      test('handles empty message parts', () {
        final message = genui.UserMessage([]);

        final ({String prompt, List<dartantic.Part> parts}) result = converter
            .toPromptAndParts(message);

        expect(result.prompt, '');
      });
    });

    group('toHistory', () {
      test('returns empty list for null history', () {
        final List<dartantic.ChatMessage> result = converter.toHistory(null);

        expect(result, isEmpty);
      });

      test('returns empty list for empty history', () {
        final List<dartantic.ChatMessage> result = converter.toHistory([]);

        expect(result, isEmpty);
      });

      test('includes system instruction as first message', () {
        final List<dartantic.ChatMessage> result = converter.toHistory(
          null,
          systemInstruction: 'You are a helpful assistant.',
        );

        expect(result, hasLength(1));
        expect(result[0].role, dartantic.ChatMessageRole.system);
        expect(result[0].text, 'You are a helpful assistant.');
      });

      test('converts UserMessage to user role', () {
        final history = [genui.UserMessage.text('Hello')];

        final List<dartantic.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(1));
        expect(result[0].role, dartantic.ChatMessageRole.user);
        expect(result[0].text, 'Hello');
      });

      test('converts UserUiInteractionMessage to user role', () {
        final history = [genui.UserUiInteractionMessage.text('Clicked button')];

        final List<dartantic.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(1));
        expect(result[0].role, dartantic.ChatMessageRole.user);
        expect(result[0].text, 'Clicked button');
      });

      test('converts AiTextMessage to model role', () {
        final history = [genui.AiTextMessage.text('AI response')];

        final List<dartantic.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(1));
        expect(result[0].role, dartantic.ChatMessageRole.model);
        expect(result[0].text, 'AI response');
      });

      test('includes InternalMessage as system', () {
        final List<genui.ChatMessage> history = [
          genui.UserMessage.text('Hello'),
          const genui.InternalMessage('Internal note'),
          genui.AiTextMessage.text('Response'),
        ];

        final List<dartantic.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(3));
        expect(result[0].role, dartantic.ChatMessageRole.user);
        expect(result[1].role, dartantic.ChatMessageRole.system);
        expect(result[2].role, dartantic.ChatMessageRole.model);
      });

      test('includes ToolResponseMessage as user tool results', () {
        final List<genui.ChatMessage> history = [
          genui.UserMessage.text('Hello'),
          const genui.ToolResponseMessage([
            genui.ToolResultPart(callId: 'call1', result: '{}'),
          ]),
          genui.AiTextMessage.text('Response'),
        ];

        final List<dartantic.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(3));
        expect(result[0].role, dartantic.ChatMessageRole.user);
        expect(result[1].role, dartantic.ChatMessageRole.user);
        expect(
          result[1].parts.whereType<dartantic.ToolPart>().length,
          greaterThanOrEqualTo(1),
        );
        expect(result[2].role, dartantic.ChatMessageRole.model);
      });

      test('handles full conversation with system instruction', () {
        final List<genui.ChatMessage> history = [
          genui.UserMessage.text('What is 2+2?'),
          genui.AiTextMessage.text('2+2 equals 4.'),
          genui.UserMessage.text('And 3+3?'),
        ];

        final List<dartantic.ChatMessage> result = converter.toHistory(
          history,
          systemInstruction: 'You are a math tutor.',
        );

        expect(result, hasLength(4));
        expect(result[0].role, dartantic.ChatMessageRole.system);
        expect(result[0].text, 'You are a math tutor.');
        expect(result[1].role, dartantic.ChatMessageRole.user);
        expect(result[1].text, 'What is 2+2?');
        expect(result[2].role, dartantic.ChatMessageRole.model);
        expect(result[2].text, '2+2 equals 4.');
        expect(result[3].role, dartantic.ChatMessageRole.user);
        expect(result[3].text, 'And 3+3?');
      });
    });
  });
}
