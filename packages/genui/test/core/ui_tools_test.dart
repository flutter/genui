// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/core/ui_tools.dart';
import 'package:genui/src/model/a2ui_message.dart';
import 'package:genui/src/model/catalog.dart';
import 'package:genui/src/model/catalog_item.dart';
import 'package:genui/src/model/tools.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  group('$SurfaceUpdateTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final messages = <A2uiMessage>[];

      void fakeHandleMessage(A2uiMessage message) {
        messages.add(message);
      }

      final tool = SurfaceUpdateTool(
        handleMessage: fakeHandleMessage,
        catalog: Catalog([
          CatalogItem(
            name: 'Text',
            widgetBuilder: (_) {
              return const Text('');
            },
            dataSchema: Schema.object(properties: {}),
          ),
        ], catalogId: 'test_catalog'),
      );

      final Map<String, Object> args = {
        surfaceIdKey: 'testSurface',
        'components': [
          {
            'id': 'rootWidget',
            'props': {
              'Text': {'text': 'Hello'},
            },
          },
        ],
      };

      await tool.invoke(args);

      expect(messages.length, 1);
      expect(messages[0], isA<SurfaceUpdate>());
      final surfaceUpdate = messages[0] as SurfaceUpdate;
      expect(surfaceUpdate.surfaceId, 'testSurface');
      expect(surfaceUpdate.components.length, 1);
      expect(surfaceUpdate.components[0].id, 'rootWidget');
      expect(surfaceUpdate.components[0].props, {
        'Text': {'text': 'Hello'},
      });
    });
  });

  group('DeleteSurfaceTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final messages = <A2uiMessage>[];

      void fakeHandleMessage(A2uiMessage message) {
        messages.add(message);
      }

      final tool = DeleteSurfaceTool(handleMessage: fakeHandleMessage);

      final Map<String, String> args = {surfaceIdKey: 'testSurface'};

      await tool.invoke(args);

      expect(messages.length, 1);
      expect(messages[0], isA<SurfaceDeletion>());
      final deleteSurface = messages[0] as SurfaceDeletion;
      expect(deleteSurface.surfaceId, 'testSurface');
    });
  });

  group('CreateSurfaceTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final messages = <A2uiMessage>[];

      void fakeHandleMessage(A2uiMessage message) {
        messages.add(message);
      }

      final tool = CreateSurfaceTool(handleMessage: fakeHandleMessage);

      final Map<String, Object> args = {surfaceIdKey: 'testSurface'};

      await tool.invoke(args);

      expect(messages.length, 1);
      expect(messages[0], isA<CreateSurface>());
      final createSurface = messages[0] as CreateSurface;
      expect(createSurface.surfaceId, 'testSurface');
    });
  });
}
