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
        // Put a primitive at /scalar, then write through it. The core data
        // model rejects traversing a primitive, and the controller surfaces
        // the failure with the offending surfaceId and path.
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
  });
}
