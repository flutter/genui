// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/data_model.dart';

void main() {
  group('DataPath', () {
    test('parses absolute paths', () {
      final path = DataPath('/a/b');
      expect(path.isAbsolute, isTrue);
      expect(path.segments, ['a', 'b']);
    });

    test('parses relative paths', () {
      final path = DataPath('a/b');
      expect(path.isAbsolute, isFalse);
      expect(path.segments, ['a', 'b']);
    });

    test('parses root path', () {
      final path = DataPath('/');
      expect(path.isAbsolute, isTrue);
      expect(path.segments, isEmpty);
    });

    test('parses empty path', () {
      final path = DataPath('');
      expect(path.isAbsolute, isFalse);
      expect(path.segments, isEmpty);
    });

    test('toString formats absolute paths', () {
      final path = DataPath('/a/b');
      expect(path.toString(), '/a/b');
    });

    test('toString formats relative paths', () {
      final path = DataPath('a/b');
      expect(path.toString(), 'a/b');
    });

    test('basename returns the last segment', () {
      final path = DataPath('/a/b');
      expect(path.basename, 'b');
    });

    test('dirname returns the parent path', () {
      final path = DataPath('/a/b/c');
      expect(path.dirname, DataPath('/a/b'));
    });

    test('join combines paths', () {
      final path1 = DataPath('/a');
      final path2 = DataPath('b/c');
      expect(path1.join(path2), DataPath('/a/b/c'));
    });

    test('join with absolute path returns the absolute path', () {
      final path1 = DataPath('/a');
      final path2 = DataPath('/b/c');
      expect(path1.join(path2), DataPath('/b/c'));
    });

    test('startsWith returns true for prefixes', () {
      final path = DataPath('/a/b/c');
      expect(path.startsWith(DataPath('/a/b')), isTrue);
    });

    test('startsWith returns false for non-prefixes', () {
      final path = DataPath('/a/b/c');
      expect(path.startsWith(DataPath('/a/c')), isFalse);
    });

    test('equality works correctly', () {
      expect(DataPath('/a/b'), DataPath('/a/b'));
      expect(DataPath('/a/b'), isNot(DataPath('a/b')));
    });
  });

  group('DataContext', () {
    late DataModel dataModel;
    late DataContext rootContext;

    setUp(() {
      dataModel = DataModel();
      rootContext = DataContext(dataModel, '/');
    });

    test('resolves absolute paths', () {
      final path = DataPath('/a/b');
      expect(rootContext.resolvePath(path), path);
    });

    test('resolves relative paths', () {
      final path = DataPath('a/b');
      expect(rootContext.resolvePath(path), DataPath('/a/b'));
    });

    test('nested creates a new context', () {
      final DataContext nested = rootContext.nested(DataPath('a'));
      expect(nested.path, DataPath('/a'));
    });
  });

  group('DataModel', () {
    late DataModel dataModel;

    setUp(() {
      dataModel = DataModel();
    });

    test('update with null path replaces the model', () {
      dataModel.update(null, {'a': 1});
      expect(dataModel.getValue<int>(DataPath('/a')), 1);
    });

    test('update with root path replaces the model', () {
      dataModel.update(DataPath.root, {'a': 1});
      expect(dataModel.getValue<int>(DataPath('/a')), 1);
    });

    test('update sets a value', () {
      dataModel.update(DataPath('/a'), 1);
      expect(dataModel.getValue<int>(DataPath('/a')), 1);
    });

    test('update sets a nested value', () {
      dataModel.update(DataPath('/a/b'), 1);
      expect(dataModel.getValue<int>(DataPath('/a/b')), 1);
    });

    test('getValue returns null for non-existent paths', () {
      expect(dataModel.getValue<Object?>(DataPath('/a')), isNull);
    });

    group('subscribe', () {
      test('notifies on direct updates', () {
        final ValueNotifier<int?> notifier = dataModel.subscribe<int>(
          DataPath('/a'),
        );
        int? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a'), 1);
        expect(value, 1);
      });

      test('notifies on child updates', () {
        final ValueNotifier<Map<Object?, Object?>?> notifier = dataModel
            .subscribe<Map<Object?, Object?>>(DataPath('/a'));
        Map<Object?, Object?>? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a/b'), 1);
        expect(value, {'b': 1});
      });

      test('notifies on parent updates', () {
        dataModel.update(DataPath('/a/b'), 1);
        final ValueNotifier<int?> notifier = dataModel.subscribe<int>(
          DataPath('/a/b'),
        );
        int? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a'), {'b': 2});
        expect(value, 2);
      });
    });

    group('subscribeToValue', () {
      test('notifies on direct updates', () {
        final ValueNotifier<int?> notifier = dataModel.subscribeToValue<int>(
          DataPath('/a'),
        );
        int? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a'), 1);
        expect(value, 1);
      });

      test('does not notify on child updates', () {
        final ValueNotifier<Map<Object?, Object?>?> notifier = dataModel
            .subscribeToValue<Map<Object?, Object?>>(DataPath('/a'));
        var callCount = 0;
        notifier.addListener(() => callCount++);
        dataModel.update(DataPath('/a/b'), 1);
        expect(callCount, 0);
      });

      test('does not notify on parent updates', () {
        dataModel.update(DataPath('/a/b'), 1);
        final ValueNotifier<int?> notifier = dataModel.subscribeToValue<int>(
          DataPath('/a/b'),
        );
        var callCount = 0;
        notifier.addListener(() => callCount++);
        dataModel.update(DataPath('/a'), {'b': 2});
        expect(callCount, 0);
      });
    });

    group('DataModel Update Parsing', () {
      test('parses contents with valueString', () {
        dataModel.update(DataPath.root, <Object?>[
          {'key': 'a', 'valueString': 'hello'},
        ]);
        expect(dataModel.getValue<String>(DataPath('/a')), 'hello');
      });

      test('parses contents with valueNumber', () {
        dataModel.update(DataPath.root, <Object?>[
          {'key': 'b', 'valueNumber': 123},
        ]);
        expect(dataModel.getValue<int>(DataPath('/b')), 123);
      });

      test('parses contents with valueBoolean', () {
        dataModel.update(DataPath.root, <Object?>[
          {'key': 'c', 'valueBoolean': true},
        ]);
        expect(dataModel.getValue<bool>(DataPath('/c')), isTrue);
      });

      test('parses contents with valueMap', () {
        dataModel.update(DataPath.root, <Object?>[
          {
            'key': 'd',
            'valueMap': <Object?>[
              {'key': 'd1', 'valueString': 'v1'},
              {'key': 'd2', 'valueNumber': 2},
            ],
          },
        ]);
        expect(dataModel.getValue<Map<Object?, Object?>>(DataPath('/d')), {
          'd1': 'v1',
          'd2': 2,
        });
      });

      test('is permissive with multiple value types', () {
        dataModel.update(DataPath.root, <Object?>[
          {'key': 'e', 'valueString': 'first', 'valueNumber': 999},
        ]);
        expect(dataModel.getValue<String>(DataPath('/e')), 'first');
      });

      test('handles empty contents array', () {
        dataModel.update(DataPath('/a'), {'b': 1}); // Initial data
        dataModel.update(DataPath.root, <Object?>[]);
        expect(dataModel.data, isEmpty);
      });

      test('handles contents with no value field', () {
        dataModel.update(DataPath.root, <Object?>[
          {'key': 'f'},
        ]);
        expect(dataModel.getValue<Object?>(DataPath('/f')), isNull);
      });
    });
  });

  group('DataModel _getValue and _updateValue consistency', () {
    late DataModel dataModel;

    setUp(() {
      dataModel = DataModel();
    });

    test('Map: set and get', () {
      dataModel.update(DataPath('/a/b'), 1);
      expect(dataModel.getValue<int>(DataPath('/a/b')), 1);
    });

    test('List: set and get', () {
      dataModel.update(DataPath('/a/0'), 'hello');
      expect(dataModel.getValue<String>(DataPath('/a/0')), 'hello');
    });

    test('List: append and get', () {
      dataModel.update(DataPath('/a/0'), 'hello');
      dataModel.update(DataPath('/a/1'), 'world');
      expect(dataModel.getValue<String>(DataPath('/a/0')), 'hello');
      expect(dataModel.getValue<String>(DataPath('/a/1')), 'world');
    });

    test('Nested Map/List: set and get', () {
      dataModel.update(DataPath('/a/b/0/c'), 123);
      expect(dataModel.getValue<int>(DataPath('/a/b/0/c')), 123);
    });

    test('Map: non-existent key returns null', () {
      dataModel.update(DataPath('/a/b'), 1);
      expect(dataModel.getValue<int>(DataPath('/a/c')), isNull);
    });

    test('List: out of bounds index returns null', () {
      dataModel.update(DataPath('/a/0'), 'hello');
      expect(dataModel.getValue<String>(DataPath('/a/1')), isNull);
    });

    test('List: update existing index', () {
      dataModel.update(DataPath('/a/0'), 'hello');
      dataModel.update(DataPath('/a/0'), 'world');
      expect(dataModel.getValue<String>(DataPath('/a/0')), 'world');
    });

    test('Empty path on getValue returns current data', () {
      dataModel.update(DataPath('/a'), {'b': 1});
      expect(dataModel.getValue<Map<Object?, Object?>>(DataPath('/a')), {
        'b': 1,
      });
    });

    test('Nested structures are created automatically', () {
      dataModel.update(DataPath('/a/b/0/c'), 123);
      expect(
        dataModel.getValue<int>(DataPath('/a/b/0/c')),
        123,
        reason: 'Should create nested map and list',
      );

      dataModel.update(DataPath('/x/y/z'), 'hello');
      expect(
        dataModel.getValue<String>(DataPath('/x/y/z')),
        'hello',
        reason: 'Should create nested maps',
      );

      dataModel.update(DataPath('/list/0/0'), 'inner list');
      expect(
        dataModel.getValue<String>(DataPath('/list/0/0')),
        'inner list',
        reason: 'Should create nested lists',
      );
    });
  });
}
