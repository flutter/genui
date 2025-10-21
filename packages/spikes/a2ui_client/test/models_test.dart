// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_client/src/models/component.dart';
import 'package:a2ui_client/src/models/stream_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A2UI Models', () {
    test('SurfaceUpdate can be deserialized', () {
      final json = {
        'surfaceUpdate': {
          'surfaceId': '1',
          'components': [
            {
              'id': 'test',
              'component': {
                'Text': {
                  'text': {'literalString': 'Hello'},
                },
              },
            },
          ],
        },
      };
      final message = A2uiStreamMessage.fromJson(json);
      expect(message, isA<SurfaceUpdate>());
      final surfaceUpdate = message as SurfaceUpdate;
      expect(surfaceUpdate.components.length, 1);
      expect(surfaceUpdate.components.first.id, 'test');
      expect(
        surfaceUpdate.components.first.component.values.first,
        isA<TextProperties>(),
      );
      final textProperties =
          surfaceUpdate.components.first.component.values.first
              as TextProperties;
      expect(textProperties.text.literalString, 'Hello');
    });

    test('DataModelUpdate can be deserialized', () {
      final json = {
        'dataModelUpdate': {
          'surfaceId': '1',
          'path': 'user.name',
          'contents': 'John Doe',
        },
      };
      final message = A2uiStreamMessage.fromJson(json);
      expect(message, isA<DataModelUpdate>());
      final dataModelUpdate = message as DataModelUpdate;
      expect(dataModelUpdate.path, 'user.name');
      expect(dataModelUpdate.contents, 'John Doe');
    });

    test('BeginRendering can be deserialized', () {
      final json = {
        'beginRendering': {'surfaceId': '1', 'root': 'root_id'},
      };
      final message = A2uiStreamMessage.fromJson(json);
      expect(message, isA<BeginRendering>());
      final beginRendering = message as BeginRendering;
      expect(beginRendering.root, 'root_id');
    });
  });
}
