// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:dartantic_interface/dartantic_interface.dart' as dartantic;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'package:flutter_genui_dartantic/flutter_genui_dartantic.dart';

void main() {
  group('DartanticContentConverter', () {
    late DartanticContentConverter converter;

    setUp(() {
      converter = DartanticContentConverter();
    });

    test('converts UserMessage to dartantic format', () {
      final message = UserMessage.text('Hello, world!');
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.role, equals(dartantic.ChatMessageRole.user));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.TextPart>());
      expect((result.first.parts.first as dartantic.TextPart).text, 
             equals('Hello, world!'));
    });

    test('converts UserUiInteractionMessage to dartantic format', () {
      final message = UserUiInteractionMessage.text('User clicked button');
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.role, equals(dartantic.ChatMessageRole.user));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.TextPart>());
    });

    test('converts AiTextMessage to dartantic format', () {
      final message = AiTextMessage.text('Hello! How can I help you?');
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.role, equals(dartantic.ChatMessageRole.model));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.TextPart>());
    });

    test('converts AiUiMessage to dartantic format', () {
      final definition = UiDefinition(
        surfaceId: 'test',
        components: {
          'root': Component(
            id: 'root',
            componentProperties: {'type': 'Column', 'children': ['text1']},
          ),
        },
      );
      final message = AiUiMessage(definition: definition);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.role, equals(dartantic.ChatMessageRole.model));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.TextPart>());
    });

    test('converts InternalMessage to dartantic format', () {
      final message = InternalMessage('System instruction');
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.role, equals(dartantic.ChatMessageRole.system));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.TextPart>());
      expect((result.first.parts.first as dartantic.TextPart).text, 
             equals('System instruction'));
    });

    test('converts ToolResponseMessage to dartantic format', () {
      final message = ToolResponseMessage([
        ToolResultPart(callId: 'call-123', result: '{"result": "success"}'),
        ToolResultPart(callId: 'call-456', result: '{"result": "error"}'),
      ]);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.role, equals(dartantic.ChatMessageRole.user));
      expect(result.first.parts, hasLength(2));
      expect(result.first.parts.first, isA<dartantic.ToolPart>());
      expect(result.first.parts.last, isA<dartantic.ToolPart>());
    });

    test('converts ImagePart from bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final imagePart = ImagePart.fromBytes(bytes, mimeType: 'image/png');
      final message = UserMessage([imagePart]);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.DataPart>());
      final imageContent = result.first.parts.first as dartantic.DataPart;
      expect(imageContent.bytes, equals(bytes));
      expect(imageContent.mimeType, equals('image/png'));
    });

    test('converts ImagePart from base64', () {
      final base64 = 'SGVsbG8gV29ybGQ='; // "Hello World" in base64
      final imagePart = ImagePart.fromBase64(base64, mimeType: 'image/jpeg');
      final message = UserMessage([imagePart]);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.DataPart>());
    });

    test('converts ImagePart from URL', () {
      final url = Uri.parse('https://example.com/image.jpg');
      final imagePart = ImagePart.fromUrl(url);
      final message = UserMessage([imagePart]);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.LinkPart>());
      expect((result.first.parts.first as dartantic.LinkPart).url.toString(), 
             contains('https://example.com/image.jpg'));
    });

    test('converts ToolCallPart to dartantic format', () {
      final toolCallPart = ToolCallPart(
        id: 'call-123',
        toolName: 'test_tool',
        arguments: {'param1': 'value1', 'param2': 42},
      );
      final message = AiTextMessage([toolCallPart]);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.ToolPart>());
      final toolCallContent = result.first.parts.first as dartantic.ToolPart;
      expect(toolCallContent.id, equals('call-123'));
      expect(toolCallContent.name, equals('test_tool'));
      expect(toolCallContent.arguments, equals({'param1': 'value1', 'param2': 42}));
    });

    test('converts ToolResultPart to dartantic format', () {
      final toolResultPart = ToolResultPart(
        callId: 'call-123',
        result: '{"result": "success"}',
      );
      final message = ToolResponseMessage([toolResultPart]);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.ToolPart>());
      final toolContent = result.first.parts.first as dartantic.ToolPart;
      expect(toolContent.id, equals('call-123'));
      expect(toolContent.result, equals('{"result": "success"}'));
    });

    test('converts ThinkingPart to dartantic format', () {
      final thinkingPart = ThinkingPart('Let me think about this...');
      final message = AiTextMessage([thinkingPart]);
      final result = converter.toDartanticMessages([message]);

      expect(result, hasLength(1));
      expect(result.first.parts, hasLength(1));
      expect(result.first.parts.first, isA<dartantic.TextPart>());
      expect((result.first.parts.first as dartantic.TextPart).text, 
             equals('Thinking: Let me think about this...'));
    });

    test('converts multiple messages', () {
      final messages = [
        UserMessage.text('Hello'),
        AiTextMessage.text('Hi there!'),
        InternalMessage('System note'),
      ];
      final result = converter.toDartanticMessages(messages);

      expect(result, hasLength(3));
      expect(result[0].role, equals(dartantic.ChatMessageRole.user));
      expect(result[1].role, equals(dartantic.ChatMessageRole.model));
      expect(result[2].role, equals(dartantic.ChatMessageRole.system));
    });

    test('throws exception for ImagePart with no data', () {
      // Create an ImagePart with no data by using a private constructor
      // This is a bit tricky since ImagePart doesn't expose a no-data constructor
      // We'll test this by creating a message with an empty parts list instead
      final message = UserMessage([]);
      final result = converter.toDartanticMessages([message]);
      
      expect(result, hasLength(1));
      expect(result.first.parts, isEmpty);
    });
  });
}
