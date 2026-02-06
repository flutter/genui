// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/functions/functions.dart';

void main() {
  group('FunctionRegistry', () {
    late FunctionRegistry registry;

    setUp(() {
      // FunctionRegistry is a singleton, so we're testing the shared instance
      registry = FunctionRegistry();
    });

    test('register and invoke custom function', () {
      registry.register('customFunc', (args) => 'invoked with ${args['val']}');
      expect(registry.invoke('customFunc', {'val': 1}), 'invoked with 1');
    });

    test('returns null for unknown function', () {
      expect(registry.invoke('unknownFunc', {}), isNull);
    });

    group('Standard Functions', () {
      test('required', () {
        expect(registry.invoke('required', {}), isFalse);
        expect(registry.invoke('required', {'value': null}), isFalse);
        expect(registry.invoke('required', {'value': ''}), isFalse);
        expect(registry.invoke('required', {'value': []}), isFalse);
        expect(registry.invoke('required', {'value': {}}), isFalse);
        expect(registry.invoke('required', {'value': 'valid'}), isTrue);
        expect(
          registry.invoke('required', {
            'value': [1],
          }),
          isTrue,
        );
        expect(
          registry.invoke('required', {
            'value': {'k': 'v'},
          }),
          isTrue,
        );
      });

      test('regex', () {
        expect(
          registry.invoke('regex', {
            'value': 'test@example.com',
            'pattern': r'^[^@]+@[^@]+\.[^@]+$',
          }),
          isTrue,
        );
        expect(
          registry.invoke('regex', {
            'value': 'invalid',
            'pattern': r'^[^@]+@[^@]+\.[^@]+$',
          }),
          isFalse,
        );
        expect(
          registry.invoke('regex', {'value': 'any', 'pattern': 'invalid['}),
          isFalse,
        ); // Invalid regex pattern
      });

      test('length', () {
        expect(registry.invoke('length', {'value': 'abc', 'min': 3}), isTrue);
        expect(registry.invoke('length', {'value': 'ab', 'min': 3}), isFalse);
        expect(registry.invoke('length', {'value': 'abc', 'max': 3}), isTrue);
        expect(registry.invoke('length', {'value': 'abcd', 'max': 3}), isFalse);
        expect(
          registry.invoke('length', {
            'value': [1, 2, 3],
            'min': 2,
            'max': 4,
          }),
          isTrue,
        );
      });

      test('numeric', () {
        expect(
          registry.invoke('numeric', {'value': 10, 'min': 5, 'max': 15}),
          isTrue,
        );
        expect(registry.invoke('numeric', {'value': 4, 'min': 5}), isFalse);
        expect(registry.invoke('numeric', {'value': 16, 'max': 15}), isFalse);
        expect(registry.invoke('numeric', {'value': 'not a number'}), isFalse);
      });

      test('email', () {
        expect(registry.invoke('email', {'value': 'test@example.com'}), isTrue);
        expect(registry.invoke('email', {'value': 'invalid'}), isFalse);
      });

      test('formatString', () {
        expect(registry.invoke('formatString', {'value': 'Hello'}), 'Hello');
        expect(registry.invoke('formatString', {'value': 123}), '123');
        expect(registry.invoke('formatString', {}), '');
      });

      test('formatNumber', () {
        // Basic formatting
        expect(
          registry.invoke('formatNumber', {'value': 1234.56}),
          '1,234.56',
        ); // Default locale might vary but usually has grouping
        expect(
          registry.invoke('formatNumber', {
            'value': 1234.56,
            'decimalPlaces': 1,
          }),
          '1,234.6',
        ); // Rounding
        expect(
          registry.invoke('formatNumber', {
            'value': 1234.56,
            'decimalPlaces': 2,
            'useGrouping': false,
          }),
          '1234.56',
        ); // No grouping
      });

      test('formatCurrency', () {
        // We can't easily test exact output without forcing locale, but we can
        // test it doesn't crash.
        expect(
          registry.invoke('formatCurrency', {
            'value': 100,
            'currencyCode': 'USD',
          }),
          contains('100.00'),
        );
      });

      test('formatDate', () {
        final date = DateTime(2023, 1, 1);
        expect(
          registry.invoke('formatDate', {
            'value': date.toIso8601String(),
            'pattern': 'yyyy-MM-dd',
          }),
          '2023-01-01',
        );
        expect(
          registry.invoke('formatDate', {
            'value': date.millisecondsSinceEpoch,
            'pattern': 'yyyy',
          }),
          '2023',
        );
      });

      test('pluralize', () {
        expect(
          registry.invoke('pluralize', {
            'count': 0,
            'zero': 'no items',
            'one': 'one item',
            'other': 'items',
          }),
          'no items',
        );
        expect(
          registry.invoke('pluralize', {
            'count': 1,
            'zero': 'no items',
            'one': 'one item',
            'other': 'items',
          }),
          'one item',
        );
        expect(
          registry.invoke('pluralize', {
            'count': 5,
            'zero': 'no items',
            'one': 'one item',
            'other': 'items',
          }),
          'items',
        );
      });
    });
  });
}
