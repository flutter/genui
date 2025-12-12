// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';

void main() {
  group('GoogleContentConverter', () {
    late GoogleContentConverter converter;

    setUp(() {
      converter = GoogleContentConverter();
    });

    test('toGoogleAiContent converts UserMessage with TextPart', () {
      final messages = [UserMessage.text('Hello')];
      final result = converter.toGoogleAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.role, 'user');
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first.text, 'Hello');
    });

    test('toGoogleAiContent converts AiTextMessage with TextPart', () {
      final messages = [AiTextMessage.text('Hi there')];
      final result = converter.toGoogleAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.role, 'model');
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first.text, 'Hi there');
    });

    test('toGoogleAiContent converts AiUiMessage', () {
      final definition = UiDefinition(surfaceId: 'testSurface');
      final messages = [AiUiMessage(definition: definition)];
      final result = converter.toGoogleAiContent(messages);
      expect(result, hasLength(1));
      expect(result.first.role, 'model');
    });

    test('toGoogleAiContent skips InternalMessage', () {
      final messages = [
        UserMessage.text('Hello'),
        const InternalMessage('Internal note'),
        AiTextMessage.text('Response'),
      ];
      final result = converter.toGoogleAiContent(messages);

      // Should only have 2 messages (user and ai), internal is skipped
      expect(result, hasLength(2));
      expect(result[0].role, 'user');
      expect(result[1].role, 'model');
    });

    test('toGoogleAiContent converts ImagePart with bytes', () {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final messages = [
        UserMessage([ImagePart.fromBytes(imageBytes, mimeType: 'image/png')]),
      ];
      final result = converter.toGoogleAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      final part = result.first.parts.first;
      expect(part.inlineData, isNotNull);
      expect(part.inlineData!.mimeType, 'image/png');
    });

    test('toGoogleAiContent converts ImagePart with URL', () {
      final messages = [
        UserMessage([
          ImagePart.fromUrl(
            Uri.parse('gs://bucket/image.png'),
            mimeType: 'image/png',
          ),
        ]),
      ];
      final result = converter.toGoogleAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      final part = result.first.parts.first;
      expect(part.fileData, isNotNull);
      expect(part.fileData!.fileUri, 'gs://bucket/image.png');
    });

    test('toGoogleAiContent converts ToolCallPart', () {
      final messages = [
        AiTextMessage([
          const ToolCallPart(
            id: 'call-1',
            toolName: 'calculator',
            arguments: {'operation': 'add', 'a': 1, 'b': 2},
          ),
        ]),
      ];
      final result = converter.toGoogleAiContent(messages);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      final part = result.first.parts.first;
      expect(part.functionCall, isNotNull);
      expect(part.functionCall!.id, 'call-1');
      expect(part.functionCall!.name, 'calculator');
    });
  });
}
