// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

const _identifier = r'^[\p{XID_Start}_][\p{XID_Continue}]*$';

void main() {
  group('pattern', () {
    final schema = Schema.fromMap({'type': 'string', 'pattern': _identifier});

    for (final valid in ['owner', 'trace_id', 'café']) {
      test('matches $valid with a Unicode property escape', () {
        expect(schema.validateSync(valid), isEmpty);
      });
    }

    test('rejects a string the property escape excludes', () {
      expect(schema.validateSync('a-b'), isNotEmpty);
    });

    test('matches a character outside the BMP as one code point', () {
      final dragons = Schema.fromMap({'type': 'string', 'pattern': r'^🐲*$'});
      expect(dragons.validateSync('🐲🐲'), isEmpty);
    });

    test('keeps a pattern that only non-unicode mode accepts', () {
      final escaped = Schema.fromMap({'type': 'string', 'pattern': r'^a\-b$'});
      expect(escaped.validateSync('a-b'), isEmpty);
      expect(escaped.validateSync('ab'), isNotEmpty);
    });
  });

  group('patternProperties', () {
    final schema = Schema.fromMap({
      'type': 'object',
      'patternProperties': {_identifier: <String, Object?>{}},
      'additionalProperties': false,
    });

    test('matches keys with a Unicode property escape', () {
      expect(
        schema.validateSync({'owner': 1, 'trace_id': 2, 'café': 3}),
        isEmpty,
      );
    });

    test('rejects a key the property escape excludes', () {
      expect(schema.validateSync({'a-b': 1}), isNotEmpty);
    });
  });
}
