// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../model/a2ui_message.dart';
import '../model/a2ui_schemas.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/simple_items.dart';
import 'genui_manager.dart';

/// A collection of tools for interacting with the GenUI system.
class GenUiTools {
  /// Returns a list of all the tools available for interacting with the GenUI
  /// system.
  static List<AiTool> allTools(GenUiManager genUiManager) {
    return [
      SurfaceUpdateTool(genUiManager),
      BeginRenderingTool(genUiManager),
      DeleteSurfaceTool(genUiManager),
      // Add DataModelUpdate tool here once
      //https://github.com/flutter/genui/pull/423 is fixed
    ];
  }
}

/// An [AiTool] for updating the data model.
class DataModelUpdateTool extends AiTool<JsonMap> {
  /// Creates a [DataModelUpdateTool].
  DataModelUpdateTool(this.genUiManager)
    : super(
        name: 'dataModelUpdate',
        description: 'Updates the data model of a surface.',
        parameters: A2uiSchemas.dataModelUpdateSchema(),
      );

  /// The [GenUiManager] to use for updating the UI.
  final GenUiManager genUiManager;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final path = args['path'] as String?;
    final contents = args['contents'] as JsonMap;
    genUiManager.handleMessage(
      DataModelUpdate(surfaceId: surfaceId, path: path, contents: contents),
    );
    return {'status': 'ok'};
  }
}

/// An [AiTool] for adding or updating a UI surface.
///
/// This tool allows the AI to create a new UI surface or update an existing
/// one with a new definition.
class SurfaceUpdateTool extends AiTool<JsonMap> {
  /// Creates an [SurfaceUpdateTool].
  SurfaceUpdateTool(this.genUiManager)
    : super(
        name: 'surfaceUpdate',
        description: 'Updates a surface with a new set of components.',
        parameters: A2uiSchemas.surfaceUpdateSchema(genUiManager.catalog),
      );

  /// The [GenUiManager] to use for updating the UI.
  final GenUiManager genUiManager;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final components = (args['components'] as List).map((e) {
      final component = e as JsonMap;
      return Component(
        id: component['id'] as String,
        componentProperties: component['component'] as JsonMap,
      );
    }).toList();
    genUiManager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    return {surfaceIdKey: surfaceId, 'status': 'SUCCESS'};
  }
}

/// An [AiTool] for deleting a UI surface.
///
/// This tool allows the AI to remove a UI surface that is no longer needed.
class DeleteSurfaceTool extends AiTool<JsonMap> {
  /// Creates a [DeleteSurfaceTool].
  DeleteSurfaceTool(this.genUiManager)
    : super(
        name: 'deleteSurface',
        description: 'Removes a UI surface that is no longer needed.',
        parameters: S.object(
          properties: {
            surfaceIdKey: S.string(
              description:
                  'The unique identifier for the UI surface to remove.',
            ),
          },
          required: [surfaceIdKey],
        ),
      );

  /// The [GenUiManager] to use for updating the UI.
  final GenUiManager genUiManager;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    genUiManager.handleMessage(SurfaceDeletion(surfaceId: surfaceId));
    return {'status': 'ok'};
  }
}

/// An [AiTool] for signaling the client to begin rendering.
///
/// This tool allows the AI to specify the root component of a UI surface.
class BeginRenderingTool extends AiTool<JsonMap> {
  /// Creates a [BeginRenderingTool].
  BeginRenderingTool(this.genUiManager)
    : super(
        name: 'beginRendering',
        description:
            'Signals the client to begin rendering a surface with a '
            'root component.',
        parameters: S.object(
          properties: {
            surfaceIdKey: S.string(
              description:
                  'The unique identifier for the UI surface to render.',
            ),
            'root': S.string(
              description:
                  'The ID of the root widget. This ID must correspond to '
                  'the ID of one of the widgets in the `components` list.',
            ),
          },
          required: [surfaceIdKey, 'root'],
        ),
      );

  /// The [GenUiManager] to use for updating the UI.
  final GenUiManager genUiManager;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final root = args['root'] as String;
    genUiManager.handleMessage(
      BeginRendering(surfaceId: surfaceId, root: root),
    );
    return {'status': 'ok'};
  }
}
