// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('$A2uiMessageProcessor', () {
    late A2uiMessageProcessor messageProcessor;

    setUp(() {
      messageProcessor = A2uiMessageProcessor(
        catalogs: [CoreCatalogItems.asCatalog()],
      );
    });

    tearDown(() {
      messageProcessor.dispose();
    });

    test('can be initialized with multiple catalogs', () {
      final catalog1 = const Catalog([], catalogId: 'cat1');
      final catalog2 = const Catalog([], catalogId: 'cat2');
      final multiManager = A2uiMessageProcessor(catalogs: [catalog1, catalog2]);
      expect(multiManager.catalogs, contains(catalog1));
      expect(multiManager.catalogs, contains(catalog2));
      expect(multiManager.catalogs.length, 2);
    });

    test('handleMessage adds a new surface and fires SurfaceAdded with '
        'definition', () async {
      const surfaceId = 's1';
      final components = [
        const Component(
          id: 'root',
          props: {'component': 'Text', 'text': 'Hello'},
        ),
      ];

      messageProcessor.handleMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );

      final Future<GenUiUpdate> futureUpdated = messageProcessor.surfaceUpdates.first;
      messageProcessor.handleMessage(
        const CreateSurface(surfaceId: surfaceId, catalogId: standardCatalogId),
      );
      final GenUiUpdate updatedUpdate = await futureUpdated;

      expect(updatedUpdate, isA<SurfaceUpdated>());
      expect(updatedUpdate.surfaceId, surfaceId);
      final UiDefinition definition =
          (updatedUpdate as SurfaceUpdated).definition;
      expect(definition, isNotNull);
      // expect(definition.rootComponentId, 'root'); // CreateSurface no longer sets root
      expect(messageProcessor.surfaces[surfaceId]!.value, isNotNull);
      // expect(manager.surfaces[surfaceId]!.value!.rootComponentId, 'root');
    });

    test(
      'handleMessage fires SurfaceAdded when CreateSurface is received for a '
      'new surface',
      () async {
        const surfaceId = 'newSurface';
        final Future<GenUiUpdate> futureUpdate = messageProcessor.surfaceUpdates.first;
        messageProcessor.handleMessage(
          const CreateSurface(
            surfaceId: surfaceId,
            catalogId: standardCatalogId,
          ),
        );
        final GenUiUpdate update = await futureUpdate;

        expect(update, isA<SurfaceAdded>());
        expect(update.surfaceId, surfaceId);
      },
    );

    test('handleMessage updates surface when UpdateComponents follows '
        'CreateSurface', () async {
      const surfaceId = 's2';
      // 1. CreateSurface
      final Future<GenUiUpdate> futureCreate = messageProcessor.surfaceUpdates.first;
      messageProcessor.handleMessage(
        const CreateSurface(surfaceId: surfaceId, catalogId: standardCatalogId),
      );
      final GenUiUpdate createUpdate = await futureCreate;
      expect(createUpdate, isA<SurfaceAdded>());

      // 2. UpdateComponents
      final components = [
        const Component(
          id: 'root',
          props: {'component': 'Text', 'text': 'Updated'},
        ),
      ];
      final Future<GenUiUpdate> futureUpdate = messageProcessor.surfaceUpdates.first;
      messageProcessor.handleMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );
      final GenUiUpdate update = await futureUpdate;

      expect(update, isA<SurfaceUpdated>());
      expect(update.surfaceId, surfaceId);
      final UiDefinition definition = (update as SurfaceUpdated).definition;
      expect(definition.components['root'], components[0]);
    });

    test(
      'handleMessage updates an existing surface and fires SurfaceUpdated',
      () async {
        const surfaceId = 's1';
        final oldComponents = [
          const Component(
            id: 'root',
            props: {'component': 'Text', 'text': 'Old'},
          ),
        ];
        final newComponents = [
          const Component(
            id: 'root',
            props: {'component': 'Text', 'text': 'New'},
          ),
        ];

        final Future<void> expectation = expectLater(
          messageProcessor.surfaceUpdates,
          emitsInOrder([isA<SurfaceUpdated>(), isA<SurfaceUpdated>()]),
        );

        messageProcessor.handleMessage(
          UpdateComponents(surfaceId: surfaceId, components: oldComponents),
        );
        messageProcessor.handleMessage(
          const CreateSurface(
            surfaceId: surfaceId,
            catalogId: standardCatalogId,
          ),
        );
        messageProcessor.handleMessage(
          UpdateComponents(surfaceId: surfaceId, components: newComponents),
        );

        await expectation;
      },
    );

    test('handleMessage removes a surface and fires SurfaceRemoved', () async {
      const surfaceId = 's1';
      final components = [
        const Component(
          id: 'root',
          props: {'component': 'Text', 'text': 'Hello'},
        ),
      ];
      messageProcessor.handleMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );

      final Future<GenUiUpdate> futureUpdate =
          messageProcessor.surfaceUpdates.first;
      messageProcessor.handleMessage(
        const SurfaceDeletion(surfaceId: surfaceId),
      );
      final GenUiUpdate update = await futureUpdate;

      expect(update, isA<SurfaceRemoved>());
      expect(update.surfaceId, surfaceId);
      expect(messageProcessor.surfaces.containsKey(surfaceId), isFalse);
    });

    test('surface() creates a new ValueNotifier if one does not exist', () {
      final ValueNotifier<UiDefinition?> notifier1 = messageProcessor
          .getSurfaceNotifier('s1');
      final ValueNotifier<UiDefinition?> notifier2 = messageProcessor
          .getSurfaceNotifier('s1');
      expect(notifier1, same(notifier2));
      expect(notifier1.value, isNull);
    });

    test('dispose() closes the updates stream', () async {
      var isClosed = false;
      messageProcessor.surfaceUpdates.listen(
        null,
        onDone: () {
          isClosed = true;
        },
      );

      messageProcessor.dispose();

      await Future<void>.delayed(Duration.zero);
      expect(isClosed, isTrue);
    });

    test('can handle UI event', () async {
      messageProcessor
          .dataModelForSurface('testSurface')
          .update(DataPath('/myValue'), 'testValue');
      final Future<UserUiInteractionMessage> future =
          messageProcessor.onSubmit.first;
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );
      messageProcessor.handleUiEvent(event);
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
