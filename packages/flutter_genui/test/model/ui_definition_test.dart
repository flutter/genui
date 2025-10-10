// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiDefinition', () {
    test('toJson() serializes correctly', () {
      final definition = UiDefinition(
        surfaceId: 'testSurface',
        rootComponentId: 'root',
        components: {
          'root': const Component(
            id: 'root',
            componentProperties: {
              'Text': {'text': 'Hello'},
            },
          ),
        },
      );

      final json = definition.toJson();

      expect(json['surfaceId'], 'testSurface');
      expect(json['rootComponentId'], 'root');
      expect(json['components'], {
        'root': {
          'id': 'root',
          'componentProperties': {
            'Text': {'text': 'Hello'},
          },
        },
      });
    });
  });
}
