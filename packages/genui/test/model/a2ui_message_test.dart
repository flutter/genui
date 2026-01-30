// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/a2ui_message.dart';
import 'package:genui/src/primitives/simple_items.dart';

void main() {
  group('A2uiMessage', () {
    test('CreateSurface.fromJson parses correctly', () {
      final Map<String, Map<String, Object>> json = {
        'createSurface': {
          surfaceIdKey: 's1',
          'catalogId': 'catalog1',
          'theme': {'color': 'blue'},
          'attachDataModel': true,
        },
      };

      final message = A2uiMessage.fromJson(json);
      expect(message, isA<CreateSurface>());
      final create = message as CreateSurface;
      expect(create.surfaceId, 's1');
      expect(create.catalogId, 'catalog1');
      expect(create.theme, {'color': 'blue'});
      expect(create.attachDataModel, isTrue);
    });

    test('UpdateComponents.fromJson parses correctly', () {
      final Map<String, Map<String, Object>> json = {
        'updateComponents': {
          surfaceIdKey: 's1',
          'components': [
            {'id': 'c1', 'component': 'Text', 'text': 'Hello'},
          ],
        },
      };

      final message = A2uiMessage.fromJson(json);
      expect(message, isA<UpdateComponents>());
      final update = message as UpdateComponents;
      expect(update.surfaceId, 's1');
      expect(update.components.length, 1);
      expect(update.components.first.id, 'c1');
      expect(update.components.first.type, 'Text');
    });

    test('UpdateDataModel.fromJson parses correctly', () {
      final Map<String, Map<String, String>> json = {
        'updateDataModel': {
          surfaceIdKey: 's1',
          'path': '/user/name',
          'value': 'Alice',
        },
      };

      final message = A2uiMessage.fromJson(json);
      expect(message, isA<UpdateDataModel>());
      final update = message as UpdateDataModel;
      expect(update.surfaceId, 's1');
      expect(update.path, '/user/name');
      expect(update.value, 'Alice');
    });

    test('DeleteSurface.fromJson parses correctly', () {
      final Map<String, Map<String, String>> json = {
        'deleteSurface': {surfaceIdKey: 's1'},
      };

      final message = A2uiMessage.fromJson(json);
      expect(message, isA<DeleteSurface>());
      final delete = message as DeleteSurface;
      expect(delete.surfaceId, 's1');
    });

    test('CreateSurface.toJson includes version', () {
      const message = CreateSurface(surfaceId: 's1', catalogId: 'c1');
      expect(message.toJson(), containsPair('version', 'v0.9'));
    });

    test('UpdateComponents.toJson includes version', () {
      const message = UpdateComponents(surfaceId: 's1', components: []);
      expect(message.toJson(), containsPair('version', 'v0.9'));
    });

    test('UpdateDataModel.toJson includes version', () {
      const message = UpdateDataModel(surfaceId: 's1');
      expect(message.toJson(), containsPair('version', 'v0.9'));
    });

    test('DeleteSurface.toJson includes version', () {
      const message = DeleteSurface(surfaceId: 's1');
      expect(message.toJson(), containsPair('version', 'v0.9'));
    });

    test('fromJson throws on unknown message type', () {
      final json = <String, Object>{'unknown': {}};
      expect(
        () => A2uiMessage.fromJson(json),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown A2UI message type'),
          ),
        ),
      );
    });
  });
}
