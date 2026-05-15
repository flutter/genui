// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2a/src/a2a/client/sse_parser.dart';

void main() {
  group('SseParser', () {
    test('handles long lines', () async {
      final parser = SseParser();
      final longLine = 'data: {"result": {"key": "${'a' * 350}"}}';
      final Stream<String> stream = Stream.fromIterable([longLine, '']);
      final List<Map<String, Object?>> result = await parser
          .parse(stream)
          .toList();
      expect(result.length, 1);
    });

    test('ignores unexpected lines', () async {
      final parser = SseParser();
      final Stream<String> stream = Stream.fromIterable(['invalid line', '']);
      final List<Map<String, Object?>> result = await parser
          .parse(stream)
          .toList();
      expect(result, isEmpty);
    });

    test('handles pending data at end of stream', () async {
      final parser = SseParser();
      final Stream<String> stream = Stream.fromIterable([
        'data: { "result": { "key": "value" } }',
      ]);
      final List<Map<String, Object?>> result = await parser
          .parse(stream)
          .toList();
      expect(
        result,
        equals([
          {'key': 'value'},
        ]),
      );
    });

    test('handles null result', () async {
      final parser = SseParser();
      final Stream<String> stream = Stream.fromIterable([
        'data: { "result": null }',
        '',
      ]);
      final List<Map<String, Object?>> result = await parser
          .parse(stream)
          .toList();
      expect(result, isEmpty);
    });
  });
}
