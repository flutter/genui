// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('UI Tools', () {
    late GenUiManager genUiManager;
    late Catalog catalog;

    setUp(() {
      catalog = CoreCatalogItems.asCatalog();
      genUiManager = GenUiManager(
        catalog: catalog,
        configuration: const GenUiConfiguration(
          actions: ActionsConfig(
            allowCreate: true,
            allowUpdate: true,
            allowDelete: true,
          ),
        ),
      );
    });

    test('SurfaceUpdateTool sends SurfaceUpdate message', () async {
      final tool = SurfaceUpdateTool(
        handleMessage: genUiManager.handleMessage,
        catalog: catalog,
        configuration: const GenUiConfiguration(),
      );

      final Map<String, Object> args = {
        surfaceIdKey: 'testSurface',
        'components': [
          {
            'id': 'root',
            'component': {
              'Text': {
                'text': {'literalString': 'Hello'},
              },
            },
          },
        ],
      };

      final Future<void> future = expectLater(
        genUiManager.surfaceUpdates,
        emits(
          isA<SurfaceAdded>()
              .having((e) => e.surfaceId, surfaceIdKey, 'testSurface')
              .having(
                (e) => e.definition.components.length,
                'components.length',
                1,
              )
              .having(
                (e) => e.definition.components.values.first.id,
                'components.first.id',
                'root',
              ),
        ),
      );

      await tool.invoke(args);
      genUiManager.handleMessage(
        const BeginRendering(surfaceId: 'testSurface', root: 'root'),
      );

      await future;
    });

    test('BeginRenderingTool sends BeginRendering message', () async {
      final tool = BeginRenderingTool(
        handleMessage: genUiManager.handleMessage,
      );

      final Map<String, String> args = {
        surfaceIdKey: 'testSurface',
        'root': 'root',
      };

      // First, add a component to the surface so that the root can be set.
      genUiManager.handleMessage(
        const SurfaceUpdate(
          surfaceId: 'testSurface',
          components: [
            Component(
              id: 'root',
              componentProperties: {
                'Text': {
                  'text': {'literalString': 'Hello'},
                },
              },
            ),
          ],
        ),
      );

      // Use expectLater to wait for the stream to emit the correct event.
      final Future<void> future = expectLater(
        genUiManager.surfaceUpdates,
        emits(
          isA<SurfaceAdded>()
              .having((e) => e.surfaceId, surfaceIdKey, 'testSurface')
              .having(
                (e) => e.definition.rootComponentId,
                'rootComponentId',
                'root',
              ),
        ),
      );

      await tool.invoke(args);

      await future; // Wait for the expectation to be met.
    });
  });
}
