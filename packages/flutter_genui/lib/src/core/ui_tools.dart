// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';

import '../model/catalog.dart';
import '../model/tools.dart';
import '../primitives/simple_items.dart';
import 'genui_configuration.dart';

/// An [AiTool] for adding or updating a UI surface.
///
/// This tool allows the AI to create a new UI surface or update an existing
/// one with a new definition.
class AddOrUpdateSurfaceTool extends AiTool<JsonMap> {
  /// Creates an [AddOrUpdateSurfaceTool].
  AddOrUpdateSurfaceTool({
    required this.onAddOrUpdate,
    required Catalog catalog,
    required this.configuration,
  }) : super(
         name: 'addOrUpdateSurface',
         description:
             'Adds a new UI surface or updates an existing one. Use this to '
             'display new content or change what is currently visible. You are '
             'only able to use the `action` types that are available.',
         parameters: S.object(
           properties: {
             'action': S.string(
               description:
                   'The action to perform. You must choose from the available '
                   'actions. If you choose the `add` action, you must choose a '
                   'new unique surfaceId. If you choose the `update` action, '
                   'you must choose an existing surfaceId.',
               enumValues: [
                 if (configuration.actions.allowCreate) 'add',
                 if (configuration.actions.allowUpdate) 'update',
               ],
             ),
             'surfaceId': S.string(
               description:
                   'The unique identifier for the UI surface to create or '
                   'update. If you are adding a new surface this *must* be a '
                   'new, unique identified that has never been used for any '
                   'existing surfaces shown in the context.',
             ),
             'definition': S.object(
               properties: {
                 'root': S.string(
                   description:
                       'The ID of the root widget. This ID must correspond to '
                       'the ID of one of the widgets in the `widgets` list.',
                 ),
                 'widgets': S.list(
                   items: catalog.schema,
                   description: 'A list of widget definitions.',
                   minItems: 1,
                 ),
               },
               description:
                   'A schema for a simple UI tree to be rendered by '
                   'Flutter.',
               required: ['root', 'widgets'],
             ),
           },
           required: ['action', 'surfaceId', 'definition'],
         ),
       );

  /// The callback to invoke when adding or updating a surface.
  final void Function(String surfaceId, JsonMap definition) onAddOrUpdate;

  /// The configuration of the Gen UI system.
  final GenUiConfiguration configuration;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args['surfaceId'] as String;
    final definition = args['definition'] as JsonMap;
    onAddOrUpdate(surfaceId, definition);
    return {'surfaceId': surfaceId, 'status': 'SUCCESS'};
  }
}

/// An [AiTool] for deleting a UI surface.
///
/// This tool allows the AI to remove a UI surface that is no longer needed.
class DeleteSurfaceTool extends AiTool<JsonMap> {
  /// Creates a [DeleteSurfaceTool].
  DeleteSurfaceTool({required this.onDelete})
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
  final void Function(String surfaceId) onDelete;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args['surfaceId'] as String;
    onDelete(surfaceId);
    return {'status': 'ok'};
  }
}
