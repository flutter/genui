// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/model/data_model.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final nested = rootContext.nested(DataPath('a'));
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
        final notifier = dataModel.subscribe<int>(DataPath('/a'));
        int? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a'), 1);
        expect(value, 1);
      });

      test('notifies on child updates', () {
        final notifier = dataModel.subscribe<Map>(DataPath('/a'));
        Map? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a/b'), 1);
        expect(value, {'b': 1});
      });

      test('notifies on parent updates', () {
        dataModel.update(DataPath('/a/b'), 1);
        final notifier = dataModel.subscribe<int>(DataPath('/a/b'));
        int? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a'), {'b': 2});
        expect(value, 2);
      });
    });

    group('subscribeToValue', () {
      test('notifies on direct updates', () {
        final notifier = dataModel.subscribeToValue<int>(DataPath('/a'));
        int? value;
        notifier.addListener(() => value = notifier.value);
        dataModel.update(DataPath('/a'), 1);
        expect(value, 1);
      });

      test('does not notify on child updates', () {
        final notifier = dataModel.subscribeToValue<Map>(DataPath('/a'));
        var callCount = 0;
        notifier.addListener(() => callCount++);
        dataModel.update(DataPath('/a/b'), 1);
        expect(callCount, 0);
      });

      test('does not notify on parent updates', () {
        dataModel.update(DataPath('/a/b'), 1);
        final notifier = dataModel.subscribeToValue<int>(DataPath('/a/b'));
        var callCount = 0;
        notifier.addListener(() => callCount++);
        dataModel.update(DataPath('/a'), {'b': 2});
        expect(callCount, 0);
      });
    });
  });
}
