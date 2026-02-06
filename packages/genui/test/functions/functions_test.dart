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
      registry.register('customFunc', (args) => 'invoked with $args');
      expect(registry.invoke('customFunc', [1, 2]), 'invoked with [1, 2]');
    });

    test('returns null for unknown function', () {
      expect(registry.invoke('unknownFunc', []), isNull);
    });

    group('Standard Functions', () {
      test('required', () {
        expect(registry.invoke('required', []), isFalse);
        expect(registry.invoke('required', [null]), isFalse);
        expect(registry.invoke('required', ['']), isFalse);
        expect(registry.invoke('required', [[]]), isFalse);
        expect(registry.invoke('required', [{}]), isFalse);
        expect(registry.invoke('required', ['valid']), isTrue);
        expect(
          registry.invoke('required', [
            [1],
          ]),
          isTrue,
        );
        expect(
          registry.invoke('required', [
            {'k': 'v'},
          ]),
          isTrue,
        );
      });

      test('regex', () {
        expect(
          registry.invoke('regex', [
            'test@example.com',
            r'^[^@]+@[^@]+\.[^@]+$',
          ]),
          isTrue,
        );
        expect(
          registry.invoke('regex', ['invalid', r'^[^@]+@[^@]+\.[^@]+$']),
          isFalse,
        );
        expect(
          registry.invoke('regex', ['any', 'invalid[']),
          isFalse,
        ); // Invalid regex pattern
      });

      test('length', () {
        expect(
          registry.invoke('length', [
            'abc',
            {'min': 3},
          ]),
          isTrue,
        );
        expect(
          registry.invoke('length', [
            'ab',
            {'min': 3},
          ]),
          isFalse,
        );
        expect(
          registry.invoke('length', [
            'abc',
            {'max': 3},
          ]),
          isTrue,
        );
        expect(
          registry.invoke('length', [
            'abcd',
            {'max': 3},
          ]),
          isFalse,
        );
        expect(
          registry.invoke('length', [
            [1, 2, 3],
            {'min': 2, 'max': 4},
          ]),
          isTrue,
        );
      });

      test('numeric', () {
        expect(
          registry.invoke('numeric', [
            10,
            {'min': 5, 'max': 15},
          ]),
          isTrue,
        );
        expect(
          registry.invoke('numeric', [
            4,
            {'min': 5},
          ]),
          isFalse,
        );
        expect(
          registry.invoke('numeric', [
            16,
            {'max': 15},
          ]),
          isFalse,
        );
        expect(registry.invoke('numeric', ['not a number', {}]), isFalse);
      });

      test('email', () {
        expect(registry.invoke('email', ['test@example.com']), isTrue);
        expect(registry.invoke('email', ['invalid']), isFalse);
      });

      test('formatString', () {
        expect(registry.invoke('formatString', ['Hello']), 'Hello');
        expect(registry.invoke('formatString', [123]), '123');
        expect(registry.invoke('formatString', []), '');
      });

      test('formatNumber', () {
        // Basic formatting
        expect(
          registry.invoke('formatNumber', [1234.56]),
          '1,234.56',
        ); // Default locale might vary but usually has grouping
        expect(
          registry.invoke('formatNumber', [1234.56, 1]),
          '1,234.6',
        ); // Rounding
        expect(
          registry.invoke('formatNumber', [1234.56, 2, false]),
          '1234.56',
        ); // No grouping
      });

      test('formatCurrency', () {
        // We can't easily test exact output without forcing locale, but we can test it doesn't crash
        expect(
          registry.invoke('formatCurrency', [100, 'USD']),
          contains('100.00'),
        );
      });

      test('formatDate', () {
        final date = DateTime(2023, 1, 1);
        expect(
          registry.invoke('formatDate', [date.toIso8601String(), 'yyyy-MM-dd']),
          '2023-01-01',
        );
        expect(
          registry.invoke('formatDate', [date.millisecondsSinceEpoch, 'yyyy']),
          '2023',
        );
      });

      test('pluralize', () {
        final options = {
          'zero': 'no items',
          'one': 'one item',
          'other': 'items',
        };
        expect(registry.invoke('pluralize', [0, options]), 'no items');
        expect(registry.invoke('pluralize', [1, options]), 'one item');
        expect(registry.invoke('pluralize', [5, options]), 'items');
      });
    });
  });
}
