// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/ai_client.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:fcp_client/fcp_client.dart';
import 'package:logging/logging.dart';

import '../fcp_schemas.dart';
import '../fcp_surface_manager.dart';

Map<String, Object?> _reconstructMap(List<Map<String, Object?>> properties) {
  return {
    for (final property in properties)
      property['name'] as String: property['value'],
  };
}

Map<String, Object?> _reconstructBindings(List<Map<String, Object?>> bindings) {
  return {
    for (final binding in bindings)
      binding['name'] as String: {'path': binding['path']},
  };
}

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
  final _log = Logger('ManageUiTool');

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
          description:
              'The ID of the target surface. This is a unique '
              'identifier for the surface, and should be a descriptive '
              'string, like "address_form" or "user_profile".',
        ),
        'layout': fcpLayoutSchema,
        'state': fcpStateSchema,
      },
      required: ['surfaceId', 'layout', 'state'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String?;
      if (surfaceId == null || surfaceId.isEmpty) {
        return {
          'success': false,
          'error': 'The "surfaceId" parameter is required.',
        };
      }
      _log.info('Invoking "set" on surface "$surfaceId".');
      final layoutMap = args['layout'] as Map<String, Object?>;
      final nodes = (layoutMap['nodes'] as List)
          .cast<Map<String, Object?>>()
          .map((node) {
            final properties =
                (node['properties'] as List?)?.cast<Map<String, Object?>>() ??
                [];
            final bindings =
                (node['bindings'] as List?)?.cast<Map<String, Object?>>() ?? [];
            return {
              'id': node['id'],
              'type': node['type'],
              'properties': _reconstructMap(properties),
              'bindings': _reconstructBindings(bindings),
            };
          })
          .toList();
      final layout = Layout.fromMap({
        'root': layoutMap['root'],
        'nodes': nodes,
      });
      final state = _reconstructMap(
        (args['state'] as List).cast<Map<String, Object?>>(),
      );
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
      _log.info('Invoking "get" on surface "$surfaceId".');
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
      _log.info('Invoking "list".');
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
      _log.info('Invoking "remove" on surface "$surfaceId".');
      surfaceManager.removeSurface(surfaceId);
      return {'success': true};
    },
  );

  /// The AI tool for patching the layout of a surface.
  AiTool<Map<String, Object?>> get patchLayout => DynamicAiTool(
    name: 'patchLayout',
    description:
        'Applies a set of JSON Patch (RFC 6902) operations to the layout of a'
        ' specific surface.',
    parameters: Schema.object(
      properties: {
        'surfaceId': Schema.string(
          description: 'The ID of the target surface.',
        ),
        'patches': Schema.list(
          description:
              'An array of JSON Patch operations. See RFC 6902 '
              'for the full specification of the patch format.',
          items: jsonPatchOperationSchema,
        ),
      },
      required: ['surfaceId', 'patches'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String;
      _log.info('Invoking "patchLayout" on surface "$surfaceId".');
      final patches = LayoutUpdate.fromMap({'patches': args['patches']});
      surfaceManager.getController(surfaceId)?.patchLayout(patches);
      return {'success': true};
    },
  );

  /// The AI tool for patching the state of a surface.
  AiTool<Map<String, Object?>> get patchState => DynamicAiTool(
    name: 'patchState',
    description:
        'Applies a set of JSON Patch (RFC 6902) operations to the'
        ' state of a specific surface.',
    parameters: Schema.object(
      properties: {
        'surfaceId': Schema.string(
          description: 'The ID of the target surface.',
        ),
        'patches': Schema.list(
          description:
              'An array of JSON Patch operations. See RFC 6902 '
              'for the full specification of the patch format.',
          items: jsonPatchOperationSchema,
        ),
      },
      required: ['surfaceId', 'patches'],
    ),
    invokeFunction: (args) async {
      final surfaceId = args['surfaceId'] as String;
      _log.info('Invoking "patchState" on surface "$surfaceId".');
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
