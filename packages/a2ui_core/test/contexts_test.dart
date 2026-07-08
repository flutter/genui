// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/src/core/contexts.dart';
import 'package:a2ui_core/src/core/data_model.dart';
import 'package:a2ui_core/src/primitives/errors.dart';
import 'package:a2ui_core/src/primitives/identifiers.dart';
import 'package:test/test.dart';

void main() {
  group('DataContext @index', () {
    late DataModel dataModel;

    setUp(() {
      dataModel = DataModel();
    });

    DataContext contextAt(int? templateIndex) => DataContext(
      dataModel,
      (name, args, context) => throw StateError('No functions registered.'),
      '/',
      templateIndex: templateIndex,
    );

    test('resolves to the iteration index inside a template scope', () {
      expect(contextAt(2).resolveSync({'call': '@index'}), 2);
    });

    test('applies the offset argument', () {
      expect(
        contextAt(2).resolveSync({
          'call': '@index',
          'args': {'offset': 1},
        }),
        3,
      );
    });

    test('resolves reactively via resolveListenable', () {
      expect(contextAt(4).resolveListenable({'call': '@index'}).value, 4);
    });

    test('throws when evaluated outside a template scope', () {
      expect(
        () => contextAt(null).resolveSync({'call': '@index'}),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('throws for unknown @-prefixed system functions', () {
      expect(
        () => contextAt(0).resolveSync({'call': '@bogus'}),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('is inherited by nested contexts', () {
      final DataContext nested = contextAt(5).nested('items');
      expect(nested.resolveSync({'call': '@index'}), 5);
    });
  });

  group('isValidA2uiIdentifier', () {
    test('accepts UAX #31 identifiers', () {
      expect(isValidA2uiIdentifier('Button'), isTrue);
      expect(isValidA2uiIdentifier('formatDate'), isTrue);
      expect(isValidA2uiIdentifier('café'), isTrue);
    });

    test('rejects invalid identifiers', () {
      expect(isValidA2uiIdentifier(''), isFalse);
      expect(isValidA2uiIdentifier('1abc'), isFalse);
      expect(isValidA2uiIdentifier('my-function'), isFalse);
      expect(isValidA2uiIdentifier('@index'), isFalse);
      expect(isValidA2uiIdentifier('has space'), isFalse);
    });
  });
}
