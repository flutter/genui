// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:genui/src/model/a2ui_message.dart';
import 'package:genui/src/model/generation_events.dart';
import 'package:genui/src/transport/a2ui_parser_transformer.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiParserTransformer', () {
    late StreamController<String> controller;
    late Stream<GenerationEvent> stream;

    setUp(() {
      controller = StreamController<String>();
      stream = controller.stream.transform(const A2uiParserTransformer());
    });

    tearDown(() {
      controller.close();
    });

    test('emits pure text chunks as TextEvents', () async {
      final StreamQueue<GenerationEvent> queue = StreamQueue(stream);
      controller.add('Hello ');
      controller.add('World');

      expect(
        (await queue.next) as TextEvent,
        isA<TextEvent>().having((e) => e.text, 'text', 'Hello '),
      );
      expect(
        (await queue.next) as TextEvent,
        isA<TextEvent>().having((e) => e.text, 'text', 'World'),
      );
      await queue.cancel();
    });

    test('extracts Markdown JSON block', () async {
      final StreamQueue<GenerationEvent> queue = StreamQueue(stream);

      controller.add('Here is a message:\n');
      controller.add('```json\n');
      controller.add(
        '{"version": "v0.9", "createSurface": {"surfaceId": "foo", '
        '"catalogId": "cat"}}\n',
      );
      controller.add('```\n');
      controller.add('End of message.');

      expect(
        (await queue.next) as TextEvent,
        isA<TextEvent>().having(
          (e) => e.text,
          'text',
          contains('Here is a message:'),
        ),
      );

      final msgEvent = (await queue.next) as A2uiMessageEvent;
      expect(msgEvent.message, isA<CreateSurface>());
      expect((msgEvent.message as CreateSurface).surfaceId, 'foo');

      // The text after might be just the newline or "End of message."
      // We accept whatever text comes next, potentially fragmented.
      var lastText = (await queue.next) as TextEvent;
      while (!lastText.text.contains('End of message.')) {
        if (!await queue.hasNext) break;
        final GenerationEvent event = await queue.next;
        if (event is TextEvent) {
          lastText = TextEvent(lastText.text + event.text);
        } else {
          fail(
            'Expected text event containing "End of message.", found $event',
          );
        }
      }
      expect(lastText.text, contains('End of message.'));

      await queue.cancel();
    });

    test('extracts Balanced JSON block split across chunks', () async {
      final StreamQueue<GenerationEvent> queue = StreamQueue(stream);

      controller.add('Start ');
      controller.add('{ "version": "v0.9", "deleteSurface": ');
      controller.add('{ "surfaceId": '); // Needs nesting for wrapper
      controller.add('"bar" } }');
      controller.add(' End');

      expect(
        (await queue.next) as TextEvent,
        isA<TextEvent>().having((e) => e.text, 'text', 'Start '),
      );

      final msgEvent = (await queue.next) as A2uiMessageEvent;
      expect(msgEvent.message, isA<DeleteSurface>());
      expect((msgEvent.message as DeleteSurface).surfaceId, 'bar');

      expect(
        (await queue.next) as TextEvent,
        isA<TextEvent>().having((e) => e.text, 'text', ' End'),
      );

      await queue.cancel();
    });

    test('flushes buffer on done', () async {
      final StreamQueue<GenerationEvent> queue = StreamQueue(stream);

      controller.add('Incomplete { json');
      unawaited(controller.close());

      expect(
        (await queue.next) as TextEvent,
        isA<TextEvent>().having((e) => e.text, 'text', 'Incomplete '),
      );
      expect(
        (await queue.next) as TextEvent,
        isA<TextEvent>().having((e) => e.text, 'text', '{ json'),
      );
      expect(await queue.hasNext, isFalse);
    });
  });
}
