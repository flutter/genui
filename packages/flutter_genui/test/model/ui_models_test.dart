// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserActionEvent', () {
    test('can be created and read', () {
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        actionName: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );

      expect(event.surfaceId, 'testSurface');
      expect(event.actionName, 'testAction');
      expect(event.sourceComponentId, 'testWidget');
      expect(event.timestamp, now);
      expect(event.isAction, isTrue);
      expect(event.context, {'key': 'value'});
    });

    test('can be created from map and read', () {
      final now = DateTime.now();
      final event = UserActionEvent.fromMap({
        'surfaceId': 'testSurface',
        'actionName': 'testAction',
        'sourceComponentId': 'testWidget',
        'timestamp': now.toIso8601String(),
        'isAction': true,
        'context': {'key': 'value'},
      });

      expect(event.surfaceId, 'testSurface');
      expect(event.actionName, 'testAction');
      expect(event.sourceComponentId, 'testWidget');
      expect(event.timestamp, now);
      expect(event.isAction, isTrue);
      expect(event.context, {'key': 'value'});
    });

    test('can be converted to map', () {
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        actionName: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );

      final map = event.toMap();

      expect(map['surfaceId'], 'testSurface');
      expect(map['actionName'], 'testAction');
      expect(map['sourceComponentId'], 'testWidget');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['isAction'], isTrue);
      expect(map['context'], {'key': 'value'});
    });
  });
}
