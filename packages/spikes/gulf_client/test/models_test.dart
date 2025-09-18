// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:gulf_client/src/models/component.dart';
import 'package:gulf_client/src/models/stream_message.dart';

void main() {
  group('GULF Models', () {
    test('ComponentUpdate can be deserialized', () {
      final json = {
        'componentUpdate': {
          'components': [
            {
              'id': 'test',
              'componentProperties': {
                'Text': {
                  'text': {'literalString': 'Hello'},
                },
              },
            },
          ],
        },
      };
      final message = GulfStreamMessage.fromJson(json);
      expect(message, isA<ComponentUpdate>());
      final componentUpdate = message as ComponentUpdate;
      expect(componentUpdate.components.length, 1);
      expect(componentUpdate.components.first.id, 'test');
      expect(
        componentUpdate.components.first.componentProperties,
        isA<TextProperties>(),
      );
      final textProperties =
          componentUpdate.components.first.componentProperties
              as TextProperties;
      expect(textProperties.text.literalString, 'Hello');
    });

    test('DataModelUpdate can be deserialized', () {
      final json = {
        'dataModelUpdate': {'path': 'user.name', 'contents': 'John Doe'},
      };
      final message = GulfStreamMessage.fromJson(json);
      expect(message, isA<DataModelUpdate>());
      final dataModelUpdate = message as DataModelUpdate;
      expect(dataModelUpdate.path, 'user.name');
      expect(dataModelUpdate.contents, 'John Doe');
    });

    test('BeginRendering can be deserialized', () {
      final json = {
        'beginRendering': {'root': 'root_id'},
      };
      final message = GulfStreamMessage.fromJson(json);
      expect(message, isA<BeginRendering>());
      final beginRendering = message as BeginRendering;
      expect(beginRendering.root, 'root_id');
    });

    test('StreamHeader can be deserialized', () {
      final json = {
        'streamHeader': {'version': '1.0.0'},
      };
      final message = GulfStreamMessage.fromJson(json);
      expect(message, isA<StreamHeader>());
      final streamHeader = message as StreamHeader;
      expect(streamHeader.version, '1.0.0');
    });
  });
}
