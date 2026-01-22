// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:genai_primitives/genai_primitives.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

void main() {
  // In this test dynamic is used instead of Object?
  // to test support for dynamic types.
  group('Part', () {
    test('mimeType helper', () {
      // Test with extensions (may be environment dependent for text/plain).
      expect(
        DataPart.mimeTypeForFile('test.png'),
        anyOf(equals('image/png'), equals('application/octet-stream')),
      );

      // Test with header bytes (sniffing should be environment independent).
      final pngHeader = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      expect(
        DataPart.mimeTypeForFile('unknown', headerBytes: pngHeader),
        equals('image/png'),
      );

      final pdfHeader = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      expect(
        DataPart.mimeTypeForFile('file', headerBytes: pdfHeader),
        equals('application/pdf'),
      );
    });

    test('nameFromMimeType helper', () {
      expect(DataPart.nameFromMimeType('image/png'), equals('image.png'));
      expect(DataPart.nameFromMimeType('application/pdf'), equals('file.pdf'));
      expect(DataPart.nameFromMimeType('unknown/type'), equals('file.bin'));
    });

    test('extensionFromMimeType helper', () {
      expect(DataPart.extensionFromMimeType('image/png'), equals('png'));
      expect(DataPart.extensionFromMimeType('application/pdf'), equals('pdf'));
      expect(DataPart.extensionFromMimeType('unknown/type'), isNull);
    });

    test('defaultMimeType helper', () {
      expect(DataPart.defaultMimeType, equals('application/octet-stream'));
    });

    test('uses defaultMimeType when unknown', () {
      expect(
        DataPart.mimeTypeForFile('unknown_file_no_extension'),
        equals(DataPart.defaultMimeType),
      );
    });

    test('fromJson throws on unknown type', () {
      expect(
        () => Part.fromJson({
          'type': 'Unknown',
          'content': '',
        }, converterRegistry: defaultPartConverterRegistry),
        throwsUnimplementedError,
      );
    });
  });

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
        expect(json, equals({'type': 'Text', 'content': 'hello'}));

        final reconstructed = Part.fromJson(
          json,
          converterRegistry: defaultPartConverterRegistry,
        );
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

        expect(json['type'], equals('Data'));
        final content = json['content'] as Map<String, dynamic>;
        expect(content['mimeType'], equals('image/png'));
        expect(content['name'], equals('test.png'));
        expect(content['bytes'], startsWith('data:image/png;base64,'));

        final reconstructed = Part.fromJson(
          json,
          converterRegistry: defaultPartConverterRegistry,
        );
        expect(reconstructed, isA<DataPart>());
        final dataPart = reconstructed as DataPart;
        expect(dataPart.mimeType, equals('image/png'));
        expect(dataPart.name, equals('test.png'));
        expect(dataPart.bytes, equals(bytes));
      });

      test('fromFile creation', () async {
        final bytes = Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);
        final file = XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'my_file.png',
        );

        final DataPart part = await DataPart.fromFile(file);
        expect(part.bytes, equals(bytes));
        expect(part.mimeType, equals('image/png'));
        // XFile.fromData might not preserve the name in some test environments
        expect(part.name, anyOf(equals('my_file.png'), equals('image.png')));
      });

      test('fromFile with unknown MIME type detection', () async {
        // PNG header
        final bytes = Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);
        final file = XFile.fromData(bytes, name: 'temp_file.png');

        final DataPart part = await DataPart.fromFile(file);
        expect(part.mimeType, equals('image/png'));
        expect(part.name, anyOf(equals('temp_file.png'), equals('image.png')));
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

        expect(json['type'], equals('Link'));
        final content = json['content'] as Map<String, dynamic>;
        expect(content['url'], equals(uri.toString()));
        expect(content['mimeType'], equals('image/png'));
        expect(content['name'], equals('image'));

        final reconstructed = Part.fromJson(
          json,
          converterRegistry: defaultPartConverterRegistry,
        );
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
          expect(json['type'], equals('Tool'));
          final content = json['content'] as Map<String, dynamic>;
          expect(content['id'], equals('call_1'));
          expect(content['name'], equals('get_weather'));
          expect(content['arguments'], equals({'city': 'London'}));
          expect(
            content['result'],
            isNull,
          ); // Ensures result is not present or null

          final reconstructed = Part.fromJson(
            json,
            converterRegistry: defaultPartConverterRegistry,
          );
          expect(reconstructed, isA<ToolPart>());
          final toolPart = reconstructed as ToolPart;
          expect(toolPart.kind, equals(ToolPartKind.call));
          expect(toolPart.callId, equals('call_1'));
          expect(toolPart.arguments, equals({'city': 'London'}));
        });

        test('toString', () {
          const part = ToolPart.call(
            callId: 'c1',
            toolName: 't1',
            arguments: {'a': 1},
          );
          expect(part.toString(), contains('ToolPart.call'));
          expect(part.toString(), contains('c1'));
        });

        test('argumentsRaw', () {
          const part1 = ToolPart.call(
            callId: 'c1',
            toolName: 't1',
            arguments: {},
          );
          expect(part1.argumentsRaw, equals('{}'));

          const part2 = ToolPart.call(
            callId: 'c2',
            toolName: 't2',
            arguments: {'a': 1},
          );
          expect(part2.argumentsRaw, equals('{"a":1}'));
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
          expect(part.argumentsRaw, equals(''));
        });

        test('toString', () {
          const part = ToolPart.result(
            callId: 'c1',
            toolName: 't1',
            result: 'ok',
          );
          expect(part.toString(), contains('ToolPart.result'));
          expect(part.toString(), contains('c1'));
        });

        test('JSON serialization', () {
          final part = const ToolPart.result(
            callId: 'call_1',
            toolName: 'get_weather',
            result: {'temp': 20},
          );
          final Map<String, dynamic> json = part.toJson();
          expect(json['type'], equals('Tool'));
          final content = json['content'] as Map<String, dynamic>;
          expect(content['id'], equals('call_1'));
          expect(content['name'], equals('get_weather'));
          expect(content['result'], equals({'temp': 20}));

          final reconstructed = Part.fromJson(
            json,
            converterRegistry: defaultPartConverterRegistry,
          );
          expect(reconstructed, isA<ToolPart>());
          final toolPart = reconstructed as ToolPart;
          expect(toolPart.kind, equals(ToolPartKind.result));
          expect(toolPart.callId, equals('call_1'));
          expect(toolPart.result, equals({'temp': 20}));
        });
      });
    });
  });

  group('Message', () {
    test('fromParts', () {
      final fromParts = ChatMessage(
        role: ChatMessageRole.user,
        parts: [const TextPart('hello')],
      );
      expect(fromParts.text, equals('hello'));
    });

    group('Named constructors', () {
      test('system', () {
        final message = ChatMessage.system(
          'instruction',
          parts: [const TextPart(' extra')],
          metadata: {'a': 1},
        );
        expect(message.role, equals(ChatMessageRole.system));
        expect(message.text, equals('instruction extra'));
        expect(message.parts.first, isA<TextPart>());
        expect((message.parts.first as TextPart).text, equals('instruction'));
        expect(message.parts[1], isA<TextPart>());
        expect((message.parts[1] as TextPart).text, equals(' extra'));
        expect(message.metadata, equals({'a': 1}));
      });

      test('user', () {
        final message = ChatMessage.user(
          'hello',
          parts: [const TextPart(' world')],
          metadata: {'b': 2},
        );
        expect(message.role, equals(ChatMessageRole.user));
        expect(message.text, equals('hello world'));
        expect(message.parts.first, isA<TextPart>());
        expect((message.parts.first as TextPart).text, equals('hello'));
        expect(message.metadata, equals({'b': 2}));
      });

      test('model', () {
        final message = ChatMessage.model(
          'response',
          parts: [
            const ToolPart.call(callId: 'id', toolName: 't', arguments: {}),
          ],
          metadata: {'c': 3},
        );
        expect(message.role, equals(ChatMessageRole.model));
        expect(message.text, equals('response'));
        expect(message.parts.first, isA<TextPart>());
        expect((message.parts.first as TextPart).text, equals('response'));
        expect(message.parts[1], isA<ToolPart>());
        expect(message.metadata, equals({'c': 3}));
      });
    });

    test('default constructor', () {
      final message = ChatMessage.system('instructions');
      expect(message.text, equals('instructions'));
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
      final msg = ChatMessage(
        role: ChatMessageRole.user,
        parts: [const TextPart('hi')],
        metadata: {'key': 'value'},
      );
      expect(msg.metadata['key'], equals('value'));

      final Map<String, dynamic> json = msg.toJson();
      expect(json['metadata'], equals({'key': 'value'}));

      final reconstructed = ChatMessage.fromJson(json);
      expect(reconstructed.metadata, equals({'key': 'value'}));
    });

    test('JSON serialization', () {
      final msg = ChatMessage.model('response');
      final Map<String, dynamic> json = msg.toJson();

      expect((json['parts'] as List).length, equals(1));

      final reconstructed = ChatMessage.fromJson(json);
      expect(reconstructed, equals(msg));
    });

    test('mixed content JSON round-trip', () {
      final msg = ChatMessage(
        role: ChatMessageRole.model,
        parts: [
          const TextPart('text'),
          const ToolPart.call(
            callId: 'id',
            toolName: 'name',
            arguments: {'a': 1},
          ),
          const ToolPart.result(
            callId: 'id',
            toolName: 'name',
            result: {'success': true},
          ),
        ],
      );

      final Map<String, Object?> json = msg.toJson();
      final reconstructed = ChatMessage.fromJson(json);

      expect(reconstructed, equals(msg));
      expect(reconstructed.parts, hasLength(3));
      expect(reconstructed.parts[0], isA<TextPart>());
      expect(reconstructed.parts[1], isA<ToolPart>());
      expect(reconstructed.parts[2], isA<ToolPart>());
    });

    test('equality and hashCode', () {
      final msg1 = ChatMessage(
        role: ChatMessageRole.user,
        parts: const [TextPart('hi')],
        metadata: const {'k': 'v'},
      );
      final msg2 = ChatMessage(
        role: ChatMessageRole.user,
        parts: const [TextPart('hi')],
        metadata: const {'k': 'v'},
      );
      final msg3 = ChatMessage(
        role: ChatMessageRole.user,
        parts: const [TextPart('hello')],
      );
      final msg4 = ChatMessage(
        role: ChatMessageRole.user,
        parts: const [TextPart('hi')],
        metadata: const {'k': 'other'},
      );

      expect(msg1, equals(msg2));
      expect(msg1.hashCode, equals(msg2.hashCode));
      expect(msg1, isNot(equals(msg3)));
      expect(msg1, isNot(equals(msg4)));
    });

    test('text concatenation', () {
      final msg = ChatMessage(
        role: ChatMessageRole.model,
        parts: [
          const TextPart('Part 1. '),
          const ToolPart.call(callId: '1', toolName: 't', arguments: {}),
          const TextPart('Part 2.'),
        ],
      );
      expect(msg.text, equals('Part 1. Part 2.'));
    });

    test('toString', () {
      final msg = ChatMessage.user('hi');
      expect(msg.toString(), contains('Message'));
      expect(msg.toString(), contains('parts: [TextPart(hi)]'));
    });
  });

  group('Parts', () {
    test('fromText', () {
      final parts = Parts.fromText(
        'Hello',
        parts: [
          const ToolPart.call(callId: 'c1', toolName: 't1', arguments: {}),
        ],
      );
      expect(parts.length, equals(2));
      expect(parts.first, isA<TextPart>());
      expect((parts.first as TextPart).text, equals('Hello'));
      expect(parts.last, isA<ToolPart>());
    });

    test('fromText with empty text', () {
      final parts = Parts.fromText(
        '',
        parts: [
          const ToolPart.call(callId: 'c1', toolName: 't1', arguments: {}),
        ],
      );
      expect(parts.length, equals(1));
      expect(parts.first, isA<ToolPart>());
    });

    test('helpers', () {
      final parts = const Parts([
        TextPart('Hello'),
        ToolPart.call(callId: 'c1', toolName: 't1', arguments: {}),
        ToolPart.result(callId: 'c2', toolName: 't2', result: 'r'),
      ]);

      expect(parts.toolResults, hasLength(1));
      expect(parts.toolResults.first.callId, equals('c2'));
    });

    test('immutability', () {
      final parts = const Parts([TextPart('text')]);
      expect(() => parts.length = 2, throwsUnsupportedError);
      expect(() => parts[0] = const TextPart('new'), throwsUnsupportedError);
    });

    test('equality', () {
      final parts1 = const Parts([TextPart('a'), TextPart('b')]);
      final parts2 = const Parts([TextPart('a'), TextPart('b')]);
      final parts3 = const Parts([TextPart('a')]);

      expect(parts1, equals(parts2));
      expect(parts1.hashCode, equals(parts2.hashCode));
      expect(parts1, isNot(equals(parts3)));
    });

    test('JSON serialization', () {
      final parts = const Parts([
        TextPart('text'),
        ToolPart.call(callId: '1', toolName: 't', arguments: {}),
      ]);

      final List<Object?> json = parts.toJson();
      expect(json, hasLength(2));

      final reconstructed = Parts.fromJson(json);
      expect(reconstructed, equals(parts));
      expect(reconstructed.first, isA<TextPart>());
      expect(reconstructed.last, isA<ToolPart>());
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

      final ToolDefinition reconstructed = ToolDefinition.fromJson(json);
      expect(reconstructed.name, equals('test'));
      expect(reconstructed.description, equals('desc'));
      expect(reconstructed.inputSchema.value['type'], equals('object'));
    });
  });
}
