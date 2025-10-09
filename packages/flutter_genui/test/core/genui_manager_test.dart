// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$GenUiManager', () {
    late GenUiManager manager;

    setUp(() {
      manager = GenUiManager(
        catalog: CoreCatalogItems.asCatalog(),
        configuration: const GenUiConfiguration(
          actions: ActionsConfig(
            allowCreate: true,
            allowUpdate: true,
            allowDelete: true,
          ),
        ),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('handleMessage adds a new surface and fires SurfaceAdded with '
        'definition', () async {
      const surfaceId = 's1';
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'Text': {'text': 'Hello'},
          },
        ),
      ];

      final futureUpdate = manager.surfaceUpdates.first;

      manager.handleMessage(
        SurfaceUpdate(surfaceId: surfaceId, components: components),
      );
      manager.handleMessage(
        const BeginRendering(surfaceId: surfaceId, root: 'root'),
      );

      final update = await futureUpdate;

      expect(update, isA<SurfaceAdded>());
      expect(update.surfaceId, surfaceId);
      final addedUpdate = update as SurfaceAdded;
      expect(addedUpdate.definition, isNotNull);
      expect(addedUpdate.definition.rootComponentId, 'root');
      expect(manager.surfaces[surfaceId]!.value, isNotNull);
      expect(manager.surfaces[surfaceId]!.value!.rootComponentId, 'root');
    });

    test(
      'handleMessage updates an existing surface and fires SurfaceUpdated',
      () async {
        const surfaceId = 's1';
        final oldComponents = [
          const Component(
            id: 'root',
            componentProperties: {
              'Text': {'text': 'Old'},
            },
          ),
        ];
        manager.handleMessage(
          SurfaceUpdate(surfaceId: surfaceId, components: oldComponents),
        );

        final newComponents = [
          const Component(
            id: 'root',
            componentProperties: {
              'Text': {'text': 'New'},
            },
          ),
        ];

        final futureUpdate = manager.surfaceUpdates.first;
        manager.handleMessage(
          SurfaceUpdate(surfaceId: surfaceId, components: newComponents),
        );
        final update = await futureUpdate;

        expect(update, isA<SurfaceUpdated>());
        expect(update.surfaceId, surfaceId);
        final updatedDefinition = (update as SurfaceUpdated).definition;
        expect(updatedDefinition.components['root'], newComponents[0]);
        expect(manager.surfaces[surfaceId]!.value, updatedDefinition);
      },
    );

    test('handleMessage removes a surface and fires SurfaceRemoved', () async {
      const surfaceId = 's1';
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'Text': {'text': 'Hello'},
          },
        ),
      ];
      manager.handleMessage(
        SurfaceUpdate(surfaceId: surfaceId, components: components),
      );

      final futureUpdate = manager.surfaceUpdates.first;
      manager.handleMessage(const SurfaceDeletion(surfaceId: surfaceId));
      final update = await futureUpdate;

      expect(update, isA<SurfaceRemoved>());
      expect(update.surfaceId, surfaceId);
      expect(manager.surfaces.containsKey(surfaceId), isFalse);
    });

    test('surface() creates a new ValueNotifier if one does not exist', () {
      final notifier1 = manager.surface('s1');
      final notifier2 = manager.surface('s1');
      expect(notifier1, same(notifier2));
      expect(notifier1.value, isNull);
    });

    test('dispose() closes the updates stream', () async {
      var isClosed = false;
      manager.surfaceUpdates.listen(
        null,
        onDone: () {
          isClosed = true;
        },
      );

      manager.dispose();

      await Future<void>.delayed(Duration.zero);
      expect(isClosed, isTrue);
    });
  });
}
