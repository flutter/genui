// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

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

    test(
      'getSurfaceController creates a new controller and fires SurfaceAdded',
      () async {
        const surfaceId = 's1';
        final Future<GenUiUpdate> futureAdded = manager.surfaceUpdates.first;

        final SurfaceController controller = manager.getSurfaceController(
          surfaceId,
        );
        expect(controller, isA<SurfaceController>());
        expect(controller.surfaceId, surfaceId);

        final GenUiUpdate update = await futureAdded;
        expect(update, isA<SurfaceAdded>());
        expect(update.controller, same(controller));
      },
    );

    test(
      'getSurfaceController returns the same controller for the same id',
      () {
        const surfaceId = 's1';
        final SurfaceController controller1 = manager.getSurfaceController(
          surfaceId,
        );
        final SurfaceController controller2 = manager.getSurfaceController(
          surfaceId,
        );
        expect(controller1, same(controller2));
      },
    );

    test('handleMessage delegates to the correct SurfaceController', () {
      const surfaceId = 's1';
      final SurfaceController controller = manager.getSurfaceController(
        surfaceId,
      );
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'Text': {'text': 'Hello'},
          },
        ),
      ];
      final message = SurfaceUpdate(
        surfaceId: surfaceId,
        components: components,
      );

      manager.handleMessage(message);

      final UiDefinition? definition = controller.uiDefinitionNotifier.value;
      expect(definition, isNotNull);
      expect(definition!.components['root'], components.first);
    });

    test(
      'handleMessage with SurfaceDeletion removes and disposes controller',
      () async {
        const surfaceId = 's1';
        final SurfaceController controller = manager.getSurfaceController(
          surfaceId,
        );
        final Future<GenUiUpdate> futureRemoved = manager.surfaceUpdates.first;

        manager.handleMessage(const SurfaceDeletion(surfaceId: surfaceId));

        final GenUiUpdate update = await futureRemoved;
        expect(update, isA<SurfaceRemoved>());
        expect(update.controller, same(controller));

        // Verify controller is disposed
        expect(
          () => controller.uiDefinitionNotifier.addListener(() {}),
          throwsA(isA<Error>()),
        );
      },
    );

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

    test('can handle UI event', () async {
      final SurfaceController controller = manager.getSurfaceController(
        'testSurface',
      );
      controller.dataModel.update(DataPath('/myValue'), 'testValue');
      final Future<UserUiInteractionMessage> future = manager.onSubmit.first;
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );
      manager.handleUiEvent(event);
      final UserUiInteractionMessage message = await future;
      expect(message, isA<UserUiInteractionMessage>());
      final String expectedJson = jsonEncode({
        'userAction': {
          'surfaceId': 'testSurface',
          'name': 'testAction',
          'sourceComponentId': 'testWidget',
          'timestamp': now.toIso8601String(),
          'isAction': true,
          'context': {'key': 'value'},
        },
      });
      expect(message.text, expectedJson);
    });
  });
}
