// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  });
}
