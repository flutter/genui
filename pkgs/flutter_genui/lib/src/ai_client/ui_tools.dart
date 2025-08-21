// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';

import '../core/genui_manager.dart';
import 'tools.dart';

/// An [AiTool] for adding or updating a UI surface.
///
/// This tool allows the AI to create a new UI surface or update an existing
/// one with a new definition.
class AddOrUpdateSurfaceTool extends AiTool<Map<String, Object?>> {
  /// Creates an [AddOrUpdateSurfaceTool].
  AddOrUpdateSurfaceTool(this.manager)
    : super(
        name: 'addOrUpdateSurface',
        description:
            'Adds a new UI surface or updates an existing one. Use this to '
            'display new content or change what is currently visible.',
        parameters: S.object(
          properties: {
            'surfaceId': S.string(
              description:
                  'The unique identifier for the UI surface to create or '
                  'modify.',
            ),
            'definition': S.object(
              properties: {
                'root': S.string(
                  description:
                      'The ID of the root widget. This ID must correspond to '
                      'the ID of one of the widgets in the `widgets` list.',
                ),
                'widgets': S.list(
                  items: manager.catalog.schema,
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
          required: ['surfaceId', 'definition'],
        ),
      );

  /// The [GenUiManager] to use for updating the UI.
  final GenUiManager manager;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final surfaceId = args['surfaceId'] as String;
    final definition = args['definition'] as Map<String, Object?>;
    manager.addOrUpdateSurface(surfaceId, definition);
    return {'status': 'ok'};
  }
}

/// An [AiTool] for deleting a UI surface.
///
/// This tool allows the AI to remove a UI surface that is no longer needed.
class DeleteSurfaceTool extends AiTool<Map<String, Object?>> {
  /// Creates a [DeleteSurfaceTool].
  DeleteSurfaceTool(this.manager)
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

  /// The [GenUiManager] to use for updating the UI.
  final GenUiManager manager;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> args) async {
    final surfaceId = args['surfaceId'] as String;
    manager.deleteSurface(surfaceId);
    return {'status': 'ok'};
  }
}
