import 'package:test/test.dart';
import 'package:a2ui_core/src/state/data_model.dart';
import 'package:a2ui_core/src/common/reactivity.dart';

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
      expect(model.get('/users'), isA<List>());
      expect(model.get('/users/0'), isA<Map>());
      expect(model.get('/users/0/name'), 'Alice');
    });

    test('notifies exact path changes', () {
      final model = DataModel();
      final watch = model.watch('/foo');
      int count = 0;
      watch.addListener(() => count++);

      model.set('/foo', 'bar');
      expect(count, 1);
      expect(watch.value, 'bar');
    });

    test('notifies ancestor changes (bubble)', () {
      final model = DataModel();
      final watch = model.watch('/user');
      int count = 0;
      watch.addListener(() => count++);

      model.set('/user/name', 'Alice');
      expect(count, 1);
      expect(watch.value, {'name': 'Alice'});
    });

    test('notifies descendant changes (cascade)', () {
      final model = DataModel();
      model.set('/user', {'name': 'Alice'});
      
      final watch = model.watch('/user/name');
      int count = 0;
      watch.addListener(() => count++);

      model.set('/user', {'name': 'Bob'});
      expect(count, 1);
      expect(watch.value, 'Bob');
    });

    test('notifies root watch on any change', () {
      final model = DataModel();
      final watch = model.watch('/');
      int count = 0;
      watch.addListener(() => count++);

      model.set('/foo', 'bar');
      expect(count, 1);
    });

    test('removes keys when setting null', () {
      final model = DataModel({'foo': 'bar'});
      model.set('/foo', null);
      expect(model.get('/'), isEmpty);
    });
  });
}
