// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiEvent', () {
    test('fromMap and toMap work correctly', () {
      final now = DateTime.now().toUtc();
      final event = UiEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onTap',
        timestamp: now,
        value: 'test value',
      );

      final map = event.toMap();
      final recreatedEvent = UiEvent.fromMap(map);

      expect(recreatedEvent.surfaceId, 's1');
      expect(recreatedEvent.widgetId, 'w1');
      expect(recreatedEvent.eventType, 'onTap');
      expect(recreatedEvent.timestamp, now);
      expect(recreatedEvent.value, 'test value');
    });

    test('toMap handles null value', () {
      final event = UiEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onTap',
        timestamp: DateTime.now(),
      );
      final map = event.toMap();
      expect(map.containsKey('value'), isFalse);
    });
  });

  group('UiDefinition', () {
    test('fromMap correctly parses widget list', () {
      final definitionMap = {
        'surfaceId': 'testSurface',
        'root': 'rootId',
        'widgets': [
          {'id': 'widget1', 'data': 'A'},
          {'id': 'widget2', 'data': 'B'},
        ],
      };

      final definition = UiDefinition.fromMap(definitionMap);

      expect(definition.surfaceId, 'testSurface');
      expect(definition.root, 'rootId');
      expect(definition.widgets.length, 2);
      expect(definition.widgets['widget1'], {'id': 'widget1', 'data': 'A'});
      expect(definition.widgets['widget2'], {'id': 'widget2', 'data': 'B'});
    });
  });
}
