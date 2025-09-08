// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/primitives/simple_items.dart';
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

    test('addOrUpdateSurface adds a new surface and fires SurfaceAdded with '
        'definition', () async {
      final definitionMap = {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'Text': {'text': 'Hello'},
            },
          },
        ],
      };

      final futureUpdate = manager.surfaceUpdates.first;

      manager.addOrUpdateSurface('s1', definitionMap);

      final update = await futureUpdate;

      expect(update, isA<SurfaceAdded>());
      expect(update.surfaceId, 's1');
      final addedUpdate = update as SurfaceAdded;
      expect(addedUpdate.definition, isNotNull);
      expect(addedUpdate.definition.root, 'root');
      expect(manager.surfaces['s1']!.value, isNotNull);
      expect(manager.surfaces['s1']!.value!.root, 'root');
    });

    test('addOrUpdateSurface with "replace" action updates an existing surface '
        'and fires SurfaceChanged', () async {
      final oldDefinition = {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'Text': {'text': 'Old'},
            },
          },
        ],
      };
      manager.addOrUpdateSurface('s1', oldDefinition);

      final newDefinition = {
        'action': 'replace',
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'Text': {'text': 'New'},
            },
          },
        ],
      };

      final futureUpdate = manager.surfaceUpdates.first;
      manager.addOrUpdateSurface('s1', newDefinition);
      final update = await futureUpdate;

      expect(update, isA<SurfaceChanged>());
      expect(update.surfaceId, 's1');
      final changedUpdate = update as SurfaceChanged;
      expect(
        ((changedUpdate.definition.widgets['root']! as JsonMap)['widget']
            as JsonMap)['Text'],
        {'text': 'New'},
      );
      expect(manager.surfaces['s1']!.value, changedUpdate.definition);
    });

    test('addOrUpdateSurface with "update" action updates an existing surface '
        'and fires SurfaceChanged', () async {
      final oldDefinition = {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'Text': {'text': 'Old'},
            },
          },
          {
            'id': 'child',
            'widget': {
              'Text': {'text': 'Child'},
            },
          },
        ],
      };
      manager.addOrUpdateSurface('s1', oldDefinition);

      final newDefinition = {
        'action': 'update',
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'Text': {'text': 'New'},
            },
          },
        ],
      };

      final futureUpdate = manager.surfaceUpdates.first;
      manager.addOrUpdateSurface('s1', newDefinition);
      final update = await futureUpdate;

      expect(update, isA<SurfaceChanged>());
      expect(update.surfaceId, 's1');
      final changedUpdate = update as SurfaceChanged;
      expect(
        ((changedUpdate.definition.widgets['root']! as JsonMap)['widget']
            as JsonMap)['Text'],
        {'text': 'New'},
      );
      expect(
        ((changedUpdate.definition.widgets['child']! as JsonMap)['widget']
            as JsonMap)['Text'],
        {'text': 'Child'},
      );
      expect(manager.surfaces['s1']!.value, changedUpdate.definition);
    });

    test('deleteSurface removes a surface and fires SurfaceRemoved', () async {
      final definition = {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'Text': {'text': 'Hello'},
            },
          },
        ],
      };
      manager.addOrUpdateSurface('s1', definition);

      final futureUpdate = manager.surfaceUpdates.first;
      manager.deleteSurface('s1');
      final update = await futureUpdate;

      expect(update, isA<SurfaceRemoved>());
      expect(update.surfaceId, 's1');
      expect(manager.surfaces.containsKey('s1'), isFalse);
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
