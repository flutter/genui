// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dartantic_interface/dartantic_interface.dart' as di;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui_dartantic/genui_dartantic.dart';

void main() {
  group('DartanticContentConverter', () {
    late DartanticContentConverter converter;

    setUp(() {
      converter = DartanticContentConverter();
    });

    group('toPromptText', () {
      test('converts UserMessage with text to prompt string', () {
        final message = genui.UserMessage.text('Hello, world!');

        final String result = converter.toPromptText(message);

        expect(result, 'Hello, world!');
      });

      test('converts UserMessage with multiple text parts', () {
        final message = genui.UserMessage([
          const genui.TextPart('First part'),
          const genui.TextPart('Second part'),
        ]);

        final String result = converter.toPromptText(message);

        expect(result, 'First part\nSecond part');
      });

      test('converts UserUiInteractionMessage to prompt string', () {
        final message = genui.UserUiInteractionMessage.text('UI interaction');

        final String result = converter.toPromptText(message);

        expect(result, 'UI interaction');
      });

      test('converts AiTextMessage to prompt string', () {
        final message = genui.AiTextMessage.text('AI response');

        final String result = converter.toPromptText(message);

        expect(result, 'AI response');
      });

      test('converts InternalMessage to prompt string', () {
        const message = genui.InternalMessage('System instruction');

        final String result = converter.toPromptText(message);

        expect(result, 'System instruction');
      });

      test('throws for ToolResponseMessage', () {
        const message = genui.ToolResponseMessage([
          genui.ToolResultPart(callId: 'call1', result: '{"status": "ok"}'),
        ]);

        expect(
          () => converter.toPromptText(message),
          throwsA(isA<ContentConverterException>()),
        );
      });

      test('handles DataPart in message', () {
        final message = genui.UserMessage([
          const genui.TextPart('Check this data:'),
          const genui.DataPart({'key': 'value'}),
        ]);

        final String result = converter.toPromptText(message);

        expect(result, contains('Check this data:'));
        expect(result, contains('Data:'));
        expect(result, contains('key'));
      });

      test('handles ImagePart with URL in message', () {
        final message = genui.UserMessage([
          const genui.TextPart('Look at this image:'),
          genui.ImagePart.fromUrl(Uri.parse('https://example.com/image.png')),
        ]);

        final String result = converter.toPromptText(message);

        expect(result, contains('Look at this image:'));
        expect(result, contains('Image at https://example.com/image.png'));
      });

      test('handles ThinkingPart in message', () {
        final message = genui.AiTextMessage([
          const genui.ThinkingPart('Let me think about this...'),
          const genui.TextPart('Here is my answer.'),
        ]);

        final String result = converter.toPromptText(message);

        expect(result, contains('Thinking: Let me think about this...'));
        expect(result, contains('Here is my answer.'));
      });

      test('ignores ToolCallPart in message', () {
        final message = genui.AiTextMessage([
          const genui.TextPart('Calling a tool'),
          const genui.ToolCallPart(
            id: 'call1',
            toolName: 'test_tool',
            arguments: {'arg': 'value'},
          ),
        ]);

        final String result = converter.toPromptText(message);

        expect(result, 'Calling a tool');
      });

      test('ignores ToolResultPart in message', () {
        final message = genui.AiTextMessage([
          const genui.TextPart('Got result'),
          const genui.ToolResultPart(callId: 'call1', result: '{}'),
        ]);

        final String result = converter.toPromptText(message);

        expect(result, 'Got result');
      });

      test('handles empty message parts', () {
        final message = genui.UserMessage([]);

        final String result = converter.toPromptText(message);

        expect(result, '');
      });
    });

    group('toHistory', () {
      test('returns empty list for null history', () {
        final List<di.ChatMessage> result = converter.toHistory(null);

        expect(result, isEmpty);
      });

      test('returns empty list for empty history', () {
        final List<di.ChatMessage> result = converter.toHistory([]);

        expect(result, isEmpty);
      });

      test('includes system instruction as first message', () {
        final List<di.ChatMessage> result = converter.toHistory(
          null,
          systemInstruction: 'You are a helpful assistant.',
        );

        expect(result, hasLength(1));
        expect(result[0].role, di.ChatMessageRole.system);
        expect(result[0].text, 'You are a helpful assistant.');
      });

      test('converts UserMessage to user role', () {
        final history = [genui.UserMessage.text('Hello')];

        final List<di.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(1));
        expect(result[0].role, di.ChatMessageRole.user);
        expect(result[0].text, 'Hello');
      });

      test('converts UserUiInteractionMessage to user role', () {
        final history = [genui.UserUiInteractionMessage.text('Clicked button')];

        final List<di.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(1));
        expect(result[0].role, di.ChatMessageRole.user);
        expect(result[0].text, 'Clicked button');
      });

      test('converts AiTextMessage to model role', () {
        final history = [genui.AiTextMessage.text('AI response')];

        final List<di.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(1));
        expect(result[0].role, di.ChatMessageRole.model);
        expect(result[0].text, 'AI response');
      });

      test('skips InternalMessage', () {
        final history = [
          genui.UserMessage.text('Hello'),
          const genui.InternalMessage('Internal note'),
          genui.AiTextMessage.text('Response'),
        ];

        final List<di.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(2));
        expect(result[0].role, di.ChatMessageRole.user);
        expect(result[1].role, di.ChatMessageRole.model);
      });

      test('skips ToolResponseMessage', () {
        final history = [
          genui.UserMessage.text('Hello'),
          const genui.ToolResponseMessage([
            genui.ToolResultPart(callId: 'call1', result: '{}'),
          ]),
          genui.AiTextMessage.text('Response'),
        ];

        final List<di.ChatMessage> result = converter.toHistory(history);

        expect(result, hasLength(2));
        expect(result[0].role, di.ChatMessageRole.user);
        expect(result[1].role, di.ChatMessageRole.model);
      });

      test('handles full conversation with system instruction', () {
        final history = [
          genui.UserMessage.text('What is 2+2?'),
          genui.AiTextMessage.text('2+2 equals 4.'),
          genui.UserMessage.text('And 3+3?'),
        ];

        final List<di.ChatMessage> result = converter.toHistory(
          history,
          systemInstruction: 'You are a math tutor.',
        );

        expect(result, hasLength(4));
        expect(result[0].role, di.ChatMessageRole.system);
        expect(result[0].text, 'You are a math tutor.');
        expect(result[1].role, di.ChatMessageRole.user);
        expect(result[1].text, 'What is 2+2?');
        expect(result[2].role, di.ChatMessageRole.model);
        expect(result[2].text, '2+2 equals 4.');
        expect(result[3].role, di.ChatMessageRole.user);
        expect(result[3].text, 'And 3+3?');
      });
    });
  });
}
