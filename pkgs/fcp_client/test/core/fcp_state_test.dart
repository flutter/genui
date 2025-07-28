import 'package:fcp_client/src/core/data_type_validator.dart';
import 'package:fcp_client/src/core/fcp_state.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FcpState', () {
    late WidgetLibraryManifest manifest;

    setUp(() {
      manifest = WidgetLibraryManifest({
        'manifestVersion': '1.0.0',
        'widgets': {},
      });
    });

    test('getValue retrieves top-level values', () {
      final state = FcpState(
        {'name': 'test', 'value': 123},
        validator: DataTypeValidator(),
        manifest: manifest,
      );
      expect(state.getValue('name'), 'test');
      expect(state.getValue('value'), 123);
    });

    test('getValue retrieves nested values', () {
      final state = FcpState(
        {
          'user': {
            'name': 'John Doe',
            'address': {'city': 'New York'},
          },
        },
        validator: DataTypeValidator(),
        manifest: manifest,
      );
      expect(state.getValue('user.name'), 'John Doe');
      expect(state.getValue('user.address.city'), 'New York');
    });

    test('getValue returns null for non-existent paths', () {
      final state = FcpState(
        {
          'user': {'name': 'John Doe'},
        },
        validator: DataTypeValidator(),
        manifest: manifest,
      );
      expect(state.getValue('user.age'), isNull);
      expect(state.getValue('address'), isNull);
      expect(state.getValue('user.address.city'), isNull);
    });

    test('getValue returns null for invalid paths', () {
      final state = FcpState(
        {'user': 'John Doe'},
        validator: DataTypeValidator(),
        manifest: manifest,
      );
      expect(state.getValue('user.name'), isNull);
    });

    test('state setter notifies listeners', () {
      final state = FcpState(
        {'value': 1},
        validator: DataTypeValidator(),
        manifest: manifest,
      );
      var notified = false;
      state.addListener(() {
        notified = true;
      });

      state.state = {'value': 2};
      expect(state.getValue('value'), 2);
      expect(notified, isTrue);
    });
  });
}
