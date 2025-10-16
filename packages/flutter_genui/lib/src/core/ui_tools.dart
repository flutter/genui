// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/tools.dart';
import '../primitives/simple_items.dart';
import 'genui_configuration.dart';

/// An [AiTool] for adding or updating a UI surface.
///
/// This tool allows the AI to create a new UI surface or update an existing
/// one with a new definition.
class SurfaceUpdateTool extends AiTool<JsonMap> {
  /// Creates an [SurfaceUpdateTool].
  SurfaceUpdateTool({
    required this.handleMessage,
    required Catalog catalog,
    required this.configuration,
  }) : super(
         name: 'surfaceUpdate',
         description: 'Updates a surface with a new set of components.',
         parameters: S.object(
           properties: {
             'surfaceId': S.string(
               description:
                   'The unique identifier for the UI surface to create or '
                   'update. If you are adding a new surface this *must* be a '
                   'new, unique identified that has never been used for any '
                   'existing surfaces shown.',
             ),
             'components': S.list(
               description: 'A list of component definitions.',
               minItems: 1,
               items: S.object(
                 description:
                     'Represents a *single* component in a UI widget tree. '
                     'This component could be one of many supported types.',
                 properties: {
                   'id': S.string(),
                   'component': S.object(
                     description:
                         '''A wrapper object that MUST contain exactly one key, which is the name of the component type (e.g., 'Heading'). The value is an object containing the properties for that specific component.''',
                     properties: {
                       for (var entry
                           in ((catalog.definition as ObjectSchema)
                                       .properties!['components']!
                                   as ObjectSchema)
                               .properties!
                               .entries)
                         entry.key: entry.value,
                     },
                   ),
                 },
                 required: ['id', 'component'],
               ),
             ),
           },
           required: ['surfaceId', 'components'],
         ),
       );

  /// The callback to invoke when adding or updating a surface.
  final void Function(A2uiMessage message) handleMessage;

  /// The configuration of the Gen UI system.
  final GenUiConfiguration configuration;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args['surfaceId'] as String;
    final components = (args['components'] as List).map((e) {
      final component = e as JsonMap;
      return Component(
        id: component['id'] as String,
        componentProperties: component['component'] as JsonMap,
      );
    }).toList();
    handleMessage(SurfaceUpdate(surfaceId: surfaceId, components: components));
    return {'surfaceId': surfaceId, 'status': 'SUCCESS'};
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
            'surfaceId': S.string(
              description:
                  'The unique identifier for the UI surface to remove.',
            ),
          },
          required: ['surfaceId'],
        ),
      );

  /// The callback to invoke when deleting a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args['surfaceId'] as String;
    handleMessage(SurfaceDeletion(surfaceId: surfaceId));
    return {'status': 'ok'};
  }
}

/// An [AiTool] for signaling the client to begin rendering.
///
/// This tool allows the AI to specify the root component of a UI surface.
class BeginRenderingTool extends AiTool<JsonMap> {
  /// Creates a [BeginRenderingTool].
  BeginRenderingTool({required this.handleMessage})
    : super(
        name: 'beginRendering',
        description:
            'Signals the client to begin rendering a surface with a '
            'root component.',
        parameters: S.object(
          properties: {
            'surfaceId': S.string(
              description:
                  'The unique identifier for the UI surface to render.',
            ),
            'root': S.string(
              description:
                  'The ID of the root widget. This ID must correspond to '
                  'the ID of one of the widgets in the `components` list.',
            ),
          },
          required: ['surfaceId', 'root'],
        ),
      );

  /// The callback to invoke when signaling to begin rendering.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args['surfaceId'] as String;
    final root = args['root'] as String;
    handleMessage(BeginRendering(surfaceId: surfaceId, root: root));
    return {'status': 'ok'};
  }
}
