// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../model/a2ui_message.dart';
import '../model/a2ui_schemas.dart';
import '../model/catalog.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/simple_items.dart';

/// An [AiTool] for adding or updating a UI surface.
///
/// This tool allows the AI to create a new UI surface or update an existing
/// one with a new definition.
class SurfaceUpdateTool extends AiTool<JsonMap> {
  /// Creates an [SurfaceUpdateTool].
  SurfaceUpdateTool({required this.handleMessage, required Catalog catalog})
    : super(
        name: 'surfaceUpdate',
        description: 'Updates a surface with a new set of components.',
        parameters: A2uiSchemas.surfaceUpdateSchema(catalog),
      );

  /// The callback to invoke when adding or updating a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final List<Component> components = (args['components'] as List).map((e) {
      final component = e as JsonMap;
      return Component(
        id: component['id'] as String,
        componentProperties: component['component'] as JsonMap,
        weight: (component['weight'] as num?)?.toInt(),
      );
    }).toList();
    handleMessage(SurfaceUpdate(surfaceId: surfaceId, components: components));
    return {
      surfaceIdKey: surfaceId,
      'status': 'UI Surface $surfaceId updated.',
    };
  }
}

/// An [AiTool] for deleting a UI surface.
///
/// This tool allows the AI to remove a UI surface that is no longer needed.
class DeleteSurfaceTool extends AiTool<JsonMap> {
  /// Creates a [DeleteSurfaceTool].
  DeleteSurfaceTool({required this.handleMessage})
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

  /// The callback to invoke when deleting a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    handleMessage(SurfaceDeletion(surfaceId: surfaceId));
    return {'status': 'Surface $surfaceId deleted.'};
  }
}

/// An [AiTool] for signaling the client to begin rendering.
///
/// This tool allows the AI to specify the root component of a UI surface.
class BeginRenderingTool extends AiTool<JsonMap> {
  /// Creates a [BeginRenderingTool].
  BeginRenderingTool({required this.handleMessage, this.catalogId})
    : super(
        name: 'beginRendering',
        description:
            'Signals the client to begin rendering a surface with a '
            'root component.',
        parameters: A2uiSchemas.beginRenderingSchemaNoCatalogId(),
      );

  /// The callback to invoke when signaling to begin rendering.
  final void Function(A2uiMessage message) handleMessage;

  /// The ID of the catalog to use for rendering this surface.
  final String? catalogId;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final root = args['root'] as String;
    handleMessage(
      BeginRendering(surfaceId: surfaceId, root: root, catalogId: catalogId),
    );
    return {
      'status': 'Surface $surfaceId rendered and waiting for user input.',
    };
  }
}
