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
      final uiDef = SurfaceDefinition(
        surfaceId: 's1',
        components: {'test': component},
      );

      // Schema invalidating the component (e.g., expecting type "Button")
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
        () => uiDef.validate(schema),
        throwsA(isA<A2uiValidationException>()),
      );
    });

    test('validate passes on correct match', () {
      final component = const Component(
        id: 'test',
        type: 'Text',
        properties: {'text': 'Hello'},
      );
      final uiDef = SurfaceDefinition(
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

      uiDef.validate(schema); // Should not throw
    });
  });
}
