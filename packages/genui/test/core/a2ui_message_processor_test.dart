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
          type: 'Text',
          properties: {'text': 'Hello'},
        ),
      ];

      messageProcessor.handleMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );

      final Future<List<GenUiUpdate>> futureUpdates = messageProcessor
          .surfaceUpdates
          .take(2)
          .toList();
      messageProcessor.handleMessage(
        const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );
      final List<GenUiUpdate> updates = await futureUpdates;

      expect(updates[0], isA<SurfaceAdded>());
      expect(updates[0].surfaceId, surfaceId);

      final GenUiUpdate update2 = updates[1];
      expect(update2, isA<ComponentsUpdated>());
      final UiDefinition definition = (update2 as ComponentsUpdated).definition;

      expect(definition, isNotNull);
      expect(
        definition.components['root'],
        isNotNull,
      ); // Check if root (or any component) exists
      expect(definition.catalogId, 'test_catalog');
      expect(messageProcessor.surfaces[surfaceId]!.value, isNotNull);
      expect(
        messageProcessor.surfaces[surfaceId]!.value!.catalogId,
        'test_catalog',
      );
    });

    test(
      'handleMessage updates an existing surface and fires ComponentsUpdated',
      () async {
        const surfaceId = 's1';
        final oldComponents = [
          const Component(
            id: 'root',
            type: 'Text',
            properties: {'text': 'Old'},
          ),
        ];
        final newComponents = [
          const Component(
            id: 'root',
            type: 'Text',
            properties: {'text': 'New'},
          ),
        ];

        final Future<void> expectation = expectLater(
          messageProcessor.surfaceUpdates,
          emitsInOrder([
            isA<SurfaceAdded>(),
            isA<ComponentsUpdated>(),
            isA<ComponentsUpdated>(),
          ]),
        );

        messageProcessor.handleMessage(
          const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
        );
        messageProcessor.handleMessage(
          UpdateComponents(surfaceId: surfaceId, components: oldComponents),
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
          type: 'Text',
          properties: {'text': 'Hello'},
        ),
      ];
      messageProcessor.handleMessage(
        const CreateSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );
      messageProcessor.handleMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );

      final Future<GenUiUpdate> futureUpdate =
          messageProcessor.surfaceUpdates.first;

      messageProcessor.handleMessage(const DeleteSurface(surfaceId: surfaceId));
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
      final Future<ChatMessage> future = messageProcessor.onSubmit.first;
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );
      messageProcessor.handleUiEvent(event);
      final ChatMessage message = await future;
      expect(message, isA<ChatMessage>());
      expect(message.role, ChatMessageRole.user);
      expect(message.parts.uiInteractionParts, hasLength(1));

      final String expectedJson = jsonEncode({
        'action': {
          'surfaceId': 'testSurface',
          'name': 'testAction',
          'sourceComponentId': 'testWidget',
          'timestamp': now.toIso8601String(),
          'isAction': true,
          'context': {'key': 'value'},
        },
      });
      final UiInteractionPart part = message.parts.uiInteractionParts.first;
      // Depending on implementation, part.interaction might be the string or
      // data map. UiInteractionPart.create took jsonEncode string.
      // UiInteractionPart.interaction is String.
      expect(part.interaction, expectedJson);
    });
  });
}
