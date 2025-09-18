// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/core/genui_configuration.dart';
import 'package:flutter_genui/src/core/ui_tools.dart';
import 'package:flutter_genui/src/model/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddOrUpdateSurfaceTool', () {
    test('invoke calls onAddOrUpdate with correct arguments', () async {
      String? calledSurfaceId;
      Map<String, Object?>? calledDefinition;

      void fakeOnAddOrUpdate(
        String surfaceId,
        Map<String, Object?> definition,
      ) {
        calledSurfaceId = surfaceId;
        calledDefinition = definition;
      }

      final tool = AddOrUpdateSurfaceTool(
        onAddOrUpdate: fakeOnAddOrUpdate,
        catalog: const Catalog([]),
        configuration: const GenUiConfiguration(),
      );

      final args = {
        'surfaceId': 'testSurface',
        'definition': {
          'root': 'rootWidget',
          'widgets': [
            {'id': 'rootWidget', 'type': 'text', 'content': 'Hello'},
          ],
        },
      };

      await tool.invoke(args);

      expect(calledSurfaceId, 'testSurface');
      expect(calledDefinition, args['definition']);
    });
  });

  group('DeleteSurfaceTool', () {
    test('invoke calls onDelete with correct arguments', () async {
      String? calledSurfaceId;

      void fakeOnDelete(String surfaceId) {
        calledSurfaceId = surfaceId;
      }

      final tool = DeleteSurfaceTool(onDelete: fakeOnDelete);

      final args = {'surfaceId': 'testSurface'};

      await tool.invoke(args);

      expect(calledSurfaceId, 'testSurface');
    });
  });
}
