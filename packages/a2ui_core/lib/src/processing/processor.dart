// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../core/catalog.dart';
import '../core/component_model.dart';
import '../core/contexts.dart';
import '../core/data_model.dart';
import '../core/messages.dart';
import '../core/surface_group_model.dart';
import '../core/surface_model.dart';
import '../primitives/errors.dart';
import '../primitives/event_notifier.dart';
import '../primitives/reactivity.dart';

/// The central processor for A2UI messages.
class MessageProcessor<T extends ComponentApi> {
  final SurfaceGroupModel<T> groupModel;
  final List<Catalog<T>> catalogs;

  final _onFunctionResponse = EventNotifier<A2uiFunctionResponse>();
  final _onError = EventNotifier<A2uiClientError>();

  /// Fires when a server-initiated function call (`callFunction`) that
  /// requested a response has been executed. The emitted
  /// [A2uiFunctionResponse] should be sent back to the server.
  EventListenable<A2uiFunctionResponse> get onFunctionResponse =>
      _onFunctionResponse;

  /// Fires when processing produces a client error that should be reported
  /// to the server (e.g. an invalid `callFunction`).
  EventListenable<A2uiClientError> get onError => _onError;

  MessageProcessor({
    required this.catalogs,
    void Function(A2uiClientAction)? onAction,
    void Function(A2uiFunctionResponse)? onFunctionResponse,
    void Function(A2uiClientError)? onError,
  }) : groupModel = SurfaceGroupModel<T>() {
    if (onAction != null) {
      groupModel.onAction.addListener(onAction);
    }
    if (onFunctionResponse != null) {
      _onFunctionResponse.addListener(onFunctionResponse);
    }
    if (onError != null) {
      _onError.addListener(onError);
    }
  }

  /// Processes a list of messages.
  void processMessages(List<A2uiMessage> messages) {
    for (final message in messages) {
      _processMessage(message);
    }
  }

  void _processMessage(A2uiMessage message) {
    if (message is CreateSurfaceMessage) {
      _processCreateSurface(message);
    } else if (message is UpdateComponentsMessage) {
      _processUpdateComponents(message);
    } else if (message is UpdateDataModelMessage) {
      _processUpdateDataModel(message);
    } else if (message is DeleteSurfaceMessage) {
      _processDeleteSurface(message);
    } else if (message is CallFunctionMessage) {
      _processCallFunction(message);
    } else if (message is ActionResponseMessage) {
      _processActionResponse(message);
    }
  }

  void _processCreateSurface(CreateSurfaceMessage message) {
    final Catalog<T> catalog = catalogs.firstWhere(
      (c) => c.id == message.catalogId,
      orElse: () =>
          throw A2uiStateError('Catalog not found: ${message.catalogId}'),
    );

    if (groupModel.getSurface(message.surfaceId) != null) {
      throw A2uiStateError('Surface ${message.surfaceId} already exists.');
    }

    final surface = SurfaceModel<T>(
      message.surfaceId,
      catalog: catalog,
      surfaceProperties: message.surfaceProperties ?? {},
      sendDataModel: message.sendDataModel,
    );
    groupModel.addSurface(surface);

    final Map<String, dynamic>? dataModel = message.dataModel;
    if (dataModel != null) {
      surface.dataModel.set('/', dataModel);
    }
    final List<Map<String, dynamic>>? components = message.components;
    if (components != null) {
      _applyComponents(surface, components);
    }
  }

  void _processUpdateComponents(UpdateComponentsMessage message) {
    final SurfaceModel<T>? surface = groupModel.getSurface(message.surfaceId);
    if (surface == null) {
      throw A2uiStateError('Surface not found: ${message.surfaceId}');
    }

    _applyComponents(surface, message.components);
  }

  void _applyComponents(
    SurfaceModel<T> surface,
    List<Map<String, dynamic>> components,
  ) {
    for (final compJson in components) {
      final id = compJson['id'] as String?;
      final type = compJson['component'] as String?;

      if (id == null) {
        throw A2uiValidationError("Component missing an 'id'.");
      }

      final ComponentModel? existing = surface.componentsModel.get(id);
      final props = Map<String, dynamic>.from(compJson)
        ..remove('id')
        ..remove('component');

      if (existing != null) {
        if (type != null && type != existing.type) {
          // Recreate if type changes
          surface.componentsModel.removeComponent(id);
          surface.componentsModel.addComponent(ComponentModel(id, type, props));
        } else {
          existing.properties = props;
        }
      } else {
        if (type == null) {
          throw A2uiValidationError(
            "Cannot create component $id without a 'component' type.",
          );
        }
        surface.componentsModel.addComponent(ComponentModel(id, type, props));
      }
    }
  }

  void _processUpdateDataModel(UpdateDataModelMessage message) {
    final SurfaceModel<T>? surface = groupModel.getSurface(message.surfaceId);
    if (surface == null) {
      throw A2uiStateError('Surface not found: ${message.surfaceId}');
    }

    surface.dataModel.set(message.path ?? '/', message.value);
  }

  void _processDeleteSurface(DeleteSurfaceMessage message) {
    groupModel.deleteSurface(message.surfaceId);
  }

  void _processCallFunction(CallFunctionMessage message) {
    FunctionImplementation? fn;
    Catalog<T>? owningCatalog;
    for (final Catalog<T> catalog in catalogs) {
      fn = catalog.functions[message.call];
      if (fn != null) {
        owningCatalog = catalog;
        break;
      }
    }

    if (fn == null || !fn.callableFrom.isRemoteCallable) {
      _onError.emit(
        A2uiClientError(
          code: 'INVALID_FUNCTION_CALL',
          functionCallId: message.functionCallId,
          message: fn == null
              ? "Function '${message.call}' is not registered in any "
                    'catalog.'
              : "Function '${message.call}' is configured as "
                    "'${fn.callableFrom.jsonValue}' and cannot be invoked "
                    'remotely.',
        ),
      );
      return;
    }

    Object? result;
    try {
      result = owningCatalog!.invoke(
        message.call,
        Map<String, dynamic>.from(message.args ?? {}),
        DataContext(DataModel(), owningCatalog.invoke, '/'),
      );
      if (result is ReadonlySignal) {
        result = result.value;
      }
    } catch (e) {
      _onError.emit(
        A2uiClientError(
          code: 'FUNCTION_EXECUTION_ERROR',
          functionCallId: message.functionCallId,
          message: "Function '${message.call}' failed: $e",
        ),
      );
      return;
    }

    if (message.wantResponse) {
      _onFunctionResponse.emit(
        A2uiFunctionResponse(
          functionCallId: message.functionCallId,
          call: message.call,
          value: result,
        ),
      );
    }
  }

  void _processActionResponse(ActionResponseMessage message) {
    for (final SurfaceModel<T> surface in groupModel.allSurfaces) {
      if (surface.applyActionResponse(message)) {
        return;
      }
    }
    throw A2uiStateError(
      'No pending action found for actionId: ${message.actionId}',
    );
  }

  /// Generates client capabilities.
  Map<String, dynamic> getClientCapabilities({
    bool includeInlineCatalogs = false,
  }) {
    final v10 = <String, dynamic>{
      'supportedCatalogIds': catalogs.map((c) => c.id).toList(),
    };

    if (includeInlineCatalogs) {
      v10['inlineCatalogs'] = catalogs.map(_generateInlineCatalog).toList();
    }

    return {'v1.0': v10};
  }

  Map<String, dynamic> _generateInlineCatalog(Catalog<T> catalog) {
    final components = <String, dynamic>{};
    for (final MapEntry<String, T> entry in catalog.components.entries) {
      final Map<String, dynamic> jsonSchema = entry.value.schema.toJsonMap();
      _processRefs(jsonSchema);

      // Wrap in A2UI envelope
      components[entry.key] = {
        'allOf': [
          {'\$ref': 'common_types.json#/\$defs/ComponentCommon'},
          {
            'properties': {
              'component': {'const': entry.key},
              ...?(jsonSchema['properties'] as Map<String, dynamic>?),
            },
            'required': ['component', ...?(jsonSchema['required'] as List?)],
          },
        ],
      };
    }

    final functions = <String, dynamic>{};
    for (final FunctionImplementation f in catalog.functions.values) {
      final Map<String, dynamic> jsonSchema = f.argumentSchema.toJsonMap();
      _processRefs(jsonSchema);
      functions[f.name] = {
        'type': 'object',
        'properties': {
          'call': {'const': f.name},
          'args': jsonSchema,
        },
        'required': ['call'],
        'additionalProperties': false,
        'returnType': f.returnType.jsonValue,
        'callableFrom': f.callableFrom.jsonValue,
      };
    }

    Map<String, dynamic>? surfaceProperties;
    if (catalog.surfacePropertiesSchema != null) {
      surfaceProperties = catalog.surfacePropertiesSchema!.toJsonMap();
      _processRefs(surfaceProperties);
    }

    return {
      'catalogId': catalog.id,
      if (catalog.instructions != null) 'instructions': catalog.instructions,
      'components': components,
      if (functions.isNotEmpty) 'functions': functions,
      '\$defs': {
        'anyComponent': {
          'oneOf': [
            for (final String name in components.keys)
              {'\$ref': '#/components/$name'},
          ],
        },
        // A boolean 'false' schema when there are no functions: no function
        // call validates against a catalog that defines none.
        'anyFunction': functions.isEmpty
            ? false
            : {
                'oneOf': [
                  for (final String name in functions.keys)
                    {'\$ref': '#/functions/$name'},
                ],
              },
        'surfaceProperties': ?surfaceProperties,
      },
    };
  }

  void _processRefs(Object? node) {
    if (node is! Map) return;

    if (node['description'] is String &&
        (node['description'] as String).startsWith('REF:')) {
      final desc = node['description'] as String;
      final List<String> parts = desc.substring(4).split('|');
      final String ref = parts[0];
      final String? actualDesc = parts.length > 1 ? parts[1] : null;

      node.clear();
      node['\$ref'] = ref;
      if (actualDesc != null) {
        node['description'] = actualDesc;
      }
      return;
    }

    node.forEach((key, value) {
      if (value is Map) {
        _processRefs(value);
      } else if (value is List) {
        for (final Object? item in value) {
          if (item is Map) {
            _processRefs(item);
          }
        }
      }
    });
  }

  /// Aggregates data models for surfaces with sendDataModel enabled.
  Map<String, dynamic>? getClientDataModel() {
    final surfaces = <String, dynamic>{};
    for (final SurfaceModel<T> surface in groupModel.allSurfaces) {
      if (surface.sendDataModel) {
        surfaces[surface.id] = surface.dataModel.get('/');
      }
    }

    if (surfaces.isEmpty) return null;

    return {'version': a2uiProtocolVersion, 'surfaces': surfaces};
  }
}

extension SchemaExtension on Schema {
  Map<String, dynamic> toJsonMap() => _deepCopy(value);

  static Map<String, dynamic> _deepCopy(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key as String, _deepCopy(value));
      }
      if (value is List) {
        return MapEntry(
          key as String,
          value.map((item) => item is Map ? _deepCopy(item) : item).toList(),
        );
      }
      return MapEntry(key as String, value);
    });
  }
}
