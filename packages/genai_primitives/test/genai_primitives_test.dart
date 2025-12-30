// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:genai_primitives/genai_primitives.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

void main() {
  group('MessagePart', () {
    group('TextPart', () {
      test('creation', () {
        const part = TextPart('hello world');
        expect(part.text, equals('hello world'));
        expect(part.toString(), contains('TextPart(hello world)'));
      });

      test('equality', () {
        const part1 = TextPart('hello');
        const part2 = TextPart('hello');
        const part3 = TextPart('world');

        expect(part1, equals(part2));
        expect(part1.hashCode, equals(part2.hashCode));
        expect(part1, isNot(equals(part3)));
      });

      test('JSON serialization', () {
        const part = TextPart('hello');
        final Map<String, dynamic> json = part.toJson();
        expect(json, equals({'type': 'TextPart', 'content': 'hello'}));

        final reconstructed = Part.fromJson(json);
        expect(reconstructed, isA<TextPart>());
        expect((reconstructed as TextPart).text, equals('hello'));
      });
    });

    group('DataPart', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      test('creation', () {
        final part = DataPart(bytes, mimeType: 'image/png', name: 'test.png');
        expect(part.bytes, equals(bytes));
        expect(part.mimeType, equals('image/png'));
        expect(part.name, equals('test.png'));
      });

      test('equality', () {
        final part1 = DataPart(bytes, mimeType: 'image/png');
        final part2 = DataPart(bytes, mimeType: 'image/png');
        final part3 = DataPart(bytes, mimeType: 'image/jpeg');

        expect(part1, equals(part2));
        expect(part1.hashCode, equals(part2.hashCode));
        expect(part1, isNot(equals(part3)));
      });

      test('JSON serialization', () {
        final part = DataPart(bytes, mimeType: 'image/png', name: 'test.png');
        final Map<String, dynamic> json = part.toJson();

        expect(json['type'], equals('DataPart'));
        final content = json['content'] as Map<String, dynamic>;
        expect(content['mimeType'], equals('image/png'));
        expect(content['name'], equals('test.png'));
        expect(content['bytes'], startsWith('data:image/png;base64,'));

        final reconstructed = Part.fromJson(json);
        expect(reconstructed, isA<DataPart>());
        final dataPart = reconstructed as DataPart;
        expect(dataPart.mimeType, equals('image/png'));
        expect(dataPart.name, equals('test.png'));
        expect(dataPart.bytes, equals(bytes));
      });
    });

    group('LinkPart', () {
      final Uri uri = Uri.parse('https://example.com/image.png');

      test('creation', () {
        final part = LinkPart(uri, mimeType: 'image/png', name: 'image.png');
        expect(part.url, equals(uri));
        expect(part.mimeType, equals('image/png'));
        expect(part.name, equals('image.png'));
      });

      test('equality', () {
        final part1 = LinkPart(uri, mimeType: 'image/png');
        final part2 = LinkPart(uri, mimeType: 'image/png');
        final part3 = LinkPart(Uri.parse('https://other.com'));

        expect(part1, equals(part2));
        expect(part1.hashCode, equals(part2.hashCode));
        expect(part1, isNot(equals(part3)));
      });

      test('JSON serialization', () {
        final part = LinkPart(uri, mimeType: 'image/png', name: 'image');
        final Map<String, dynamic> json = part.toJson();

        expect(json['type'], equals('LinkPart'));
        final content = json['content'] as Map<String, dynamic>;
        expect(content['url'], equals(uri.toString()));
        expect(content['mimeType'], equals('image/png'));
        expect(content['name'], equals('image'));

        final reconstructed = Part.fromJson(json);
        expect(reconstructed, isA<LinkPart>());
        final linkPart = reconstructed as LinkPart;
        expect(linkPart.url, equals(uri));
        expect(linkPart.mimeType, equals('image/png'));
        expect(linkPart.name, equals('image'));
      });
    });

    group('ToolPart', () {
      group('Call', () {
        test('creation', () {
          final part = const ToolPart.call(
            callId: 'call_1',
            toolName: 'get_weather',
            arguments: {'city': 'London'},
          );
          expect(part.kind, equals(ToolPartKind.call));
          expect(part.callId, equals('call_1'));
          expect(part.toolName, equals('get_weather'));
          expect(part.arguments, equals({'city': 'London'}));
          expect(part.result, isNull);
          expect(part.argumentsRaw, contains('"city":"London"'));
        });

        test('JSON serialization', () {
          final part = const ToolPart.call(
            callId: 'call_1',
            toolName: 'get_weather',
            arguments: {'city': 'London'},
          );
          final Map<String, dynamic> json = part.toJson();

          expect(json['type'], equals('ToolPart'));
          final content = json['content'] as Map<String, dynamic>;
          expect(content['id'], equals('call_1'));
          expect(content['name'], equals('get_weather'));
          expect(content['arguments'], equals({'city': 'London'}));
          expect(
            content['result'],
            isNull,
          ); // Ensures result is not present or null

          final reconstructed = Part.fromJson(json);
          expect(reconstructed, isA<ToolPart>());
          final toolPart = reconstructed as ToolPart;
          expect(toolPart.kind, equals(ToolPartKind.call));
          expect(toolPart.callId, equals('call_1'));
          expect(toolPart.arguments, equals({'city': 'London'}));
        });
      });

      group('Result', () {
        test('creation', () {
          final part = const ToolPart.result(
            callId: 'call_1',
            toolName: 'get_weather',
            result: {'temp': 20},
          );
          expect(part.kind, equals(ToolPartKind.result));
          expect(part.callId, equals('call_1'));
          expect(part.toolName, equals('get_weather'));
          expect(part.result, equals({'temp': 20}));
          expect(part.arguments, isNull);
        });

        test('JSON serialization', () {
          final part = const ToolPart.result(
            callId: 'call_1',
            toolName: 'get_weather',
            result: {'temp': 20},
          );
          final Map<String, dynamic> json = part.toJson();

          expect(json['type'], equals('ToolPart'));
          final content = json['content'] as Map<String, dynamic>;
          expect(content['id'], equals('call_1'));
          expect(content['name'], equals('get_weather'));
          expect(content['result'], equals({'temp': 20}));

          final reconstructed = Part.fromJson(json);
          expect(reconstructed, isA<ToolPart>());
          final toolPart = reconstructed as ToolPart;
          expect(toolPart.kind, equals(ToolPartKind.result));
          expect(toolPart.callId, equals('call_1'));
          expect(toolPart.result, equals({'temp': 20}));
        });
      });
    });
  });

  group('ChatMessage', () {
    test('factories', () {
      final system = ChatMessage.system('instructions');
      expect(system.role, equals(ChatMessageRole.system));
      expect(system.text, equals('instructions'));

      final user = ChatMessage.user('hello');
      expect(user.role, equals(ChatMessageRole.user));
      expect(user.text, equals('hello'));

      final model = ChatMessage.model('hi');
      expect(model.role, equals(ChatMessageRole.model));
      expect(model.text, equals('hi'));
    });

    test('helpers', () {
      final toolCall = const ToolPart.call(
        callId: '1',
        toolName: 'tool',
        arguments: {},
      );
      final toolResult = const ToolPart.result(
        callId: '1',
        toolName: 'tool',
        result: 'ok',
      );

      final msg1 = ChatMessage(
        role: ChatMessageRole.model,
        parts: [const TextPart('Hi'), toolCall],
      );
      expect(msg1.hasToolCalls, isTrue);
      expect(msg1.hasToolResults, isFalse);
      expect(msg1.toolCalls, hasLength(1));
      expect(msg1.toolResults, isEmpty);
      expect(msg1.text, equals('Hi'));

      final msg2 = ChatMessage(role: ChatMessageRole.user, parts: [toolResult]);
      expect(msg2.hasToolCalls, isFalse);
      expect(msg2.hasToolResults, isTrue);
      expect(msg2.toolCalls, isEmpty);
      expect(msg2.toolResults, hasLength(1));
    });

    test('metadata', () {
      final msg = ChatMessage.user('hi', metadata: {'key': 'value'});
      expect(msg.metadata['key'], equals('value'));

      final Map<String, dynamic> json = msg.toJson();
      expect(json['metadata'], equals({'key': 'value'}));

      final reconstructed = ChatMessage.fromJson(json);
      expect(reconstructed.metadata, equals({'key': 'value'}));
    });

    test('JSON serialization', () {
      final msg = ChatMessage.model('response');
      final Map<String, dynamic> json = msg.toJson();

      expect(json['role'], equals('model'));
      expect((json['parts'] as List).length, equals(1));

      final reconstructed = ChatMessage.fromJson(json);
      expect(reconstructed, equals(msg));
    });
  });

  group('ToolDefinition', () {
    test('creation and serialization', () {
      final ToolDefinition<Object> tool = ToolDefinition(
        name: 'test',
        description: 'desc',
        inputSchema: Schema.object(
          properties: {'loc': Schema.string(description: 'Location')},
        ),
      );

      final Map<String, dynamic> json = tool.toJson();
      expect(json['name'], equals('test'));
      expect(json['description'], equals('desc'));
      expect(json['inputSchema'], isNotNull);

      // Since we don't have a fromJson in ToolDefinition (yet?), we just test
      // serialization If we needed it, we would add it. For now, testing that
      // it produces expected map structure.
      final schemaMap = json['inputSchema'] as Map<String, dynamic>;
      expect(schemaMap['type'], equals('object'));
    });
  });
}
