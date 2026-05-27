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

    test('notifies descendant watches on root changes', () {
      final model = DataModel({
        'user': {'name': 'Alice'},
        'stale': 'present',
      });
      final ReadonlySignal<Object?> nameWatch = model.watch('/user/name');
      final ReadonlySignal<Object?> staleWatch = model.watch('/stale');
      var nameChangeCount = 0;
      var staleChangeCount = 0;
      nameWatch.subscribe((_) => nameChangeCount++);
      staleWatch.subscribe((_) => staleChangeCount++);
      nameChangeCount = 0;
      staleChangeCount = 0;

      model.set('/', {
        'user': {'name': 'Bob'},
      });

      expect(nameChangeCount, 1);
      expect(nameWatch.value, 'Bob');
      expect(staleChangeCount, 1);
      expect(staleWatch.value, isNull);
    });

    test('notifies root watch on root set', () {
      final model = DataModel({'foo': 'bar'});
      final ReadonlySignal<Object?> rootWatch = model.watch('/');
      var changeCount = 0;
      rootWatch.subscribe((_) => changeCount++);
      changeCount = 0;

      model.set('/', {'baz': 'qux'});
      expect(changeCount, 1);
      expect(rootWatch.value, {'baz': 'qux'});
    });

    test('does not notify unrelated paths', () {
      final model = DataModel({'a': 1, 'b': 2});
      final ReadonlySignal<Object?> bWatch = model.watch('/b');
      var bChangeCount = 0;
      bWatch.subscribe((_) => bChangeCount++);
      bChangeCount = 0;

      model.set('/a', 99);
      expect(bChangeCount, 0);
    });

    test('does not notify a sibling whose name shares a prefix', () {
      final model = DataModel({'foo': 1, 'foobar': 2});
      final ReadonlySignal<Object?> foobarWatch = model.watch('/foobar');
      var foobarChangeCount = 0;
      foobarWatch.subscribe((_) => foobarChangeCount++);
      foobarChangeCount = 0;

      model.set('/foo', 99);
      expect(foobarChangeCount, 0);
    });

    test('set(path, null) sets the key to literal null', () {
      final model = DataModel(<String, Object?>{'foo': 'bar', 'baz': 1});
      model.set('/foo', null);
      expect(model.get('/'), {'foo': null, 'baz': 1});
    });

    test('remove(path) deletes the key from a map', () {
      final model = DataModel(<String, Object?>{'foo': 'bar', 'baz': 1});
      model.remove('/foo');
      expect(model.get('/'), {'baz': 1});
    });

    test('remove(path) sets a list index to null and preserves length', () {
      final model = DataModel(<String, Object?>{
        'items': <Object?>['a', 'b', 'c'],
      });
      model.remove('/items/1');
      expect(model.get('/items'), ['a', null, 'c']);
    });

    test('remove(path) is a no-op for non-existent paths', () {
      final model = DataModel(<String, Object?>{'foo': 'bar'});
      model.remove('/nonexistent');
      model.remove('/foo/nested/deep');
      expect(model.get('/'), {'foo': 'bar'});
    });

    test('remove(/) resets the data model to an empty map', () {
      final model = DataModel(<String, Object?>{'foo': 'bar', 'baz': 1});
      model.remove('/');
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

    test(
      'remove(path) no-ops on out-of-bounds or non-numeric list indices',
      () {
        final model = DataModel(<String, Object?>{
          'items': <Object?>['a', 'b'],
        });
        model.remove('/items/999999999');
        model.remove('/items/foo/bar');
        expect(model.get('/items'), ['a', 'b']);
      },
    );

    test('set(path, value) throws when the parent is a primitive', () {
      final model = DataModel();
      model.set('/x', 5);
      expect(() => model.set('/x/y', 'oops'), throwsA(isA<A2uiDataError>()));
    });

    test(
      'set throws when the root is a primitive and the path is non-empty',
      () {
        final model = DataModel();
        model.set('/', 5);
        expect(() => model.set('/x', 'oops'), throwsA(isA<A2uiDataError>()));
      },
    );
  });
}
