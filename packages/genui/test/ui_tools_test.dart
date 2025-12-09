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
      genUiManager = GenUiManager(catalogs: [catalog]);
    });

    test('SurfaceUpdateTool sends SurfaceUpdate message', () async {
      final tool = SurfaceUpdateTool(
        handleMessage: genUiManager.handleMessage,
        catalog: catalog,
      );

      final Map<String, Object> args = {
        surfaceIdKey: 'testSurface',
        'components': [
          {
            'id': 'root',
            'props': {
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
          isA<SurfaceUpdated>()
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
      genUiManager.handleMessage(const CreateSurface(surfaceId: 'testSurface'));

      await future;
    });

    test('CreateSurfaceTool sends CreateSurface message', () async {
      final tool = CreateSurfaceTool(handleMessage: genUiManager.handleMessage);

      final Map<String, String> args = {surfaceIdKey: 'testSurface'};

      // First, add a component to the surface so that the root can be set.
      genUiManager.handleMessage(
        const SurfaceUpdate(
          surfaceId: 'testSurface',
          components: [
            Component(
              id: 'root',
              props: {
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
          isA<SurfaceUpdated>().having(
            (e) => e.surfaceId,
            surfaceIdKey,
            'testSurface',
          ),
        ),
      );

      await tool.invoke(args);

      await future; // Wait for the expectation to be met.
    });
  });
}
