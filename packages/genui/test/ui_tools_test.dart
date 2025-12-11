// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('UI Tools', () {
    late A2uiMessageProcessor a2uiMessageProcessor;
    late Catalog catalog;

    setUp(() {
      catalog = CoreCatalogItems.asCatalog();
      a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);
    });

    test('SurfaceUpdateTool sends SurfaceUpdate message', () async {
      final tool = SurfaceUpdateTool(
        handleMessage: a2uiMessageProcessor.handleMessage,
        catalog: catalog,
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
        a2uiMessageProcessor.surfaceUpdates,
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
      a2uiMessageProcessor.handleMessage(
        const BeginRendering(surfaceId: 'testSurface', root: 'root'),
      );

      await future;
    });

    test('BeginRenderingTool sends BeginRendering message', () async {
      final tool = BeginRenderingTool(
        handleMessage: a2uiMessageProcessor.handleMessage,
        catalogId: 'test_catalog',
      );

      final Map<String, String> args = {
        surfaceIdKey: 'testSurface',
        'root': 'root',
      };

      // First, add a component to the surface so that the root can be set.
      a2uiMessageProcessor.handleMessage(
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
        a2uiMessageProcessor.surfaceUpdates,
        emits(
          isA<SurfaceAdded>()
              .having((e) => e.surfaceId, surfaceIdKey, 'testSurface')
              .having(
                (e) => e.definition.rootComponentId,
                'rootComponentId',
                'root',
              )
              .having(
                (e) => e.definition.catalogId,
                'catalogId',
                'test_catalog',
              ),
        ),
      );

      await tool.invoke(args);

      await future; // Wait for the expectation to be met.
    });
  });
}
