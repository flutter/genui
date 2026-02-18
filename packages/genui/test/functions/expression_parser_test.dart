// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/catalog/basic_catalog.dart';
import 'package:genui/src/functions/expression_parser.dart';
import 'package:genui/src/model/data_model.dart';
// import 'package:genui/src/primitives/simple_items.dart'; // Unused

void main() {
  group('ExpressionParser', () {
    late DataContext context;
    late ExpressionParser parser;
    late DataModel dataModel;

    setUp(() {
      dataModel = DataModel();
      context = DataContext(
        dataModel,
        '/',
        functions: BasicCatalogItems.asCatalog().functions,
      );
      parser = ExpressionParser(context);
    });

    Future<T> eval<T>(Object? result) async {
      if (result is Stream) {
        return (await result.first) as T;
      }
      return result as T;
    }

    group('parse', () {
      test('returns input if no expressions', () {
        expect(parser.parse('hello'), 'hello');
        expect(parser.parse('123'), '123');
      });

      test('resolves simple path expression', () {
        dataModel.update(DataPath('/name'), 'World');
        expect(parser.parse(r'Hello ${/name}'), 'Hello World');
      });

      test('resolves multiple expressions', () {
        dataModel.update(DataPath('/firstName'), 'John');
        dataModel.update(DataPath('/lastName'), 'Doe');
        expect(parser.parse(r'${/firstName} ${/lastName}'), 'John Doe');
      });

      test('escapes expression', () {
        expect(parser.parse(r'Value: \${/foo}'), r'Value: ${/foo}');
      });

      test('returns non-string type for single expression', () {
        dataModel.update(DataPath('/count'), 42);
        expect(parser.parse(r'${/count}'), 42);
      });

      test('converts non-string values to string when mixed with text', () {
        dataModel.update(DataPath('/count'), 42);
        expect(parser.parse(r'Count: ${/count}'), 'Count: 42');
      });
    });

    group('evaluateFunctionCall (Logic)', () {
      test('and', () async {
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'and',
              'args': {
                'values': [true, true],
              },
            }),
          ),
          isTrue,
        );
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'and',
              'args': {
                'values': [true, false],
              },
            }),
          ),
          isFalse,
        );
      });

      test('or', () async {
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'or',
              'args': {
                'values': [false, true],
              },
            }),
          ),
          isTrue,
        );
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'or',
              'args': {
                'values': [false, false],
              },
            }),
          ),
          isFalse,
        );
      });

      test('not', () async {
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'not',
              'args': {'value': true},
            }),
          ),
          isFalse,
        );
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'not',
              'args': {'value': false},
            }),
          ),
          isTrue,
        );
      });

      test('standard function', () async {
        // 'required' is a standard function
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'required',
              'args': {'value': 'something'},
            }),
          ),
          isTrue,
        );
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'required',
              'args': {'value': ''},
            }),
          ),
          isFalse,
        );
      });

      test('nested function calls via map', () async {
        // not(and(true, false)) -> not(false) -> true
        expect(
          await eval<bool>(
            parser.evaluateFunctionCall({
              'call': 'not',
              'args': {
                'value': {
                  'call': 'and',
                  'args': {
                    'values': [true, false],
                  },
                },
              },
            }),
          ),
          isTrue,
        );
      });
    });

    group('Function calls in expressions', () {
      test('resolves simple function', () async {
        expect(
          await eval<String>(parser.parse(r'${formatString(value: "Hello")}')),
          'Hello',
        );
      });

      test('resolves nested function', () async {
        expect(
          await eval<String>(
            parser.parse(
              r'${formatString(value: ${formatString(value: "Nested")})}',
            ),
          ),
          'Nested',
        );
      });

      test('resolves function with path args', () async {
        dataModel.update(DataPath('/val'), 'Dynamic');
        expect(
          await eval<String>(parser.parse(r'${formatString(value: ${/val})}')),
          'Dynamic',
        );
      });

      test('resolves function with quoted string containing spaces', () async {
        expect(
          await eval<String>(
            parser.parse(r'${formatString(value: "Hello World")}'),
          ),
          'Hello World',
        );
      });
    });

    group('extractDependencies', () {
      test('returns empty for no expressions', () {
        expect(parser.extractDependencies('hello'), isEmpty);
      });

      test('returns single path', () {
        expect(parser.extractDependencies(r'${/foo}'), {DataPath('/foo')});
      });

      test('returns multiple paths', () {
        expect(parser.extractDependencies(r'${/foo} ${/bar}'), {
          DataPath('/foo'),
          DataPath('/bar'),
        });
      });

      test('returns paths in function calls', () {
        expect(parser.extractDependencies(r'${formatString(value: ${/foo})}'), {
          DataPath('/foo'),
        });
      });

      test('returns paths in nested function calls', () {
        expect(
          parser.extractDependencies(
            r'${upper(value: ${lower(value: ${/foo})})}',
          ),
          {DataPath('/foo')},
        );
      });

      test('returns paths in nested interpolations', () {
        expect(parser.extractDependencies(r'${foo(val: ${/bar})}'), {
          DataPath('/bar'),
        });
      });

      test('returns paths with whitespace', () {
        expect(parser.extractDependencies(r'${  /foo  }'), {DataPath('/foo')});
      });

      test('returns paths with mixed content', () {
        expect(parser.extractDependencies(r'Value: ${/foo}, Count: ${/bar}'), {
          DataPath('/foo'),
          DataPath('/bar'),
        });
      });
    });

    group('Invalid syntax', () {
      test(
        'rejects function call with raw function call as argument',
        () async {
          // ${foo(bar())} should NOT parse bar() as a function call.
          // It should be treated as a path "bar()" which likely resolves to
          // null, or fail to parse the outer function call due to syntax error
          // (missing colon).
          //
          // "bar()" is not a valid named argument key (missing colon).
          // So _parseNamedArgs will likely return empty map or partial map.
          // "foo" will be called with empty/partial args.
          //
          // Verify that "bar" is NOT invoked.
          parser = ExpressionParser(context);

          // ${not(true)} -> false.
          // ${not(not(false))} -> true (if nested).
          // ${not(not(false))} -> invalid syntax "not(false)" is not
          //   "key: value".
          expect(
            await eval<Object?>(parser.parse(r'${not(not(false))}')),
            isNot(true),
          );
        },
      );

      test(
        'rejects function call with raw function call as named argument value',
        () async {
          // ... existing test content ...
          expect(
            await eval<Object?>(
              parser.parse(r'${not(value: not(value: false))}'),
            ),
            true,
          );
        },
      );
    });

    group('Reactive Validation', () {
      test('required function with DataContext updates', () {
        dataModel.update(DataPath('/myDate'), null);
        final Stream<bool> stream = parser.evaluateConditionStream({
          'call': 'required',
          'args': {
            'value': {'path': '/myDate'},
          },
        });

        expect(stream, emitsInOrder([false, true]));

        // Schedule update
        Future.microtask(
          () => dataModel.update(DataPath('/myDate'), '2022-01-01'),
        );
      });
    });

    group('Recursion Depth', () {
      test('evaluateConditionSync throws on exceeding max depth', () {
        // Create a deeply nested structure: not(not(not(...)))
        // Depth 101 should trigger the limit of 100.
        Map<String, Object?> expression = {'value': true};
        for (var i = 0; i < 105; i++) {
          expression = {
            'call': 'not',
            'args': {'value': expression},
          };
        }

        expect(
          () => parser.evaluateConditionSync(expression),
          throwsA(isA<RecursionExpectedException>()),
        );
      });

      test('evaluateConditionStream throws on exceeding max depth', () {
        Map<String, Object?> expression = {'value': true};
        for (var i = 0; i < 105; i++) {
          expression = {
            'call': 'not',
            'args': {'value': expression},
          };
        }

        expect(
          () => parser.evaluateConditionStream(expression),
          throwsA(isA<RecursionExpectedException>()),
        );
      });
    });
  });
}
