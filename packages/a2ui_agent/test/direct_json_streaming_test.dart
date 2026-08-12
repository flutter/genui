// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final catalogs = <Catalog<ComponentApi>>[MinimalCatalog()];

  /// Feeds [response] to a parser one [size]-character chunk at a time.
  List<ResponsePart> stream(String response, {int size = 1}) {
    final parser = DirectJsonParser(catalogs: catalogs);
    final parts = <ResponsePart>[];
    for (var index = 0; index < response.length; index += size) {
      final int end = index + size < response.length
          ? index + size
          : response.length;
      parts.addAll(parser.parseChunk(response.substring(index, end)));
    }
    parts.addAll(parser.flush());
    return parts;
  }

  List<AgentToRendererMessage> messagesOf(List<ResponsePart> parts) => [
    for (final part in parts)
      if (part is A2uiPart) ...part.a2ui,
  ];

  String textOf(List<ResponsePart> parts) => [
    for (final part in parts)
      if (part is TextPart) part.text,
  ].join();

  const response = '''
Building it now.
<a2ui-json>[
{"version":"v0.9","createSurface":{"surfaceId":"s","catalogId":"https://a2ui.org/specification/v0_9/catalogs/minimal/minimal_catalog.json"}},
{"version":"v0.9","updateComponents":{"surfaceId":"s","components":[
{"id":"root","component":"Column","children":["a","b"]},
{"id":"a","component":"Text","text":"First"},
{"id":"b","component":"Text","text":"Second"}
]}}
]</a2ui-json>
Done.''';

  group('streaming', () {
    test('settles on the same UI as a non-streamed parse', () {
      final List<AgentToRendererMessage> streamed = messagesOf(
        stream(response),
      );
      final List<AgentToRendererMessage> whole = messagesOf(
        DirectJsonParser(catalogs: catalogs).parseResponse(response),
      );

      // Streaming emits a component repeatedly as its content grows, so the
      // comparable value is the state each id settles on, not the emission
      // count.
      expect(_finalState(streamed), _finalState(whole));
      expect(streamed.whereType<CreateSurfaceMessage>(), hasLength(1));
      expect(streamed.whereType<CreateSurfaceMessage>().single.surfaceId, 's');
    });

    test('emits conversational text around the block', () {
      expect(textOf(stream(response)).trim(), startsWith('Building it now.'));
      expect(textOf(stream(response)).trim(), endsWith('Done.'));
    });

    test('never re-emits a component that has not changed', () {
      final emissions = <String, List<String>>{};
      for (final AgentToRendererMessage message in messagesOf(
        stream(response),
      )) {
        if (message is! UpdateComponentsMessage) continue;
        for (final Map<String, dynamic> component in message.components) {
          emissions
              .putIfAbsent('${component['id']}', () => <String>[])
              .add('$component');
        }
      }

      expect(emissions.keys, unorderedEquals(['root', 'a', 'b']));
      for (final MapEntry<String, List<String>> entry in emissions.entries) {
        expect(
          entry.value.toSet(),
          hasLength(entry.value.length),
          reason: 'component ${entry.key} was emitted unchanged twice',
        );
      }
    });

    test('emits components before the payload is complete', () {
      final parser = DirectJsonParser(catalogs: catalogs);
      const prefix =
          '<a2ui-json>[{"version":"v0.9","updateComponents":{"surfaceId":"s",'
          '"components":[{"id":"root","component":"Column","children":["a"]},';

      final List<ResponsePart> parts = parser.parseChunk(prefix);
      final List<AgentToRendererMessage> messages = messagesOf(parts);

      expect(messages, hasLength(1));
      expect(
        (messages.single as UpdateComponentsMessage).components.single['id'],
        'root',
      );
    });

    test('grows a progressive string as it arrives', () {
      final parser = DirectJsonParser(catalogs: catalogs);
      final texts = <Object?>[];

      void feed(String chunk) {
        for (final ResponsePart part in parser.parseChunk(chunk)) {
          if (part is! A2uiPart) continue;
          for (final AgentToRendererMessage message in part.a2ui) {
            if (message is! UpdateComponentsMessage) continue;
            for (final Map<String, dynamic> component in message.components) {
              texts.add(component['text']);
            }
          }
        }
      }

      feed(
        '<a2ui-json>[{"version":"v0.9","updateComponents":{"surfaceId":"s",'
        '"components":[{"id":"a","component":"Text","text":"Hel',
      );
      feed('lo wor');
      feed('ld"}]}}]</a2ui-json>');

      expect(texts, ['Hel', 'Hello wor', 'Hello world']);
    });

    test('holds back a component whose type is still arriving', () {
      final parser = DirectJsonParser(catalogs: catalogs);

      final List<ResponsePart> parts = parser.parseChunk(
        '<a2ui-json>[{"version":"v0.9","updateComponents":{"surfaceId":"s",'
        '"components":[{"id":"a","component":"Te',
      );

      expect(messagesOf(parts), isEmpty);
    });

    test('does not leak a partially received sentinel tag as text', () {
      final parser = DirectJsonParser(catalogs: catalogs);

      expect(parser.parseChunk('hi <a2ui'), [const TextPart('hi ')]);
      expect(parser.parseChunk('-json>[]</a2ui-json>'), isEmpty);
    });

    test('salvages a payload the model never closed', () {
      final List<AgentToRendererMessage> messages = messagesOf(
        stream(
          '<a2ui-json>[{"version":"v0.9","updateComponents":{"surfaceId":"s",'
          '"components":[{"id":"a","component":"Text","text":"Trunca',
        ),
      );

      // The truncated string is healed to the prefix that did arrive rather
      // than dropping the component entirely.
      expect(_finalState(messages), {'a': 'Trunca'});
    });

    test('handles an unwrapped stream', () {
      final parser = DirectJsonParser(catalogs: catalogs);
      final parts = <ResponsePart>[
        ...parser.parseChunk(
          '[{"version":"v0.9","deleteSurface":{"surfaceId":"s"}}]',
          wrapped: false,
        ),
        ...parser.flush(),
      ];

      expect(messagesOf(parts).single, isA<DeleteSurfaceMessage>());
    });

    test('parses a stream of chunks', () async {
      final parser = DirectJsonParser(catalogs: catalogs);
      final List<ResponsePart> parts = await parser
          .parseStream(Stream<String>.fromIterable(_chunks(response, 7)))
          .toList();

      expect(messagesOf(parts).whereType<CreateSurfaceMessage>(), hasLength(1));
    });

    test('is chunk-size independent', () {
      final List<String> byOne = _describe(messagesOf(stream(response)));
      final List<String> byThirteen = _describe(
        messagesOf(stream(response, size: 13)),
      );
      final List<String> byHuge = _describe(
        messagesOf(stream(response, size: 1000)),
      );

      expect(byThirteen, byOne);
      expect(byHuge, byOne);
    });

    test('rejects a component that is not in the catalog', () {
      expect(
        () => stream(
          '<a2ui-json>[{"version":"v0.9","updateComponents":{"surfaceId":"s",'
          '"components":[{"id":"a","component":"Carousel"}]}}]</a2ui-json>',
        ),
        throwsA(isA<A2uiValidationError>()),
      );
    });
  });
}

/// The text each component id settled on.
Map<String, Object?> _finalState(List<AgentToRendererMessage> messages) {
  final state = <String, Object?>{};
  for (final message in messages) {
    if (message is! UpdateComponentsMessage) continue;
    for (final Map<String, dynamic> component in message.components) {
      state['${component['id']}'] = component['text'];
    }
  }
  return state;
}

/// The final content of each component, in emission order.
List<String> _describe(List<AgentToRendererMessage> messages) {
  final rendered = <String, String>{};
  for (final message in messages) {
    if (message is! UpdateComponentsMessage) continue;
    for (final Map<String, dynamic> component in message.components) {
      rendered['${component['id']}'] = '$component';
    }
  }
  return [
    for (final MapEntry<String, String> entry in rendered.entries)
      '${entry.key}=${entry.value}',
  ];
}

Iterable<String> _chunks(String value, int size) sync* {
  for (var index = 0; index < value.length; index += size) {
    yield value.substring(
      index,
      index + size < value.length ? index + size : value.length,
    );
  }
}
