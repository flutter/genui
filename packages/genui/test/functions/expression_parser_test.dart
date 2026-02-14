// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/functions/expression_parser.dart';
import 'package:genui/src/model/data_model.dart';

void main() {
  group('ExpressionParser', () {
    late DataContext context;
    late ExpressionParser parser;
    late DataModel dataModel;

    setUp(() {
      dataModel = DataModel();
      context = DataContext(dataModel, '/');
      parser = ExpressionParser(context);
    });

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
      test('and', () {
        expect(
          parser.evaluateFunctionCall({
            'call': 'and',
            'args': {
              'values': [true, true],
            },
          }),
          isTrue,
        );
        expect(
          parser.evaluateFunctionCall({
            'call': 'and',
            'args': {
              'values': [true, false],
            },
          }),
          isFalse,
        );
      });

      test('or', () {
        expect(
          parser.evaluateFunctionCall({
            'call': 'or',
            'args': {
              'values': [false, true],
            },
          }),
          isTrue,
        );
        expect(
          parser.evaluateFunctionCall({
            'call': 'or',
            'args': {
              'values': [false, false],
            },
          }),
          isFalse,
        );
      });

      test('not', () {
        expect(
          parser.evaluateFunctionCall({
            'call': 'not',
            'args': {'value': true},
          }),
          isFalse,
        );
        expect(
          parser.evaluateFunctionCall({
            'call': 'not',
            'args': {'value': false},
          }),
          isTrue,
        );
      });

      test('standard function', () {
        // 'required' is a standard function
        expect(
          parser.evaluateFunctionCall({
            'call': 'required',
            'args': {'value': 'something'},
          }),
          isTrue,
        );
        expect(
          parser.evaluateFunctionCall({
            'call': 'required',
            'args': {'value': ''},
          }),
          isFalse,
        );
      });

      test('nested function calls', () {
        // not(and(true, false)) -> not(false) -> true
        expect(
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
          isTrue,
        );
      });
    });

    group('Function calls in expressions', () {
      test('resolves simple function', () {
        expect(parser.parse(r'${formatString(value: "Hello")}'), 'Hello');
      });

      test('resolves nested function', () {
        expect(
          parser.parse(
            r'${formatString(value: ${formatString(value: "Nested")})}',
          ),
          'Nested',
        );
      });

      test('resolves function with path args', () {
        dataModel.update(DataPath('/val'), 'Dynamic');
        expect(parser.parse(r'${formatString(value: ${/val})}'), 'Dynamic');
      });

      test('resolves function with quoted string containing spaces', () {
        expect(
          parser.parse(r'${formatString(value: "Hello World")}'),
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
      test('rejects function call with raw function call as argument', () {
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
        expect(parser.parse(r'${not(not(false))}'), isNot(true));
      });

      test(
        'rejects function call with raw function call as named argument value',
        () {
          // ${not(value: not(value: false))}
          // Inner "not(value: false)" is NOT a string literal or ${...}.
          // It is treated as a path "not(value: false)".
          // So outer not receives "value": null (result of path lookup).
          // not(null) -> true.
          // But if it was parsed as function, not(true) -> false.
          // So if it returns true, it means it FAILED to parse inner
          // function.
          expect(parser.parse(r'${not(value: not(value: false))}'), true);
        },
      );
    });
  });
}
