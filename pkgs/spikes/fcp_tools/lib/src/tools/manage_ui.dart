// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/ai_client.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:fcp_client/fcp_client.dart';

import '../fcp_surface_manager.dart';

/// A tool for managing the UI of a surface.
///
/// This tool provides a set of actions for creating, updating, and removing
/// UI surfaces.
class ManageUiTool {
  /// Creates a new instance of the [ManageUiTool].
  ///
  /// The [surfaceManager] is used to interact with the UI surfaces.
  ManageUiTool(this.surfaceManager);

  /// The surface manager used to interact with the UI surfaces.
  final FcpSurfaceManager surfaceManager;

  /// The AI tool for setting the UI of a surface.
  AiTool<Map<String, Object?>> get set => DynamicAiTool(
    name: 'set',
    description:
        'Sets the complete UI for a given surface. If the surface with the '
        'specified `surfaceId` does not exist, it will be created. This '
        'will replace any existing UI on that surface.',
    parameters: Schema.object(
      properties: {
        'surfaceId': Schema.string(
          description: 'The ID of the target surface.',
        ),
        'layout': Schema.object(description: 'A valid FCP Layout object.'),
        'state': Schema.object(description: 'A valid FCP State object.'),
      },
      required: ['surfaceId', 'layout', 'state'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String;
      final layout = Layout.fromMap(args['layout'] as Map<String, Object?>);
      final state = args['state'] as Map<String, Object?>;
      final packet = DynamicUIPacket(layout: layout, state: state);
      surfaceManager.setSurface(surfaceId, packet);
      return {'success': true};
    },
  );

  /// The AI tool for getting the UI of a surface.
  AiTool<Map<String, Object?>> get get => DynamicAiTool(
    name: 'get',
    description: 'Retrieves the current Layout and State for a given surface.',
    parameters: Schema.object(
      properties: {
        'surfaceId': Schema.string(
          description: 'The ID of the target surface.',
        ),
      },
      required: ['surfaceId'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String;
      final packet = surfaceManager.getPacket(surfaceId);
      return {
        'layout': packet?.layout.toJson() ?? {},
        'state': packet?.state ?? {},
      };
    },
  );

  /// The AI tool for listing the active surfaces.
  AiTool<Map<String, Object?>> get list => DynamicAiTool(
    name: 'list',
    description: 'Lists the IDs of all currently active surfaces.',
    invokeFunction: (args) async {
      return {'surfaceIds': surfaceManager.listSurfaces()};
    },
  );

  /// The AI tool for removing a surface.
  AiTool<Map<String, Object?>> get remove => DynamicAiTool(
    name: 'remove',
    description: 'Removes/destroys the UI surface with the specified ID.',
    parameters: Schema.object(
      properties: {
        'surfaceId': Schema.string(
          description: 'The ID of the surface to remove.',
        ),
      },
      required: ['surfaceId'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String;
      surfaceManager.removeSurface(surfaceId);
      return {'success': true};
    },
  );

  /// The AI tool for patching the layout of a surface.
  AiTool<Map<String, Object?>> get patchLayout => DynamicAiTool(
        name: 'patchLayout',
        description: 'Applies a set of patch operations to the layout of a'
            ' specific surface.',
    parameters: Schema.object(
      properties: {
        'surfaceId': Schema.string(
          description: 'The ID of the target surface.',
        ),
        'operations': Schema.list(
          description: 'An array of FCP layout patch operations.',
          items: Schema.object(),
        ),
      },
      required: ['surfaceId', 'operations'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String;
      final operations = LayoutUpdate.fromMap({
        'operations': args['operations'],
      });
      surfaceManager.getController(surfaceId)?.patchLayout(operations);
      return {'success': true};
    },
  );

  /// The AI tool for patching the state of a surface.
  AiTool<Map<String, Object?>> get patchState => DynamicAiTool(
        name: 'patchState',
        description: 'Applies a set of JSON Patch (RFC 6902) operations to the'
            ' state of a specific surface.',
    parameters: Schema.object(
      properties: {
        'surfaceId': Schema.string(
          description: 'The ID of the target surface.',
        ),
        'patches': Schema.list(
          description: 'An array of JSON Patch operations.',
          items: Schema.object(),
        ),
      },
      required: ['surfaceId', 'patches'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String;
      final patches = StateUpdate.fromMap({'patches': args['patches']});
      surfaceManager.getController(surfaceId)?.patchState(patches);
      return {'success': true};
    },
  );

  /// Returns a list of all the tools in this group.
  List<AiTool<Map<String, Object?>>> get tools => [
    set,
    get,
    list,
    remove,
    patchLayout,
    patchState,
  ];
}
