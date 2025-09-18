// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiContentConverter', () {
    late GeminiContentConverter converter;

    setUp(() {
      converter = GeminiContentConverter();
    });

    test('toFirebaseAiContent converts $UserMessage with $TextPart', () {
      final messages = [UserMessage.text('Hello')];
      final result = converter.toFirebaseAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.role, 'user');
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<firebase_ai.TextPart>());
      expect((result.first.parts.first as firebase_ai.TextPart).text, 'Hello');
    });

    test('toFirebaseAiContent converts $AiTextMessage with $TextPart', () {
      final messages = [AiTextMessage.text('Hi there')];
      final result = converter.toFirebaseAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.role, 'model');
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<firebase_ai.TextPart>());
      expect(
        (result.first.parts.first as firebase_ai.TextPart).text,
        'Hi there',
      );
    });

    test('toFirebaseAiContent converts $AiUiMessage', () {
      final definition = UiDefinition.fromMap({
        'root': 'a',
        'widgets': <Object?>[],
      });
      final messages = [AiUiMessage(definition: definition)];
      final result = converter.toFirebaseAiContent(messages);
      expect(result, hasLength(1));
      expect(result.first.role, 'model');
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<firebase_ai.TextPart>());
      expect(
        (result.first.parts.first as firebase_ai.TextPart).text,
        definition.asContextDescriptionText(),
      );
    });

    test('toFirebaseAiContent ignores $InternalMessage', () {
      final messages = [const InternalMessage('Thinking...')];
      final result = converter.toFirebaseAiContent(messages);
      expect(result, isEmpty);
    });

    test('toFirebaseAiContent converts multi-part $UserMessage', () {
      final messages = [
        UserMessage([
          const TextPart('Look at this image'),
          ImagePart.fromBytes(Uint8List(0), mimeType: 'image/png'),
        ]),
      ];
      final result = converter.toFirebaseAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.role, 'user');
      expect(result.first.parts, hasLength(2));
      expect(result.first.parts[0], isA<firebase_ai.TextPart>());
      expect(result.first.parts[1], isA<firebase_ai.InlineDataPart>());
    });

    test('toFirebaseAiContent converts $ImagePart from bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final messages = [
        UserMessage([ImagePart.fromBytes(bytes, mimeType: 'image/jpeg')]),
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.InlineDataPart;
      expect(part.mimeType, 'image/jpeg');
      expect(part.bytes, bytes);
    });

    test('toFirebaseAiContent converts $ImagePart from base64', () {
      const base64String = 'AQID'; // base64 for [1, 2, 3]
      final messages = [
        UserMessage([
          const ImagePart.fromBase64(base64String, mimeType: 'image/png'),
        ]),
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.InlineDataPart;
      expect(part.mimeType, 'image/png');
      expect(part.bytes, base64.decode(base64String));
    });

    test('toFirebaseAiContent converts $ImagePart from URL', () {
      final url = Uri.parse('http://example.com/image.jpg');
      final messages = [
        UserMessage([ImagePart.fromUrl(url)]),
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.TextPart;
      expect(part.text, 'Image at $url');
    });

    test('toFirebaseAiContent converts $ToolCallPart', () {
      final messages = [
        const AiTextMessage([
          ToolCallPart(
            id: 'call1',
            toolName: 'doSomething',
            arguments: {'arg': 'value'},
          ),
        ]),
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.FunctionCall;
      expect(part.name, 'doSomething');
      expect(part.args, {'arg': 'value'});
    });

    test('toFirebaseAiContent converts $ToolResponseMessage', () {
      final messages = [
        ToolResponseMessage([
          ToolResultPart(callId: 'call1', result: jsonEncode({'data': 'ok'})),
        ]),
      ];
      final result = converter.toFirebaseAiContent(messages);
      expect(result.first.role, 'user');
      final part = result.first.parts.first as firebase_ai.FunctionResponse;
      expect(part.name, 'call1');
      expect(part.response, {'data': 'ok'});
    });

    test('toFirebaseAiContent converts $ThinkingPart', () {
      final messages = [
        const AiTextMessage([ThinkingPart('working on it')]),
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.TextPart;
      expect(part.text, 'Thinking: working on it');
    });

    test(
      'toFirebaseAiContent handles multiple messages of different types',
      () {
        final messages = [
          UserMessage.text('First message'),
          AiTextMessage.text('Second message'),
          UserMessage.text('Third message'),
        ];
        final result = converter.toFirebaseAiContent(messages);

        expect(result, hasLength(3));
        expect(result[0].role, 'user');
        expect(
          (result[0].parts.first as firebase_ai.TextPart).text,
          'First message',
        );
        expect(result[1].role, 'model');
        expect(
          (result[1].parts.first as firebase_ai.TextPart).text,
          'Second message',
        );
        expect(result[2].role, 'user');
        expect(
          (result[2].parts.first as firebase_ai.TextPart).text,
          'Third message',
        );
      },
    );
  });
}
