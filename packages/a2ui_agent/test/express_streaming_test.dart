// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final catalogs = <Catalog<ComponentApi>>[MinimalCatalog()];

  List<ResponsePart> stream(String response, {int size = 1}) {
    final parser = ExpressParser(catalogs: catalogs);
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

  List<Object?> componentIdsOf(List<ResponsePart> parts) => [
    for (final message in messagesOf(parts))
      if (message is UpdateComponentsMessage)
        for (final Map<String, dynamic> component in message.components)
          component['id'],
  ];

  const response = '''
Here you go.
<a2ui-express>
surface("s1")
root = Column([title, cta])
title = Text("Hello", "h1")
cta = Button(label, Event("go"))
label = Text("Go")
</a2ui-express>
Anything else?''';

  group('statement splitting', () {
    test('stops at the last complete statement', () {
      expect(completeStatementPrefixLength('a = Text("x")\nb = Te'), 14);
    });

    test('does not split inside an open call', () {
      expect(completeStatementPrefixLength('a = Column([\n  b,\n'), 0);
    });

    test('does not split inside a string', () {
      expect(completeStatementPrefixLength('a = Text("line\nbreak'), 0);
    });

    test('treats a semicolon as a boundary', () {
      expect(completeStatementPrefixLength('a = Text("x"); b'), 14);
    });

    test('ignores brackets inside comments', () {
      expect(
        completeStatementPrefixLength('# a ( comment\na = Text("x")\n'),
        28,
      );
    });
  });

  group('streaming', () {
    test('produces the same messages as a non-streamed parse', () {
      final List<AgentToRendererMessage> streamed = messagesOf(
        stream(response),
      );
      final List<AgentToRendererMessage> whole = messagesOf(
        ExpressParser(catalogs: catalogs).parseResponse(response),
      );

      expect(_components(streamed), _components(whole));
      expect(streamed.whereType<CreateSurfaceMessage>(), hasLength(1));
    });

    test('emits each component exactly once', () {
      final List<Object?> ids = componentIdsOf(stream(response));

      expect(ids, ['root', 'title', 'cta', 'label']);
    });

    test('emits a statement as soon as its line completes', () {
      final parser = ExpressParser(catalogs: catalogs);

      expect(parser.parseChunk('<a2ui-express>\nroot = Text("a")'), isEmpty);

      final List<ResponsePart> parts = parser.parseChunk('\n');
      final List<AgentToRendererMessage> messages = [
        for (final part in parts)
          if (part is A2uiPart) ...part.a2ui,
      ];
      expect(messages.whereType<CreateSurfaceMessage>(), hasLength(1));
      expect(
        messages.whereType<UpdateComponentsMessage>().single.components.single,
        containsPair('id', 'root'),
      );
    });

    test('holds back a statement that spans lines until it closes', () {
      final parser = ExpressParser(catalogs: catalogs);

      expect(
        parser.parseChunk('<a2ui-express>\nroot = Column([\n  Text("a"),\n'),
        isEmpty,
      );
      expect(parser.parseChunk('])\n'), isNotEmpty);
    });

    test('emits surrounding conversational text', () {
      final String text = [
        for (final part in stream(response))
          if (part is TextPart) part.text,
      ].join();

      expect(text.trim(), startsWith('Here you go.'));
      expect(text.trim(), endsWith('Anything else?'));
    });

    test('is chunk-size independent', () {
      expect(componentIdsOf(stream(response, size: 11)), [
        'root',
        'title',
        'cta',
        'label',
      ]);
      expect(componentIdsOf(stream(response, size: 5000)), [
        'root',
        'title',
        'cta',
        'label',
      ]);
    });

    test('drops a statement the model never finished', () {
      final List<Object?> ids = componentIdsOf(
        stream('<a2ui-express>\nroot = Text("ok")\ntitle = Text("trunc'),
      );

      expect(ids, ['root']);
    });

    test('rejects an unknown component mid-stream', () {
      expect(
        () => stream('<a2ui-express>\nroot = Carousel()\n</a2ui-express>'),
        throwsA(isA<A2uiFormatError>()),
      );
    });
  });
}

List<Object?> _components(List<AgentToRendererMessage> messages) => [
  for (final message in messages)
    if (message is UpdateComponentsMessage) ...message.components,
];
