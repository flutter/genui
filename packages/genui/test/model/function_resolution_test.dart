// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/catalog/basic_functions.dart';
import 'package:genui/src/model/data_model.dart';

void main() {
  group('DataContext Function Resolution', () {
    late DataModel dataModel;
    late DataContext context;

    setUp(() {
      dataModel = DataModel();
      context = DataContext(dataModel, '/', functions: BasicFunctions.all);
    });

    test('resolves simple function call', () async {
      final Map<String, Object> input = {
        'call': 'formatNumber',
        'args': {'value': 1234.56, 'decimalPlaces': 1},
      };
      final String result = await eval<String>(input, context);
      expect(result, isA<String>());
    });

    test('resolves required function returning boolean', () async {
      final Map<String, Object> input = {
        'call': 'required',
        'args': {'value': 'some value'},
      };
      expect(await eval<bool>(input, context), isTrue);
    });

    test('resolves nested function calls', () async {
      final Map<String, Object> input = {
        'call': 'required',
        'args': {
          'value': {
            'call': 'formatString',
            'args': {'value': ''},
          },
        },
      };
      // formatString('') -> ''
      // required('') -> false
      expect(await eval<bool>(input, context), isFalse);
    });

    test('resolves arguments with expressions', () async {
      dataModel.update(DataPath('/name'), 'World');
      final Map<String, Object> input = {
        'call': 'formatString',
        'args': {'value': r'Hello ${/name}'},
      };
      expect(await eval<String>(input, context), 'Hello World');
    });

    test('returns original object if not a function call', () {
      final input = {'other': 'value'};
      // resolve should return the object itself if not a function call.
      // But context.resolve is void? No, it returns Object?.
      expect(context.resolve(input), input);
    });
  });
}

Future<T> eval<T>(Object? input, DataContext context) async {
  final Object? result = context.resolve(input);
  if (result is Stream) {
    return (await result.first) as T;
  }
  return result as T;
}
