// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

class MockGenUiManager extends GenUiManager {
  MockGenUiManager({required super.catalog});

  final messages = <A2uiMessage>[];

  @override
  void handleMessage(A2uiMessage message) {
    messages.add(message);
  }
}

void main() {
  group('$SurfaceUpdateTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final mockManager = MockGenUiManager(
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
      );

      final tool = SurfaceUpdateTool(mockManager);

      final args = {
        surfaceIdKey: 'testSurface',
        'components': [
          {
            'id': 'rootWidget',
            'component': {
              'Text': {'text': 'Hello'},
            },
          },
        ],
      };

      await tool.invoke(args);

      expect(mockManager.messages.length, 1);
      expect(mockManager.messages[0], isA<SurfaceUpdate>());
      final surfaceUpdate = mockManager.messages[0] as SurfaceUpdate;
      expect(surfaceUpdate.surfaceId, 'testSurface');
      expect(surfaceUpdate.components.length, 1);
      expect(surfaceUpdate.components[0].id, 'rootWidget');
      expect(surfaceUpdate.components[0].componentProperties, {
        'Text': {'text': 'Hello'},
      });
    });
  });

  group('DeleteSurfaceTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final mockManager = MockGenUiManager(catalog: const Catalog([]));

      final tool = DeleteSurfaceTool(mockManager);

      final args = {surfaceIdKey: 'testSurface'};

      await tool.invoke(args);

      expect(mockManager.messages.length, 1);
      expect(mockManager.messages[0], isA<SurfaceDeletion>());
      final deleteSurface = mockManager.messages[0] as SurfaceDeletion;
      expect(deleteSurface.surfaceId, 'testSurface');
    });
  });

  group('BeginRenderingTool', () {
    test('invoke calls handleMessage with correct arguments', () async {
      final mockManager = MockGenUiManager(catalog: const Catalog([]));

      final tool = BeginRenderingTool(mockManager);

      final args = {surfaceIdKey: 'testSurface', 'root': 'rootWidget'};

      await tool.invoke(args);

      expect(mockManager.messages.length, 1);
      expect(mockManager.messages[0], isA<BeginRendering>());
      final beginRendering = mockManager.messages[0] as BeginRendering;
      expect(beginRendering.surfaceId, 'testSurface');
      expect(beginRendering.root, 'rootWidget');
    });
  });
}
