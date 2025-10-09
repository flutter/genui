// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/core/genui_configuration.dart';
import 'package:flutter_genui/src/core/ui_tools.dart';
import 'package:flutter_genui/src/model/a2ui_message.dart';
import 'package:flutter_genui/src/model/catalog.dart';
import 'package:flutter_genui/src/model/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  group('AddOrUpdateSurfaceTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final messages = <A2uiMessage>[];

      void fakeHandleMessage(A2uiMessage message) {
        messages.add(message);
      }

      final tool = AddOrUpdateSurfaceTool(
        handleMessage: fakeHandleMessage,
        catalog: Catalog([
          CatalogItem(
            name: 'Text',
            widgetBuilder:
                ({
                  required data,
                  required id,
                  required buildChild,
                  required dispatchEvent,
                  required context,
                  required dataContext,
                }) {
                  return const Text('');
                },
            dataSchema: Schema.object(properties: {}),
          ),
        ]),
        configuration: const GenUiConfiguration(),
      );

      final args = {
        'surfaceId': 'testSurface',
        'definition': {
          'root': 'rootWidget',
          'widgets': [
            {
              'id': 'rootWidget',
              'widget': {
                'Text': {'text': 'Hello'},
              },
            },
          ],
        },
      };

      await tool.invoke(args);

      expect(messages.length, 2);
      expect(messages[0], isA<SurfaceUpdate>());
      final surfaceUpdate = messages[0] as SurfaceUpdate;
      expect(surfaceUpdate.surfaceId, 'testSurface');
      expect(surfaceUpdate.components.length, 1);
      expect(surfaceUpdate.components[0].id, 'rootWidget');
      expect(surfaceUpdate.components[0].componentProperties, {
        'Text': {'text': 'Hello'},
      });
      expect(messages[1], isA<BeginRendering>());
      final beginRendering = messages[1] as BeginRendering;
      expect(beginRendering.surfaceId, 'testSurface');
      expect(beginRendering.root, 'rootWidget');
    });
  });

  group('DeleteSurfaceTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final messages = <A2uiMessage>[];

      void fakeHandleMessage(A2uiMessage message) {
        messages.add(message);
      }

      final tool = DeleteSurfaceTool(handleMessage: fakeHandleMessage);

      final args = {'surfaceId': 'testSurface'};

      await tool.invoke(args);

      expect(messages.length, 1);
      expect(messages[0], isA<SurfaceDeletion>());
      final surfaceDeletion = messages[0] as SurfaceDeletion;
      expect(surfaceDeletion.surfaceId, 'testSurface');
    });
  });
}
