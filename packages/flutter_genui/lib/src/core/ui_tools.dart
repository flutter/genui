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
class AddOrUpdateSurfaceTool extends AiTool<JsonMap> {
  /// Creates an [AddOrUpdateSurfaceTool].
  AddOrUpdateSurfaceTool({
    required this.handleMessage,
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
                   description: 'A list of widget definitions.',
                   minItems: 1,
                   items: S.object(
                     description:
                         'Represents a *single* widget in a UI widget tree. '
                         'This widget could be one of many supported types.',
                     properties: {
                       'id': S.string(),
                       'widget': Schema.combined(
                         description:
                             'A wrapper object for a single widget '
                             'definition. It MUST contain exactly one key, '
                             'where the key is the name of a widget type '
                             '(e.g., "Column", "Text", "ElevatedButton") from '
                             'the list of allowed properties. The value is an '
                             'object containing the definition of that widget '
                             'using its properties. For example: '
                             '`{"TypeOfWidget": {"widget_property": "Value of '
                             'property"}}`',
                         anyOf: [
                           for (var entry
                               in ((catalog.definition as ObjectSchema)
                                           .properties!['components']!
                                       as ObjectSchema)
                                   .properties!
                                   .entries)
                             Schema.object(
                               properties: {entry.key: entry.value},
                               required: [entry.key],
                             ),
                         ],
                       ),
                     },
                     required: ['id', 'widget'],
                   ),
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
  final void Function(A2uiMessage message) handleMessage;

  /// The configuration of the Gen UI system.
  final GenUiConfiguration configuration;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    // ignore: avoid_print
    final surfaceId = args['surfaceId'] as String;
    final definition = args['definition'] as JsonMap;
    final widgets = definition['widgets'] as List?;
    if (widgets == null) {
      return {'status': 'ERROR', 'message': 'Missing widgets'};
    }
    final components = widgets.map((e) {
      final widget = e as JsonMap;
      return Component(
        id: widget['id'] as String,
        componentProperties: widget['widget'] as JsonMap,
      );
    }).toList();
    final surfaceUpdate = SurfaceUpdate(
      surfaceId: surfaceId,
      components: components,
    );
    // ignore: avoid_print
    handleMessage(surfaceUpdate);
    final beginRendering = BeginRendering(
      surfaceId: surfaceId,
      root: definition['root'] as String,
    );
    // ignore: avoid_print
    handleMessage(beginRendering);
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
