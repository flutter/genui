// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/ai_client.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:fcp_client/fcp_client.dart';
import 'package:logging/logging.dart';

import '../fcp_schemas.dart';
import '../fcp_surface_manager.dart';

Map<String, Object?> _getSurfacesState(FcpSurfaceManager surfaceManager) {
  final surfaces = surfaceManager.listSurfaces();
  final surfaceData = <String, Object?>{};
  for (final surfaceId in surfaces) {
    final packet = surfaceManager.getPacket(surfaceId);
    if (packet != null) {
      final layoutJson = packet.layout.toJson();
      final nodes = (layoutJson['nodes'] as List<Object?>).map((node) {
        final nodeMap = node as Map<String, Object?>;
        final properties = nodeMap['properties'] as Map<String, Object?>?;
        final bindings = nodeMap['bindings'] as Map<String, Object?>?;
        return {
          ...nodeMap,
          'properties': _deconstructMap(properties),
          'bindings': _deconstructBindings(bindings),
        };
      }).toList();
      surfaceData[surfaceId] = {
        'layout': {'root': layoutJson['root'], 'nodes': nodes},
        'state': _deconstructMap(packet.state),
      };
    }
  }
  return {'current_ui': surfaceData};
}

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

List<Map<String, Object?>> _deconstructMap(Map<String, Object?>? map) {
  if (map == null) {
    return [];
  }
  return map.entries.map((e) => {'name': e.key, 'value': e.value}).toList();
}

List<Map<String, Object?>> _deconstructBindings(
  Map<String, Object?>? bindings,
) {
  if (bindings == null) {
    return [];
  }
  return bindings.entries.map((e) {
    final binding = e.value as Map<String, Object?>;
    return {'name': e.key, 'path': binding['path']};
  }).toList();
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
    prefix: 'ui',
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
      final stateData = args['state'];
      final Map<String, Object?> state;
      if (stateData is List) {
        state = _reconstructMap(stateData.cast<Map<String, Object?>>());
      } else {
        state = (stateData as Map).cast<String, Object?>();
      }
      final packet = DynamicUIPacket(layout: layout, state: state);
      surfaceManager.setSurface(surfaceId, packet);
      return {
        'success': true,
        'outcome': 'Surface $surfaceId was set.',
        ..._getSurfacesState(surfaceManager),
      };
    },
  );

  /// The AI tool for getting the UI of a surface.
  AiTool<Map<String, Object?>> get get => DynamicAiTool(
    name: 'get',
    prefix: 'ui',
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
      if (packet == null) {
        return {'layout': {}, 'state': []};
      }
      final layoutJson = packet.layout.toJson();
      final nodes = (layoutJson['nodes'] as List<Object?>).map((node) {
        final nodeMap = node as Map<String, Object?>;
        final properties = nodeMap['properties'] as Map<String, Object?>?;
        final bindings = nodeMap['bindings'] as Map<String, Object?>?;
        return {
          ...nodeMap,
          'properties': _deconstructMap(properties),
          'bindings': _deconstructBindings(bindings),
        };
      }).toList();
      return {
        'layout': {'root': layoutJson['root'], 'nodes': nodes},
        'state': _deconstructMap(packet.state),
      };
    },
  );

  /// The AI tool for listing the active surfaces.
  AiTool<Map<String, Object?>> get list => DynamicAiTool(
    name: 'list',
    prefix: 'ui',
    description: 'Lists the IDs of all currently active surfaces.',
    invokeFunction: (args) async {
      _log.info('Invoking "list".');
      return {'surfaceIds': surfaceManager.listSurfaces()};
    },
  );

  /// The AI tool for removing a surface.
  AiTool<Map<String, Object?>> get remove => DynamicAiTool(
    name: 'remove',
    prefix: 'ui',
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
      return {'success': true, ..._getSurfacesState(surfaceManager)};
    },
  );

  /// The AI tool for patching the layout of a surface.
  AiTool<Map<String, Object?>> get patchLayout => DynamicAiTool(
    name: 'patchLayout',
    prefix: 'ui',
    description:
        'Applies a set of JSON Patch (RFC 6902) operations to the '
        'layout of a specific surface. The path for the patch can '
        'use either an index or a widget ID to identify the node to '
        'update. For example, `/nodes/0/properties/children/5` and '
        '`/nodes/address_form_column/properties/children/5` are both '
        'valid paths, assuming `address_form_column` is at index 0.',
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
      _log.info(
        'Invoking "patchLayout" on surface "$surfaceId" with patches: '
        '${args['patches']}',
      );
      final patchesList = (args['patches'] as List)
          .cast<Map<String, Object?>>();
      final packet = surfaceManager.getPacket(surfaceId);
      if (packet == null) {
        return {
          'success': false,
          'error': 'Surface with id "$surfaceId" not found.',
        };
      }

      // Resolve widget IDs in paths to indices.
      final resolvedPatches = <Map<String, Object?>>[];
      for (final patch in patchesList) {
        final path = patch['path'] as String;
        final parts = path.split('/');
        if (parts.length > 2 && parts[1] == 'nodes') {
          final nodeId = parts[2];
          final nodeIndex = packet.layout.nodes.indexWhere(
            (node) => node.id == nodeId,
          );
          if (nodeIndex != -1) {
            parts[2] = nodeIndex.toString();
            final newPatch = {...patch, 'path': parts.join('/')};
            resolvedPatches.add(newPatch);
          } else {
            // If the node ID is not found, maybe it's already an index.
            if (int.tryParse(nodeId) != null) {
              resolvedPatches.add(patch);
            } else {
              return {
                'success': false,
                'error': 'Widget with id "$nodeId" not found in layout.',
              };
            }
          }
        } else {
          resolvedPatches.add(patch);
        }
      }

      final patches = LayoutUpdate.fromMap({'patches': resolvedPatches});
      surfaceManager.getController(surfaceId)?.patchLayout(patches);
      return {
        'success': true,
        'outcome': 'Layout for $surfaceId was patched.',
        ..._getSurfacesState(surfaceManager),
      };
    },
  );

  /// The AI tool for patching the state of a surface.
  AiTool<Map<String, Object?>> get patchState => DynamicAiTool(
    name: 'patchState',
    prefix: 'ui',
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
      return {
        'success': true,
        'outcome': 'State for $surfaceId was patched.',
        ..._getSurfacesState(surfaceManager),
      };
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
