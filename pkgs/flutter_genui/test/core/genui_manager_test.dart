// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/core/core_catalog.dart';
import 'package:flutter_genui/src/core/genui_manager.dart';
import 'package:flutter_genui/src/model/tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenUiManager', () {
    late GenUiManager manager;
    late AiTool addOrUpdateSurfaceTool;
    late AiTool deleteSurfaceTool;

    setUp(() {
      manager = GenUiManager(catalog: coreCatalog);
      addOrUpdateSurfaceTool = manager
          .getTools()
          .firstWhere((tool) => tool.name == 'addOrUpdateSurface');
      deleteSurfaceTool =
          manager.getTools().firstWhere((tool) => tool.name == 'deleteSurface');
    });

    tearDown(() {
      manager.dispose();
    });

    test(
        'addOrUpdateSurface tool adds a new surface and fires SurfaceAdded with definition',
        () async {
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

      final futureUpdate = manager.updates.first;

      await addOrUpdateSurfaceTool.invoke({
        'surfaceId': 's1',
        'definition': definitionMap,
      });

      final update = await futureUpdate;

      expect(update, isA<SurfaceAdded>());
      expect(update.surfaceId, 's1');
      final addedUpdate = update as SurfaceAdded;
      expect(addedUpdate.definition, isNotNull);
      expect(addedUpdate.definition.root, 'root');
      expect(addedUpdate.controller, isNotNull);
      expect(manager.surface('s1').value, isNotNull);
      expect(manager.surface('s1').value!.root, 'root');
    });

    test(
        'addOrUpdateSurface tool updates an existing surface and fires SurfaceUpdated',
        () async {
      final oldDefinition = {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'text': {'text': 'Old'},
            },
          },
        ],
      };
      await addOrUpdateSurfaceTool.invoke({
        'surfaceId': 's1',
        'definition': oldDefinition,
      });

      final newDefinition = {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'text': {'text': 'New'},
            },
          },
        ],
      };

      final futureUpdate = manager.updates.first;
      await addOrUpdateSurfaceTool.invoke({
        'surfaceId': 's1',
        'definition': newDefinition,
      });
      final update = await futureUpdate;

      expect(update, isA<SurfaceUpdated>());
      expect(update.surfaceId, 's1');
      final updatedDefinition = (update as SurfaceUpdated).definition;
      expect(updatedDefinition.widgets['root'], {
        'id': 'root',
        'widget': {
          'text': {'text': 'New'},
        },
      });
      expect(manager.surface('s1').value, updatedDefinition);
    });

    test('deleteSurface tool removes a surface and fires SurfaceRemoved', () async {
      final definition = {
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'widget': {
              'text': {'text': 'Hello'},
            },
          },
        ],
      };
      await addOrUpdateSurfaceTool.invoke({
        'surfaceId': 's1',
        'definition': definition,
      });

      final futureUpdate = manager.updates.first;
      await deleteSurfaceTool.invoke({'surfaceId': 's1'});
      final update = await futureUpdate;

      expect(update, isA<SurfaceRemoved>());
      expect(update.surfaceId, 's1');
      expect(manager.surface('s1').value, isNull);
    });

    test('surface() creates a new ValueNotifier if one does not exist', () {
      final notifier1 = manager.surface('s1');
      final notifier2 = manager.surface('s1');
      expect(notifier1, same(notifier2));
      expect(notifier1.value, isNull);
    });

    test('dispose() closes the updates stream', () async {
      var isClosed = false;
      manager.updates.listen(
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