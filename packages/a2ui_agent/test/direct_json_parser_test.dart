// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final catalogs = <Catalog<ComponentApi>>[MinimalCatalog()];
  DirectJsonParser parser() => DirectJsonParser(catalogs: catalogs);

  group('unwrap', () {
    test('splits text and payload blocks in order', () {
      final List<RawResponsePart> parts = parser().unwrap(
        'Before <a2ui-json>[]</a2ui-json> after',
      );

      expect(parts, hasLength(3));
      expect(parts[0].part, const TextPart('Before'));
      expect(parts[1].part, const RawA2uiPart('[]'));
      expect(parts[1].isFinal, isTrue);
      expect(parts[2].part, const TextPart('after'));
    });

    test('handles several blocks', () {
      final List<RawResponsePart> parts = parser().unwrap(
        '<a2ui-json>[1]</a2ui-json>mid<a2ui-json>[2]</a2ui-json>',
      );

      expect(parts.map((part) => part.part), [
        const RawA2uiPart('[1]'),
        const TextPart('mid'),
        const RawA2uiPart('[2]'),
      ]);
    });

    test('marks an unterminated block as not final', () {
      final List<RawResponsePart> parts = parser().unwrap(
        'text <a2ui-json>[{"a"',
      );

      expect(parts.last.isFinal, isFalse);
      expect(parts.last.part, const RawA2uiPart('[{"a"'));
    });

    test('returns only text when there is no block', () {
      expect(
        parser().unwrap('just talking').single.part,
        const TextPart('just talking'),
      );
    });
  });

  group('wrap', () {
    test('re-adds the sentinel tags around raw blocks', () {
      final DirectJsonParser subject = parser();

      expect(
        subject.wrap(const [
          RawResponsePart(TextPart('Hello')),
          RawResponsePart(RawA2uiPart('[{"version":"v0.9"}]')),
        ]),
        'Hello<a2ui-json>[{"version":"v0.9"}]</a2ui-json>',
      );
    });

    test('is a fixed point of unwrap', () {
      final DirectJsonParser subject = parser();
      const response = 'Hello <a2ui-json>[{"version":"v0.9"}]</a2ui-json> bye';

      // unwrap trims conversational text, so wrapping is idempotent from the
      // second pass on rather than byte-identical to the model's output.
      final String wrapped = subject.wrap(subject.unwrap(response));
      expect(subject.wrap(subject.unwrap(wrapped)), wrapped);
      expect(wrapped, contains('<a2ui-json>[{"version":"v0.9"}]</a2ui-json>'));
    });
  });

  group('compile', () {
    test('compiles a list of messages', () {
      final List<AgentToRendererMessage> messages = parser().compile('''
[
  {"version": "v0.9", "createSurface": {"surfaceId": "s", "catalogId": "${MinimalCatalog().id}"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "s", "components": [
    {"id": "root", "component": "Text", "text": "Hi"}
  ]}}
]
''');

      expect(messages, hasLength(2));
      expect(messages.first, isA<CreateSurfaceMessage>());
      expect(
        (messages[1] as UpdateComponentsMessage).components.single['id'],
        'root',
      );
    });

    test('wraps a single message object in a list', () {
      final List<AgentToRendererMessage> messages = parser().compile(
        '{"version": "v0.9", "deleteSurface": {"surfaceId": "s"}}',
      );

      expect(messages.single, isA<DeleteSurfaceMessage>());
    });

    test('supplies a missing version', () {
      final List<AgentToRendererMessage> messages = parser().compile(
        '[{"deleteSurface": {"surfaceId": "s"}}]',
      );

      expect(messages.single.version, 'v0.9');
    });

    test('repairs trailing commas', () {
      final List<AgentToRendererMessage> messages = parser().compile(
        '[{"version": "v0.9", "deleteSurface": {"surfaceId": "s",},},]',
      );

      expect(messages.single, isA<DeleteSurfaceMessage>());
    });

    test('leaves commas inside strings alone', () {
      final List<AgentToRendererMessage> messages = parser().compile('''
[{"version": "v0.9", "updateComponents": {"surfaceId": "s", "components": [
  {"id": "root", "component": "Text", "text": "a, b, and c"}
]}}]
''');

      final message = messages.single as UpdateComponentsMessage;
      expect(message.components.single['text'], 'a, b, and c');
    });

    test('normalizes smart quotes', () {
      final List<AgentToRendererMessage> messages = parser().compile(
        '[{“version”: “v0.9”, “deleteSurface”: {“surfaceId”: “s”}}]',
      );

      expect((messages.single as DeleteSurfaceMessage).surfaceId, 's');
    });

    test('strips a markdown fence', () {
      final List<AgentToRendererMessage> messages = parser().compile(
        '```json\n'
        '[{"version": "v0.9", "deleteSurface": {"surfaceId": "s"}}]\n'
        '```',
      );

      expect(messages.single, isA<DeleteSurfaceMessage>());
    });

    test('rejects an empty block', () {
      expect(() => parser().compile('   '), throwsA(isA<A2uiFormatError>()));
    });

    test('rejects unparseable JSON', () {
      expect(
        () => parser().compile('[{"createSurface": '),
        throwsA(isA<A2uiFormatError>()),
      );
    });

    test('rejects a component that is not in the catalog', () {
      expect(
        () => parser().compile('''
[{"version": "v0.9", "updateComponents": {"surfaceId": "s", "components": [
  {"id": "root", "component": "Carousel"}
]}}]
'''),
        throwsA(
          isA<A2uiValidationError>().having(
            (error) => error.message,
            'message',
            contains("Unknown component 'Carousel'"),
          ),
        ),
      );
    });

    test('rejects a surface bound to an unknown catalog', () {
      expect(
        () => parser().compile(
          '[{"version": "v0.9", "createSurface": '
          '{"surfaceId": "s", "catalogId": "other"}}]',
        ),
        throwsA(isA<A2uiValidationError>()),
      );
    });
  });

  group('parseResponse', () {
    test('preserves the order of text and payloads', () {
      final List<ResponsePart> parts = parser().parseResponse(
        'Intro\n<a2ui-json>[{"version":"v0.9","deleteSurface":'
        '{"surfaceId":"s"}}]</a2ui-json>\nOutro',
      );

      expect(parts.map((part) => part.runtimeType.toString()), [
        'TextPart',
        'A2uiPart',
        'TextPart',
      ]);
    });

    test('compiles the whole content when it is not wrapped', () {
      final List<ResponsePart> parts = parser().parseResponse(
        '[{"version":"v0.9","deleteSurface":{"surfaceId":"s"}}]',
        wrapped: false,
      );

      expect((parts.single as A2uiPart).a2ui, hasLength(1));
    });
  });

  group('decompile', () {
    test('renders messages as indented JSON that compiles back', () {
      final DirectJsonParser subject = parser();
      final messages = <AgentToRendererMessage>[
        DeleteSurfaceMessage(surfaceId: 's'),
      ];

      final String json = subject.decompile(messages);
      expect(json, contains('"deleteSurface"'));
      expect(subject.compile(json).single, isA<DeleteSurfaceMessage>());
    });
  });

  group('progressiveKeys', () {
    test('covers free-form string properties', () {
      expect(parser().progressiveKeys, containsAll(['text', 'label']));
    });

    test('excludes component references and enums', () {
      final Set<String> keys = parser().progressiveKeys;

      expect(keys, isNot(contains('child')));
      expect(keys, isNot(contains('children')));
      expect(keys, isNot(contains('variant')));
    });

    test('honours an override', () {
      final parser = DirectJsonParser(
        catalogs: catalogs,
        customProgressiveKeys: const {'only'},
      );

      expect(parser.progressiveKeys, {'only'});
    });
  });
}
