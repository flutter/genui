import 'package:fcp_client/src/core/binding_processor.dart';
import 'package:fcp_client/src/core/data_type_validator.dart';
import 'package:fcp_client/src/core/fcp_state.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BindingProcessor', () {
    late FcpState state;
    late BindingProcessor processor;

    setUp(() {
      state = FcpState(
        {
          'user': {'name': 'Alice', 'isPremium': true},
          'status': 'active',
          'count': 42,
        },
        validator: DataTypeValidator(),
        manifest: WidgetLibraryManifest({
          'manifestVersion': '1.0.0',
          'widgets': {
            'Text': {
              'properties': {
                'text': {'type': 'String'},
                'value': {'type': 'int'},
                'age': {'type': 'int'},
              }
            }
          },
        }),
      );
      processor = BindingProcessor(state);
    });

    test('resolves simple path binding', () {
      final binding = Binding.fromJson({'path': 'user.name'});
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Alice');
    });

    test('handles format transformer', () {
      final binding = Binding.fromJson({
        'path': 'user.name',
        'format': 'Welcome, {}!',
      });
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Welcome, Alice!');
    });

    test('handles condition transformer (true case)', () {
      final binding = Binding.fromJson({
        'path': 'user.isPremium',
        'condition': {'if': 'Premium User', 'else': 'Standard User'},
      });
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Premium User');
    });

    test('handles condition transformer (false case)', () {
      state.state = {
        'user': {'isPremium': false},
      };
      final binding = Binding.fromJson({
        'path': 'user.isPremium',
        'condition': {'if': 'Premium User', 'else': 'Standard User'},
      });
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Standard User');
    });

    test('handles map transformer (found case)', () {
      final binding = Binding.fromJson({
        'path': 'status',
        'map': {
          'mapping': {'active': 'Online', 'inactive': 'Offline'},
          'fallback': 'Unknown',
        },
      });
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Online');
    });

    test('handles map transformer (fallback case)', () {
      state.state = {'status': 'away'};
      final binding = Binding.fromJson({
        'path': 'status',
        'map': {
          'mapping': {'active': 'Online', 'inactive': 'Offline'},
          'fallback': 'Unknown',
        },
      });
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Unknown');
    });

    test('handles map transformer with no fallback (miss case)', () {
      state.state = {'status': 'away'};
      final binding = Binding.fromJson({
        'path': 'status',
        'map': {
          'mapping': {'active': 'Online', 'inactive': 'Offline'},
        },
      });
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'text': binding.toJson()},
        }),
      );
      expect(result['text'], isNull);
    });

    test('returns raw value when no transformer is present', () {
      final binding = Binding.fromJson({'path': 'count'});
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'value': binding.toJson()},
        }),
      );
      expect(result['value'], 42);
    });

    test('returns empty map for empty bindings', () {
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Object?>{},
        }),
      );
      expect(result, isEmpty);
    });

    test('returns empty map for null bindings', () {
      final result = processor.process(
        WidgetNode.fromJson({'id': 'w1', 'type': 'Text'}),
      );
      expect(result, isEmpty);
    });

    test('returns default value for a path that does not exist in the state', () {
      final binding = Binding.fromJson({'path': 'user.age'});
      final result = processor.process(
        WidgetNode.fromJson({
          'id': 'w1',
          'type': 'Text',
          'bindings': {'age': binding.toJson()},
        }),
      );
      expect(result['age'], 0);
    });

    group('Scoped Bindings', () {
      final scopedData = {'title': 'Scoped Title', 'value': 100};

      test('resolves item path from scoped data', () {
        final binding = Binding.fromJson({'path': 'item.title'});
        final result = processor.processScoped(
          WidgetNode.fromJson({
            'id': 'w1',
            'type': 'Text',
            'bindings': {'text': binding.toJson()},
          }),
          scopedData,
        );
        expect(result['text'], 'Scoped Title');
      });

      test('resolves global path even when scoped data is present', () {
        final binding = Binding.fromJson({'path': 'user.name'});
        final result = processor.processScoped(
          WidgetNode.fromJson({
            'id': 'w1',
            'type': 'Text',
            'bindings': {'text': binding.toJson()},
          }),
          scopedData,
        );
        expect(result['text'], 'Alice');
      });

      test('applies transformer to scoped data', () {
        final binding = Binding.fromJson({
          'path': 'item.value',
          'format': 'Value: {}',
        });
        final result = processor.processScoped(
          WidgetNode.fromJson({
            'id': 'w1',
            'type': 'Text',
            'bindings': {'text': binding.toJson()},
          }),
          scopedData,
        );
        expect(result['text'], 'Value: 100');
      });

      test('returns default value for item path when scoped data is empty', () {
        final binding = Binding.fromJson({'path': 'item.title'});
        final result = processor.processScoped(
          WidgetNode.fromJson({
            'id': 'w1',
            'type': 'Text',
            'bindings': {'text': binding.toJson()},
          }),
          {},
        );
        expect(result['text'], '');
      });
    });
  });
}
