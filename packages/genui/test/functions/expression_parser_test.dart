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

      test('handles nested braces in generic way (?)', () {
        // The parser logic for nested braces is simple depth counting
        // It should handle ${func({})} if implemented
      });
    });

    group('evaluateLogic', () {
      test('and', () {
        expect(
          parser.evaluateLogic({
            'and': [
              {'true': null},
              {'true': null},
            ],
          }),
          isTrue,
        );
        expect(
          parser.evaluateLogic({
            'and': [
              {'true': null},
              {'false': null},
            ],
          }),
          isFalse,
        );
      });

      test('or', () {
        expect(
          parser.evaluateLogic({
            'or': [
              {'true': null},
              {'false': null},
            ],
          }),
          isTrue,
        );
        expect(
          parser.evaluateLogic({
            'or': [
              {'false': null},
              {'false': null},
            ],
          }),
          isFalse,
        );
      });

      test('not', () {
        expect(
          parser.evaluateLogic({
            'not': {'true': null},
          }),
          isFalse,
        );
        expect(
          parser.evaluateLogic({
            'not': {'false': null},
          }),
          isTrue,
        );
      });

      test('func', () {
        // Need to register a function first or use a standard one
        // Standard 'required' function
        expect(
          parser.evaluateLogic({
            'func': 'required',
            'args': {'value': 'something'},
          }),
          isTrue,
        );
        expect(
          parser.evaluateLogic({
            'func': 'required',
            'args': {'value': ''},
          }),
          isFalse,
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
  });
}
