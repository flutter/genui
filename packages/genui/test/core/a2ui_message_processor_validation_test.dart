// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../test_infra/message_builders.dart';

void main() {
  group('SurfaceController Validation', () {
    test('CreateSurface fails validation with empty surfaceId', () async {
      final controller = SurfaceController(catalogs: []);

      // Expect an error message on the submit stream
      final Future<void> future = expectLater(
        controller.onSubmit,
        emits(
          predicate((ChatMessage message) {
            final UiInteractionPart part =
                message.parts.uiInteractionParts.first;
            final json = jsonDecode(part.interaction) as Map<String, dynamic>;
            final error = json['error'] as Map<String, dynamic>;
            return error['code'] == 'VALIDATION_FAILED' &&
                error['path'] == 'surfaceId';
          }),
        ),
      );

      controller.handleMessage(
        createSurface(surfaceId: '', catalogId: 'default'),
      );

      await future;
    });

    test(
      'CreateSurface fails schema validation for invalid component',
      () async {
        final controller = SurfaceController(
          catalogs: [BasicCatalogItems.asCatalog()],
        );

        final Future<void> future = expectLater(
          controller.onSubmit,
          emits(
            predicate((ChatMessage message) {
              final UiInteractionPart part =
                  message.parts.uiInteractionParts.first;
              final json = jsonDecode(part.interaction) as Map<String, dynamic>;
              final error = json['error'] as Map<String, dynamic>;
              return error['code'] == 'VALIDATION_FAILED' &&
                  error['path'] == '/components/badText';
            }),
          ),
        );

        controller.handleMessage(
          createSurface(surfaceId: 'surf1', catalogId: basicCatalogId),
        );

        controller.handleMessage(
          updateComponents(
            surfaceId: 'surf1',
            components: [
              component(
                id: 'badText',
                type: 'Text',
                properties: {},
              ), // Missing 'text' property
            ],
          ),
        );

        await future;
      },
    );

    test(
      'UpdateDataModel write failure reports its surfaceId and path',
      () async {
        final controller = SurfaceController(
          catalogs: [BasicCatalogItems.asCatalog()],
        );

        final Future<void> future = expectLater(
          controller.onSubmit,
          emits(
            predicate((ChatMessage message) {
              final UiInteractionPart part =
                  message.parts.uiInteractionParts.first;
              final json = jsonDecode(part.interaction) as Map<String, Object?>;
              final error = json['error'] as Map<String, Object?>;
              return error['code'] == 'VALIDATION_FAILED' &&
                  error['surfaceId'] == 'surf1' &&
                  error['path'] == '/scalar/child/leaf';
            }),
          ),
        );

        controller.handleMessage(
          createSurface(surfaceId: 'surf1', catalogId: basicCatalogId),
        );
        // The core data model rejects writing through a primitive intermediate;
        // the controller surfaces it with the offending surfaceId and path.
        controller.handleMessage(
          updateDataModel(
            surfaceId: 'surf1',
            path: DataPath('/scalar'),
            value: 5,
          ),
        );
        controller.handleMessage(
          updateDataModel(
            surfaceId: 'surf1',
            path: DataPath('/scalar/child/leaf'),
            value: 'x',
          ),
        );

        await future;
      },
    );

    test(
      'validates components against an inline catalog (catalogId == null)',
      () async {
        // An inline catalog (no explicit id) is registered under a synthesized
        // id; the controller must resolve a surface back to it, or validation
        // is silently skipped.
        final inlineCatalog = Catalog(BasicCatalogItems.asCatalog().items);
        final controller = SurfaceController(catalogs: [inlineCatalog]);

        final Future<void> future = expectLater(
          controller.onSubmit,
          emits(
            predicate((ChatMessage message) {
              final UiInteractionPart part =
                  message.parts.uiInteractionParts.first;
              final json = jsonDecode(part.interaction) as Map<String, Object?>;
              final error = json['error'] as Map<String, Object?>;
              return error['code'] == 'VALIDATION_FAILED' &&
                  error['path'] == '/components/badText';
            }),
          ),
        );

        controller.handleMessage(
          createSurface(
            surfaceId: 'surf1',
            catalogId: inlineCatalog.effectiveCatalogId,
          ),
        );
        controller.handleMessage(
          updateComponents(
            surfaceId: 'surf1',
            components: [
              component(id: 'badText', type: 'Text', properties: {}),
            ],
          ),
        );

        await future;
      },
    );

    group('reports a path for every rejected message', () {
      late SurfaceController controller;
      late List<Map<String, Object?>> errors;

      setUp(() {
        controller = SurfaceController(
          catalogs: [BasicCatalogItems.asCatalog()],
        );
        errors = [];
        controller.onSubmit.listen((ChatMessage message) {
          final UiInteractionPart part = message.parts.uiInteractionParts.first;
          final json = jsonDecode(part.interaction) as Map<String, Object?>;
          errors.add(json['error']! as Map<String, Object?>);
        });
        controller.handleMessage(
          createSurface(surfaceId: 'surf1', catalogId: basicCatalogId),
        );
      });

      tearDown(() => controller.dispose());

      Future<Map<String, Object?>> onlyError() async {
        await Future<void>.delayed(Duration.zero);
        expect(errors, hasLength(1));
        expect(errors.single['code'], 'VALIDATION_FAILED');
        return errors.single;
      }

      test('duplicate component ids', () async {
        controller.handleMessage(
          updateComponents(
            surfaceId: 'surf1',
            components: [
              component(id: 'dup', type: 'Text', properties: {'text': 'a'}),
              component(id: 'dup', type: 'Text', properties: {'text': 'b'}),
            ],
          ),
        );

        expect((await onlyError())['path'], '/components/dup');
      });

      test('a component that references itself', () async {
        controller.handleMessage(
          updateComponents(
            surfaceId: 'surf1',
            components: [
              component(
                id: 'loop',
                type: 'Card',
                properties: {'child': 'loop'},
              ),
            ],
          ),
        );

        expect((await onlyError())['path'], '/components/loop');
      });

      test('a binding with invalid path syntax', () async {
        controller.handleMessage(
          updateComponents(
            surfaceId: 'surf1',
            components: [
              component(
                id: 'root',
                type: 'Text',
                properties: {
                  'text': {'path': '/a~2b'},
                },
              ),
            ],
          ),
        );

        expect((await onlyError())['path'], '/components');
      });

      test(
        'leaves the surface unchanged when one component is invalid',
        () async {
          controller.handleMessage(
            updateComponents(
              surfaceId: 'surf1',
              components: [
                component(
                  id: 'root',
                  type: 'Text',
                  properties: {'text': 'old'},
                ),
              ],
            ),
          );
          await Future<void>.delayed(Duration.zero);

          controller.handleMessage(
            updateComponents(
              surfaceId: 'surf1',
              components: [
                component(
                  id: 'root',
                  type: 'Text',
                  properties: {'text': 'new'},
                ),
                component(id: 'bad', type: 'Text', properties: {}),
              ],
            ),
          );

          expect((await onlyError())['path'], '/components/bad');
          final Map<String, Component> components = controller.registry
              .getSurface('surf1')!
              .components;
          expect(components.keys, ['root']);
          expect(components['root']!.properties['text'], 'old');
        },
      );

      test('a data model value with invalid path syntax', () async {
        controller.handleMessage(
          updateDataModel(
            surfaceId: 'surf1',
            value: {
              'file': {'path': '~/photos'},
            },
          ),
        );

        expect((await onlyError())['path'], '/value');
      });
    });
  });

  test('applies an update that omits the component type', () async {
    final controller = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    addTearDown(controller.dispose);
    controller.handleMessage(
      createSurface(surfaceId: 'surf1', catalogId: basicCatalogId),
    );
    controller.handleMessage(
      updateComponents(
        surfaceId: 'surf1',
        components: [
          component(id: 'root', type: 'Text', properties: {'text': 'old'}),
        ],
      ),
    );

    controller.handleMessage(
      updateComponents(
        surfaceId: 'surf1',
        components: [
          {'id': 'root', 'text': 'new'},
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final Component root = controller.registry
        .getSurface('surf1')!
        .components['root']!;
    expect(root.type, 'Text');
    expect(root.properties['text'], 'new');
  });
}
