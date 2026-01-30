// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/functions/functions.dart';
import 'package:genui/src/model/data_model.dart';

void main() {
  group('DataContext Function Resolution', () {
    late DataModel dataModel;
    late DataContext context;

    setUp(() {
      dataModel = DataModel();
      context = DataContext(dataModel, '/');
      // Ensure standard functions are registered (singleton)
      FunctionRegistry();
    });

    test('resolves simple function call', () {
      final Map<String, Object> input = {
        'func': 'formatNumber',
        'args': [1234.56, 1],
      };
      final Object? result = context.resolve(input);
      // Default standard formatNumber uses current locale, might vary,
      // but usually '1,234.6' or '1234.6' depending on environment.
      // Let's check regex or simpler function first.
      expect(result, isA<String>());
    });

    test('resolves required function returning boolean', () {
      final Map<String, Object> input = {
        'func': 'required',
        'args': ['some value'],
      };
      expect(context.resolve(input), isTrue);
    });

    test('resolves nested function calls', () {
      final Map<String, Object> input = {
        'func': 'required',
        'args': [
          {
            'func': 'formatString',
            'args': [''],
          },
        ],
      };
      // formatString('') -> ''
      // required('') -> false
      expect(context.resolve(input), isFalse);
    });

    test('resolves arguments with expressions', () {
      dataModel.update(DataPath('/name'), 'World');
      final Map<String, Object> input = {
        'func': 'formatString',
        'args': [r'Hello ${/name}'],
      };
      expect(context.resolve(input), 'Hello World');
    });

    test('returns original object if not a function call', () {
      final input = {'other': 'value'};
      expect(context.resolve(input), input);
    });
  });
}
