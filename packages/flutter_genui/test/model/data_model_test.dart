// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/model/data_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataContext', () {
    late DataModel dataModel;
    late DataContext rootContext;

    setUp(() {
      dataModel = DataModel();
      rootContext = DataContext(dataModel, '/');
    });

    test('resolves absolute paths from root', () {
      final context = DataContext(dataModel, '/');
      expect(context.resolvePath('/a/b'), '/a/b');
    });

    test('resolves relative paths from root', () {
      final context = DataContext(dataModel, '/');
      expect(context.resolvePath('a/b'), '/a/b');
    });

    test('resolves absolute paths from nested context', () {
      final context = DataContext(dataModel, '/a');
      expect(context.resolvePath('/b/c'), '/b/c');
    });

    test('resolves relative paths from nested context', () {
      final context = DataContext(dataModel, '/a');
      expect(context.resolvePath('b/c'), '/a/b/c');
    });

    test('nested creates a new context with the correct base path', () {
      final nestedContext = rootContext.nested('a');
      expect(nestedContext.basePath, '/a');
      final deeplyNestedContext = nestedContext.nested('b');
      expect(deeplyNestedContext.basePath, '/a/b');
    });
  });

  group('DataModel', () {
    late DataModel dataModel;

    setUp(() {
      dataModel = DataModel();
    });

    test('update replaces entire model when path is null', () {
      dataModel.update(null, {'a': 1});
      expect(dataModel.getValue<int>('/a'), 1);
    });

    test('update replaces entire model when path is empty', () {
      dataModel.update('', {'a': 1});
      expect(dataModel.getValue<int>('/a'), 1);
    });

    test('update sets value at root', () {
      dataModel.update('/a', 1);
      expect(dataModel.getValue<int>('/a'), 1);
    });

    test('update sets nested value', () {
      dataModel.update('/a/b', 1);
      expect(dataModel.getValue<int>('/a/b'), 1);
    });

    test('update sets value in a list', () {
      dataModel.update('/a', [
        {'b': 1},
      ]);
      dataModel.update('/a[0]/c', 2);
      expect(dataModel.getValue<int>('/a[0]/c'), 2);
    });

    test('getValue returns null for non-existent value', () {
      expect(dataModel.getValue<dynamic>('/a'), null);
    });

    test('subscribe returns a notifier with the initial value', () {
      dataModel.update('/a', 1);
      final notifier = dataModel.subscribe<int>('/a');
      expect(notifier.value, 1);
    });

    test('subscribe returns the same notifier for the same path', () {
      final notifier1 = dataModel.subscribe<dynamic>('/a');
      final notifier2 = dataModel.subscribe<dynamic>('/a');
      expect(notifier1, same(notifier2));
    });

    test('update notifies subscribers', () {
      final notifier = dataModel.subscribe<int>('/a');
      var callCount = 0;
      notifier.addListener(() {
        callCount++;
      });
      dataModel.update('/a', 1);
      expect(callCount, 1);
      expect(notifier.value, 1);
    });

    test('update notifies subscribers of parent paths', () {
      final notifierA = dataModel.subscribe<Map>('/a');
      final notifierB = dataModel.subscribe<int>('/a/b');
      var callCountA = 0;
      var callCountB = 0;
      notifierA.addListener(() {
        callCountA++;
      });
      notifierB.addListener(() {
        callCountB++;
      });
      dataModel.update('/a/b', 1);
      expect(callCountA, 1);
      expect(callCountB, 1);
      expect(notifierA.value, {'b': 1});
      expect(notifierB.value, 1);
    });
  });
}
