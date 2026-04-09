// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/src/core/data_model.dart';
import 'package:a2ui_core/src/primitives/errors.dart';
import 'package:a2ui_core/src/primitives/reactivity.dart';
import 'package:test/test.dart';

void main() {
  group('DataModel', () {
    test('gets and sets root data', () {
      final model = DataModel({'foo': 'bar'});
      expect(model.get('/'), {'foo': 'bar'});

      model.set('/', {'baz': 'qux'});
      expect(model.get('/'), {'baz': 'qux'});
    });

    test('gets and sets nested data', () {
      final model = DataModel();
      model.set('/user/name', 'Alice');
      expect(model.get('/user/name'), 'Alice');
      expect(model.get('/user'), {'name': 'Alice'});
    });

    test('auto-vivifies maps and lists', () {
      final model = DataModel();
      model.set('/users/0/name', 'Alice');
      expect(model.get('/users'), isA<List<dynamic>>());
      expect(model.get('/users/0'), isA<Map<dynamic, dynamic>>());
      expect(model.get('/users/0/name'), 'Alice');
    });

    test('notifies exact path changes', () {
      final model = DataModel();
      final ReadonlySignal<Object?> watch = model.watch('/foo');
      var changeCount = 0;
      watch.subscribe((_) => changeCount++);
      changeCount = 0; // ignore initial subscribe callback

      model.set('/foo', 'bar');
      expect(changeCount, 1);
      expect(watch.value, 'bar');
    });

    test('notifies ancestor changes (bubble)', () {
      final model = DataModel();
      final ReadonlySignal<Object?> watch = model.watch('/user');
      var changeCount = 0;
      watch.subscribe((_) => changeCount++);
      changeCount = 0;

      model.set('/user/name', 'Alice');
      expect(changeCount, 1);
      expect(watch.value, {'name': 'Alice'});
    });

    test('notifies descendant changes (cascade)', () {
      final model = DataModel();
      model.set('/user', {'name': 'Alice'});

      final ReadonlySignal<Object?> watch = model.watch('/user/name');
      var changeCount = 0;
      watch.subscribe((_) => changeCount++);
      changeCount = 0;

      model.set('/user', {'name': 'Bob'});
      expect(changeCount, 1);
      expect(watch.value, 'Bob');
    });

    test('notifies root watch on any change', () {
      final model = DataModel();
      final ReadonlySignal<Object?> watch = model.watch('/');
      var changeCount = 0;
      watch.subscribe((_) => changeCount++);
      changeCount = 0;

      model.set('/foo', 'bar');
      expect(changeCount, 1);
    });

    test('removes keys when setting null', () {
      final model = DataModel({'foo': 'bar'});
      model.set('/foo', null);
      expect(model.get('/'), isEmpty);
    });

    test('rejects excessively large list indices to prevent OOM', () {
      final model = DataModel();
      expect(
        () => model.set('/items/999999999/name', 'x'),
        throwsA(isA<A2uiDataError>()),
      );
      expect(
        () => model.set('/items/999999999', 'x'),
        throwsA(isA<A2uiDataError>()),
      );
    });
  });
}
