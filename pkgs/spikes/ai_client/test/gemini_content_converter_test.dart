// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_client/src/gemini_content_converter.dart';
import 'package:ai_client/src/model/chat_message.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiContentConverter', () {
    final converter = GeminiContentConverter();

    test('converts UserMessage with text', () {
      final messages = [UserMessage.text('Hello')];
      final result = converter.toFirebaseAiContent(messages);
      expect(result.length, 1);
      expect(result.first.role, 'user');
      expect(result.first.parts.first, isA<firebase_ai.TextPart>());
      expect((result.first.parts.first as firebase_ai.TextPart).text, 'Hello');
    });

    test('converts AssistantMessage with text', () {
      final messages = [AssistantMessage.text('Hi there')];
      final result = converter.toFirebaseAiContent(messages);
      expect(result.length, 1);
      expect(result.first.role, 'model');
      expect(result.first.parts.first, isA<firebase_ai.TextPart>());
      expect(
          (result.first.parts.first as firebase_ai.TextPart).text, 'Hi there');
    });

    test('converts ToolResponseMessage', () {
      final messages = [
        const ToolResponseMessage([
          ToolResultPart(callId: '123', result: '{"status": "done"}'),
        ])
      ];
      final result = converter.toFirebaseAiContent(messages);
      expect(result.length, 1);
      expect(result.first.role, 'user');
      final part = result.first.parts.first;
      expect(part, isA<firebase_ai.FunctionResponse>());
      final funcResponse = part as firebase_ai.FunctionResponse;
      expect(funcResponse.name, '123');
      expect(funcResponse.response['status'], 'done');
    });

    test('skips InternalMessage', () {
      final messages = [const InternalMessage('internal')];
      final result = converter.toFirebaseAiContent(messages);
      expect(result, isEmpty);
    });

    test('converts ImagePart from bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final messages = [
        UserMessage([ImagePart.fromBytes(bytes, mimeType: 'image/png')])
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.InlineDataPart;
      expect(part.mimeType, 'image/png');
      expect(part.bytes, bytes);
    });

    test('converts ImagePart from base64', () {
      const base64String = 'AQID'; // [1, 2, 3]
      final messages = [
        const UserMessage([ImagePart.fromBase64(base64String, mimeType: 'image/png')])
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.InlineDataPart;
      expect(part.mimeType, 'image/png');
      expect(part.bytes, base64.decode(base64String));
    });

    test('converts ThinkingPart', () {
      final messages = [
        const AssistantMessage([ThinkingPart('hmmm...')])
      ];
      final result = converter.toFirebaseAiContent(messages);
      final part = result.first.parts.first as firebase_ai.TextPart;
      expect(part.text, 'Thinking: hmmm...');
    });
  });
}
