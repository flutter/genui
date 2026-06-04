// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/ui_models.dart';
import 'package:genui/src/primitives/simple_items.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  group('UserActionEvent', () {
    test('can be created and read', () {
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );

      expect(event.surfaceId, 'testSurface');
      expect(event.name, 'testAction');
      expect(event.sourceComponentId, 'testWidget');
      expect(event.timestamp, now);
      expect(event.context, {'key': 'value'});
    });

    test('can be created from map and read', () {
      final now = DateTime.now();
      final event = UserActionEvent.fromMap({
        surfaceIdKey: 'testSurface',
        'name': 'testAction',
        'sourceComponentId': 'testWidget',
        'timestamp': now.toIso8601String(),
        'context': {'key': 'value'},
      });

      expect(event.surfaceId, 'testSurface');
      expect(event.name, 'testAction');
      expect(event.sourceComponentId, 'testWidget');
      expect(event.timestamp, now);
      expect(event.context, {'key': 'value'});
    });

    test('can be converted to map', () {
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );

      final JsonMap map = event.toMap();

      expect(map[surfaceIdKey], 'testSurface');
      expect(map['name'], 'testAction');
      expect(map['sourceComponentId'], 'testWidget');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['context'], {'key': 'value'});
    });
  });

  group('SurfaceDefinition', () {
    test('validate throws exception on mismatch', () {
      final component = const Component(
        id: 'test',
        type: 'Text',
        properties: {'text': 'Hello'},
      );
      final surfaceDefinition = SurfaceDefinition(
        surfaceId: 's1',
        components: {'test': component},
      );

      final schema = S.object(
        properties: {
          'components': S.list(
            items: S.object(
              properties: {'component': S.string(constValue: 'Button')},
            ),
          ),
        },
      );

      expect(
        () => surfaceDefinition.validate(schema),
        throwsA(isA<A2uiValidationException>()),
      );
    });

    test('validate passes on correct match', () {
      final component = const Component(
        id: 'test',
        type: 'Text',
        properties: {'text': 'Hello'},
      );
      final surfaceDefinition = SurfaceDefinition(
        surfaceId: 's1',
        components: {'test': component},
      );

      final schema = S.object(
        properties: {
          'components': S.list(
            items: S.object(
              properties: {
                'component': S.string(constValue: 'Text'),
                'text': S.string(),
              },
            ),
          ),
        },
      );

      surfaceDefinition.validate(schema); // Should not throw.
    });

    test('validate enforces primitive types: string', () {
      final component = const Component(
        id: 'test',
        type: 'Text',
        // int instead of string.
        properties: {'text': 42},
      );
      final surfaceDefinition = SurfaceDefinition(
        surfaceId: 's1',
        components: {'test': component},
      );

      final schema = S.object(
        properties: {
          'components': S.list(
            items: S.object(
              properties: {
                'component': S.string(constValue: 'Text'),
                'text': S.string(),
              },
            ),
          ),
        },
      );

      expect(
        () => surfaceDefinition.validate(schema),
        throwsA(
          isA<A2uiValidationException>().having(
            (e) => e.message,
            'message',
            contains('Type mismatch'),
          ),
        ),
      );
    });

    test('validate enforces primitive types: boolean', () {
      final component = const Component(
        id: 'test',
        type: 'Checkbox',
        properties: {'checked': 'true'}, // string instead of bool.
      );
      final surfaceDefinition = SurfaceDefinition(
        surfaceId: 's1',
        components: {'test': component},
      );

      final schema = S.object(
        properties: {
          'components': S.list(
            items: S.object(
              properties: {
                'component': S.string(constValue: 'Checkbox'),
                'checked': S.boolean(),
              },
            ),
          ),
        },
      );

      expect(
        () => surfaceDefinition.validate(schema),
        throwsA(isA<A2uiValidationException>()),
      );
    });

    test('validate enforces primitive types: '
        'number vs integer', () {
      final componentInt = const Component(
        id: 'test1',
        type: 'Slider',
        properties: {'value': 42}, // Valid integer.
      );
      final componentDouble = const Component(
        id: 'test2',
        type: 'Slider',
        properties: {'value': 42.5}, // Valid number, invalid integer.
      );
      // JSON decodes whole numbers like 42.0 to a Dart double; per JSON
      // Schema a double with a zero fractional part is still an integer.
      final componentWholeDouble = const Component(
        id: 'test3',
        type: 'Slider',
        properties: {'value': 42.0},
      );

      final schema = S.object(
        properties: {
          'components': S.list(
            items: S.object(
              properties: {
                'component': S.string(constValue: 'Slider'),
                'value': S.integer(),
              },
            ),
          ),
        },
      );

      SurfaceDefinition(
        surfaceId: 's1',
        components: {'test1': componentInt},
      ).validate(schema);

      SurfaceDefinition(
        surfaceId: 's3',
        components: {'test3': componentWholeDouble},
      ).validate(schema);

      expect(
        () => SurfaceDefinition(
          surfaceId: 's2',
          components: {'test2': componentDouble},
        ).validate(schema),
        throwsA(isA<A2uiValidationException>()),
      );
    });

    test('validate accepts both int and double for number type', () {
      final schema = S.object(
        properties: {
          'components': S.list(
            items: S.object(
              properties: {
                'component': S.string(constValue: 'Slider'),
                'value': S.number(),
              },
            ),
          ),
        },
      );

      for (final value in const <Object>[42, 42.5]) {
        SurfaceDefinition(
          surfaceId: 's1',
          components: {
            'test': Component(
              id: 'test',
              type: 'Slider',
              properties: {'value': value},
            ),
          },
        ).validate(schema);
      }
    });

    test('validate enforces primitive types: array and object', () {
      final component = const Component(
        id: 'test',
        type: 'List',
        properties: {'items': 42}, // int instead of array.
      );
      final surfaceDefinition = SurfaceDefinition(
        surfaceId: 's1',
        components: {'test': component},
      );

      final schema = S.object(
        properties: {
          'components': S.list(
            items: S.object(
              properties: {
                'component': S.string(constValue: 'List'),
                'items': S.list(items: S.string()),
              },
            ),
          ),
        },
      );

      expect(
        () => surfaceDefinition.validate(schema),
        throwsA(isA<A2uiValidationException>()),
      );
    });
  });

  group('SurfaceDefinition extended', () {
    test('copyWith works', () {
      final sd = SurfaceDefinition(
        surfaceId: 's1',
        catalogId: 'c1',
        components: const {},
      );
      final SurfaceDefinition copied = sd.copyWith(catalogId: 'c2');
      expect(copied.surfaceId, 's1');
      expect(copied.catalogId, 'c2');
    });

    test('asContextDescriptionText works', () {
      final sd = SurfaceDefinition(
        surfaceId: 's1',
        components: {
          'root': const Component(
            id: 'root',
            type: 'Text',
            properties: {'text': 'Hello'},
          ),
        },
      );
      final String text = sd.asContextDescriptionText();
      expect(text, contains('Text'));
      expect(text, contains('Hello'));
    });
  });

  group('Component', () {
    test('toJson', () {
      final c = const Component(
        id: 'c1',
        type: 'Button',
        properties: {'label': 'Click'},
      );
      expect(c.toJson(), {'id': 'c1', 'component': 'Button', 'label': 'Click'});
    });
  });
}
