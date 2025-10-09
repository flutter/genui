// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiEvent', () {
    test('can be created and read', () {
      final now = DateTime.now();
      final event = UiActionEvent(
        surfaceId: 'testSurface',
        widgetId: 'testWidget',
        eventType: 'onTap',
        timestamp: now,
        value: 'testValue',
      );

      expect(event.surfaceId, 'testSurface');
      expect(event.widgetId, 'testWidget');
      expect(event.eventType, 'onTap');
      expect(event.isAction, isTrue);
      expect(event.timestamp, now);
      expect(event.value, 'testValue');
    });

    test('can be created from map and read', () {
      final now = DateTime.now();
      final event = UiEvent.fromMap({
        'surfaceId': 'testSurface',
        'widgetId': 'testWidget',
        'eventType': 'onTap',
        'isAction': false,
        'timestamp': now.toIso8601String(),
        'value': 'testValue',
      });

      expect(event.surfaceId, 'testSurface');
      expect(event.widgetId, 'testWidget');
      expect(event.eventType, 'onTap');
      expect(event.isAction, isFalse);
      expect(event.timestamp, now);
      expect(event.value, 'testValue');
    });

    test('can be converted to map', () {
      final now = DateTime.now();
      final event = UiActionEvent(
        surfaceId: 'testSurface',
        widgetId: 'testWidget',
        eventType: 'onTap',
        timestamp: now,
        value: 'testValue',
      );

      final map = event.toMap();

      expect(map['surfaceId'], 'testSurface');
      expect(map['widgetId'], 'testWidget');
      expect(map['eventType'], 'onTap');
      expect(map['isAction'], isTrue);
      expect(map['timestamp'], now.toIso8601String());
      expect(map['value'], 'testValue');
    });
  });
}
