// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../test_infra/message_builders.dart';

void main() {
  group('$SurfaceController', () {
    late SurfaceController controller;

    setUp(() {
      controller = SurfaceController(catalogs: [BasicCatalogItems.asCatalog()]);
    });

    tearDown(() {
      controller.dispose();
    });

    test('can be initialized with multiple catalogs', () {
      final catalog1 = const Catalog([], catalogId: 'cat1');
      final catalog2 = const Catalog([], catalogId: 'cat2');
      final multiManager = SurfaceController(catalogs: [catalog1, catalog2]);
      expect(multiManager.catalogs, contains(catalog1));
      expect(multiManager.catalogs, contains(catalog2));
      expect(multiManager.catalogs.length, 2);
    });

    test('handleMessage adds a new surface and fires SurfaceAdded with '
        'definition', () async {
      const surfaceId = 's1';
      final List<JsonMap> components = [
        component(id: 'root', type: 'Text', properties: {'text': 'Hello'}),
      ];

      controller.handleMessage(
        updateComponents(surfaceId: surfaceId, components: components),
      );

      final Future<List<SurfaceUpdate>> futureUpdates = controller
          .surfaceUpdates
          .take(2)
          .toList();
      controller.handleMessage(
        createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );
      final List<SurfaceUpdate> updates = await futureUpdates;

      expect(updates[0], isA<SurfaceAdded>());
      expect(updates[0].surfaceId, surfaceId);

      final SurfaceUpdate update2 = updates[1];
      expect(update2, isA<ComponentsUpdated>());
      final SurfaceDefinition definition =
          (update2 as ComponentsUpdated).definition;

      expect(definition, isNotNull);
      expect(
        definition.components['root'],
        isNotNull,
      ); // Check if root (or any component) exists
      expect(definition.catalogId, 'test_catalog');
      expect(controller.registry.getSurface(surfaceId), isNotNull);
      expect(
        controller.registry.getSurface(surfaceId)!.catalogId,
        'test_catalog',
      );
    });

    test(
      'handleMessage updates an existing surface and fires ComponentsUpdated',
      () async {
        const surfaceId = 's1';
        final List<JsonMap> oldComponents = [
          component(id: 'root', type: 'Text', properties: {'text': 'Old'}),
        ];
        final List<JsonMap> newComponents = [
          component(id: 'root', type: 'Text', properties: {'text': 'New'}),
        ];

        final Future<void> expectation = expectLater(
          controller.surfaceUpdates,
          emitsInOrder([
            isA<SurfaceAdded>(),
            isA<ComponentsUpdated>(),
            isA<ComponentsUpdated>(),
          ]),
        );

        controller.handleMessage(
          createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
        );
        controller.handleMessage(
          updateComponents(surfaceId: surfaceId, components: oldComponents),
        );
        controller.handleMessage(
          updateComponents(surfaceId: surfaceId, components: newComponents),
        );

        await expectation;
      },
    );

    test('handleMessage removes a surface and fires SurfaceRemoved', () async {
      const surfaceId = 's1';
      final List<JsonMap> components = [
        component(id: 'root', type: 'Text', properties: {'text': 'Hello'}),
      ];
      controller.handleMessage(
        createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );
      controller.handleMessage(
        updateComponents(surfaceId: surfaceId, components: components),
      );

      final Future<SurfaceUpdate> futureUpdate =
          controller.surfaceUpdates.first;

      controller.handleMessage(deleteSurface(surfaceId: surfaceId));
      final SurfaceUpdate update = await futureUpdate;

      expect(update, isA<SurfaceRemoved>());
      expect(update.surfaceId, surfaceId);
      expect(controller.registry.hasSurface(surfaceId), isFalse);
    });

    test('surface() creates a new ValueNotifier if one does not exist', () {
      final ValueListenable<SurfaceDefinition?> notifier1 = controller.registry
          .watchDefinition('s1');
      final ValueListenable<SurfaceDefinition?> notifier2 = controller.registry
          .watchDefinition('s1');
      expect(notifier1, same(notifier2));
      expect(notifier1.value, isNull);
    });

    test('public SurfaceAdded / ComponentsUpdated constructors are '
        'definition-based', () {
      final def = SurfaceDefinition(surfaceId: 's1');
      final added = SurfaceAdded('s1', def);
      expect(added.surfaceId, 's1');
      expect(added.definition, same(def));
      expect(added.surface, isNull);

      final updated = ComponentsUpdated('s1', def);
      expect(updated.surfaceId, 's1');
      expect(updated.definition, same(def));
      expect(updated.surface, isNull);
    });

    test(
      'registry watchSurface/getSurface expose SurfaceDefinition snapshots',
      () {
        const surfaceId = 's1';
        final ValueListenable<SurfaceDefinition?> notifier = controller.registry
            .watchSurface(surfaceId);
        expect(notifier.value, isNull);
        expect(controller.registry.getSurface(surfaceId), isNull);

        controller.handleMessage(
          createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
        );

        final SurfaceDefinition? def = controller.registry.getSurface(
          surfaceId,
        );
        expect(def, isNotNull);
        expect(def!.catalogId, 'test_catalog');
        expect(notifier.value, same(def));
      },
    );

    test('store exposes the live surface data model facade', () {
      const surfaceId = 's1';
      controller.handleMessage(
        createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );
      controller.handleMessage(
        updateDataModel(
          surfaceId: surfaceId,
          path: DataPath.root,
          value: {'name': 'Alice'},
        ),
      );

      final DataModel model = controller.store.getDataModel(surfaceId);
      expect(model.getValue<String>(DataPath('/name')), 'Alice');
      expect(controller.store.dataModels[surfaceId], same(model));

      controller.handleMessage(
        updateDataModel(
          surfaceId: surfaceId,
          path: DataPath('/name'),
          value: 'Bob',
        ),
      );
      expect(model.getValue<String>(DataPath('/name')), 'Bob');
    });

    test('contextFor(surfaceId).dataModel returns a writable model '
        'before createSurface', () {
      const surfaceId = 'pre_create';
      final DataModel model = controller.contextFor(surfaceId).dataModel;
      expect(() => model.update(DataPath('/foo'), 'bar'), returnsNormally);
      expect(model.getValue<String>(DataPath('/foo')), 'bar');
    });

    test('pre-create data written via contextFor is migrated into the live '
        'surface model when createSurface arrives', () async {
      const surfaceId = 'migrate_me';
      controller
          .contextFor(surfaceId)
          .dataModel
          .update(DataPath('/name'), 'Alice');

      controller.handleMessage(
        createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );

      // Post-create, contextFor.dataModel routes through the live core
      // surface model, so reading back here proves the migration landed.
      final DataModel model = controller.contextFor(surfaceId).dataModel;
      expect(model.getValue<String>(DataPath('/name')), 'Alice');
    });

    test('pre-create root-null write is preserved across createSurface', () {
      const surfaceId = 'null_root';
      controller.contextFor(surfaceId).dataModel.update(DataPath.root, null);

      controller.handleMessage(
        createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );

      final DataModel model = controller.contextFor(surfaceId).dataModel;
      expect(model.getValue<Object?>(DataPath.root), isNull);
    });

    test('dispose() closes the updates stream', () async {
      var isClosed = false;
      controller.surfaceUpdates.listen(
        null,
        onDone: () {
          isClosed = true;
        },
      );

      controller.dispose();

      await Future<void>.delayed(Duration.zero);
      expect(isClosed, isTrue);
    });

    test('can handle UI event', () async {
      final Future<ChatMessage> future = controller.onSubmit.first;
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );
      controller.handleUiEvent(event);
      final ChatMessage message = await future;
      expect(message, isA<ChatMessage>());
      expect(message.role, ChatMessageRole.user);
      expect(message.parts.uiInteractionParts, hasLength(1));

      final String expectedJson = jsonEncode({
        'version': 'v0.9',
        'action': {
          'surfaceId': 'testSurface',
          'name': 'testAction',
          'sourceComponentId': 'testWidget',
          'timestamp': now.toIso8601String(),
          'context': {'key': 'value'},
        },
      });
      final UiInteractionPart part = message.parts.uiInteractionParts.first;
      // Depending on implementation, part.interaction might be the string or
      // data map. UiInteractionPart.create took jsonEncode string.
      // UiInteractionPart.interaction is String.
      expect(part.interaction, expectedJson);
    });

    test('handleUiEvent ignores non-action UiEvents', () async {
      var submitted = false;
      final StreamSubscription<ChatMessage> sub = controller.onSubmit.listen(
        (_) => submitted = true,
      );
      final event = UiEvent.fromMap({
        'widgetId': 'testWidget',
        'eventType': 'onChanged',
        'value': 'hello',
        'timestamp': DateTime.now().toIso8601String(),
      });
      controller.handleUiEvent(event);
      await Future<void>.delayed(Duration.zero);
      expect(submitted, isFalse);
      await sub.cancel();
    });

    test(
      'handleMessage reports validation error with correct structure',
      () async {
        // Trigger validation error by using an empty surface ID.
        final Future<ChatMessage> messageFuture = controller.onSubmit.first;
        controller.handleMessage(
          createSurface(surfaceId: '', catalogId: 'test_catalog'),
        );

        final ChatMessage message = await messageFuture;
        expect(message.role, ChatMessageRole.user);
        final UiInteractionPart part = message.parts.uiInteractionParts.first;
        final errorJson = jsonDecode(part.interaction) as Map<String, dynamic>;

        expect(errorJson['version'], 'v0.9');
        final Object? errorObj = errorJson['error'];
        expect(errorObj, isA<Map<String, dynamic>>());
        final errorMap = errorObj! as Map<String, dynamic>;
        expect(errorMap['code'], 'VALIDATION_FAILED');
        expect(errorMap['surfaceId'], '');
        expect(errorMap['path'], 'surfaceId');
      },
    );

    test('rejects empty surfaceId on non-create messages', () async {
      final Future<ChatMessage> messageFuture = controller.onSubmit.first;
      controller.handleMessage(updateDataModel(surfaceId: '', value: 1));

      final ChatMessage message = await messageFuture;
      final UiInteractionPart part = message.parts.uiInteractionParts.first;
      final errorJson = jsonDecode(part.interaction) as Map<String, dynamic>;
      final errorMap = errorJson['error']! as Map<String, dynamic>;
      expect(errorMap['code'], 'VALIDATION_FAILED');
      expect(errorMap['surfaceId'], '');
      expect(errorMap['path'], 'surfaceId');
    });

    test(
      'duplicate createSurface for an active surface reports an error',
      () async {
        controller.handleMessage(
          createSurface(surfaceId: 's1', catalogId: 'test_catalog'),
        );
        final Future<ChatMessage> messageFuture = controller.onSubmit.first;
        controller.handleMessage(
          createSurface(surfaceId: 's1', catalogId: 'test_catalog'),
        );

        final ChatMessage message = await messageFuture;
        final UiInteractionPart part = message.parts.uiInteractionParts.first;
        final errorJson = jsonDecode(part.interaction) as Map<String, dynamic>;
        final errorMap = errorJson['error']! as Map<String, dynamic>;
        expect(errorMap['surfaceId'], 's1');
      },
    );

    test('drops pending updates after timeout', () async {
      // Create controller with short timeout
      final shortTimeoutController = SurfaceController(
        catalogs: [BasicCatalogItems.asCatalog()],
        pendingUpdateTimeout: const Duration(milliseconds: 100),
      );
      addTearDown(shortTimeoutController.dispose);

      const surfaceId = 'timedOutSurface';
      final List<JsonMap> components = [
        component(
          id: 'root',
          type: 'Text',
          properties: {'text': 'Should not be seen'},
        ),
      ];

      // 1. Send update for non-existent surface (buffered)
      shortTimeoutController.handleMessage(
        updateComponents(surfaceId: surfaceId, components: components),
      );

      // 2. Wait for timeout
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // 3. Create surface (but first setup listener)
      final Future<List<SurfaceUpdate>> updatesFuture = shortTimeoutController
          .surfaceUpdates
          .take(1)
          .toList();
      shortTimeoutController.handleMessage(
        createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
      );

      // 4. Verify surface created but NO update applied
      // If update was applied, we'd see [SurfaceAdded, ComponentsUpdated]
      // If dropped, we only see [SurfaceAdded] (and potentially components from
      // CreateSurface if any, but default is empty)
      final List<SurfaceUpdate> updates = await updatesFuture;
      expect(updates.length, 1);
      expect(updates[0], isA<SurfaceAdded>());

      // Allow a small delay to ensure no other events come through
      // Testing emptiness of a stream is tricky, checking registry state is
      // better.
      await Future<void>.delayed(Duration.zero);

      final SurfaceDefinition? surface = shortTimeoutController.registry
          .watchDefinition(surfaceId)
          .value;
      expect(surface, isNotNull);
      // Updates NOT applied, so components should be empty (or default)
      expect(surface!.components, isEmpty);
    });

    test(
      'handleMessage reports schema validation error for invalid component',
      () async {
        final catalog = Catalog([
          CatalogItem(
            name: 'StrictWidget',
            dataSchema: Schema.object(
              properties: {
                'component': Schema.string(enumValues: ['StrictWidget']),
                'requiredProp': Schema.string(),
              },
              required: ['component', 'requiredProp'],
            ),
            widgetBuilder: _dummyBuilder,
          ),
        ], catalogId: 'strict_catalog');
        final strictController = SurfaceController(catalogs: [catalog]);
        addTearDown(strictController.dispose);

        const surfaceId = 'strictSurface';
        strictController.handleMessage(
          createSurface(surfaceId: surfaceId, catalogId: 'strict_catalog'),
        );

        final Future<ChatMessage> future = strictController.onSubmit.first;

        // Send invalid component (missing requiredProp)
        strictController.handleMessage(
          updateComponents(
            surfaceId: surfaceId,
            components: [
              component(id: 'bad', type: 'StrictWidget', properties: {}),
            ],
          ),
        );

        final ChatMessage message = await future;
        final UiInteractionPart part = message.parts.uiInteractionParts.first;
        final errorJson = jsonDecode(part.interaction) as Map<String, dynamic>;

        final errorObj = errorJson['error'] as Map<String, dynamic>;
        expect(errorObj['code'], 'VALIDATION_FAILED');
        expect(errorObj['message'], contains('Missing required property'));
      },
    );
  });
}

Widget _dummyBuilder(CatalogItemContext context) => const SizedBox();
