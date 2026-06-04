// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../primitives/a2ui_validation_exception.dart';
import '../primitives/simple_items.dart';
import 'a2ui_schemas.dart';
import 'catalog.dart';
import 'data_model.dart';
import 'ui_models.dart';

/// A source-compatible GenUI facade for A2UI protocol messages.
///
/// The canonical parser and processor live in `a2ui_core`; these classes keep
/// the legacy GenUI names while converting to/from the core message types at
/// the renderer boundary.
abstract class A2uiMessage {
  const A2uiMessage({this.version = 'v0.9'});

  factory A2uiMessage.fromJson(JsonMap json) {
    try {
      return A2uiMessage.fromCore(
        core.A2uiMessage.fromJson(Map<String, dynamic>.from(json)),
      );
    } on core.A2uiValidationError catch (e) {
      String message = e.message;
      if (message.contains("'version'")) {
        message = 'A2UI message must have version "v0.9"';
      }
      throw A2uiValidationException(message, json: json, cause: e);
    } catch (e) {
      throw A2uiValidationException(
        'Failed to parse A2UI message',
        json: json,
        cause: e,
      );
    }
  }

  /// Creates a facade message from a core message.
  factory A2uiMessage.fromCore(core.A2uiMessage message) {
    return switch (message) {
      core.CreateSurfaceMessage() => CreateSurface.fromCore(message),
      core.UpdateComponentsMessage() => UpdateComponents.fromCore(message),
      core.UpdateDataModelMessage() => UpdateDataModel.fromCore(message),
      core.DeleteSurfaceMessage() => DeleteSurface.fromCore(message),
      _ => throw A2uiValidationException(
        'Unknown A2UI message type: ${message.runtimeType}',
      ),
    };
  }

  /// Returns the JSON schema for an A2UI message.
  static Schema a2uiMessageSchema(Catalog catalog) =>
      _buildA2uiMessageSchema(catalog);

  /// The protocol version.
  final String version;

  /// Converts this facade message to the core substrate message.
  core.A2uiMessage toCoreMessage();

  Map<String, dynamic> toJson() => toCoreMessage().toJson();
}

/// Returns the JSON schema for an A2UI message, parameterized by [catalog].
Schema a2uiMessageSchema(Catalog catalog) => _buildA2uiMessageSchema(catalog);

Schema _buildA2uiMessageSchema(Catalog catalog) {
  return S.combined(
    title: 'A2UI Message Schema',
    description:
        'Describes a JSON payload for an A2UI (Agent to UI) message, '
        'which is used to dynamically construct and update user interfaces.',
    oneOf: [
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'createSurface': A2uiSchemas.createSurfaceSchema(),
        },
        required: ['version', 'createSurface'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'updateComponents': A2uiSchemas.updateComponentsSchema(catalog),
        },
        required: ['version', 'updateComponents'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'updateDataModel': A2uiSchemas.updateDataModelSchema(),
        },
        required: ['version', 'updateDataModel'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'deleteSurface': A2uiSchemas.deleteSurfaceSchema(),
        },
        required: ['version', 'deleteSurface'],
        additionalProperties: false,
      ),
    ],
  );
}

/// An A2UI message that signals the client to create and show a new surface.
final class CreateSurface extends A2uiMessage {
  const CreateSurface({
    super.version,
    required this.surfaceId,
    required this.catalogId,
    this.theme,
    this.sendDataModel = false,
  });

  /// Creates a [CreateSurface] message from a JSON map body.
  factory CreateSurface.fromJson(JsonMap json) {
    return CreateSurface(
      surfaceId: json[surfaceIdKey] as String,
      catalogId: json['catalogId'] as String,
      theme: json['theme'] as JsonMap?,
      sendDataModel: json['sendDataModel'] as bool? ?? false,
    );
  }

  factory CreateSurface.fromCore(core.CreateSurfaceMessage message) {
    return CreateSurface(
      version: message.version,
      surfaceId: message.surfaceId,
      catalogId: message.catalogId,
      theme: message.theme == null ? null : JsonMap.from(message.theme!),
      sendDataModel: message.sendDataModel,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The ID of the catalog to use for rendering this surface.
  final String catalogId;

  /// The theme parameters for this surface.
  final JsonMap? theme;

  /// If true, the client sends the full data model in A2A metadata.
  final bool sendDataModel;

  @override
  core.CreateSurfaceMessage toCoreMessage() {
    return core.CreateSurfaceMessage(
      version: version,
      surfaceId: surfaceId,
      catalogId: catalogId,
      theme: theme == null ? null : Map<String, dynamic>.from(theme!),
      sendDataModel: sendDataModel,
    );
  }
}

/// An A2UI message that updates a surface with new components.
final class UpdateComponents extends A2uiMessage {
  const UpdateComponents({
    super.version,
    required this.surfaceId,
    required this.components,
  });

  /// Creates an [UpdateComponents] message from a JSON map body.
  factory UpdateComponents.fromJson(JsonMap json) {
    return UpdateComponents(
      surfaceId: json[surfaceIdKey] as String,
      components: (json['components'] as List<Object?>)
          .map((e) => Component.fromJson(e as JsonMap))
          .toList(),
    );
  }

  factory UpdateComponents.fromCore(core.UpdateComponentsMessage message) {
    return UpdateComponents(
      version: message.version,
      surfaceId: message.surfaceId,
      components: message.components
          .map((json) => Component.fromJson(JsonMap.from(json)))
          .toList(),
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The list of components to add or update.
  final List<Component> components;

  @override
  core.UpdateComponentsMessage toCoreMessage() {
    return core.UpdateComponentsMessage(
      version: version,
      surfaceId: surfaceId,
      components: components.map((c) => c.toCoreJson()).toList(),
    );
  }
}

/// An A2UI message that updates the data model.
final class UpdateDataModel extends A2uiMessage {
  /// Creates an [UpdateDataModel] message that sets [path] to [value].
  const UpdateDataModel({
    super.version,
    required this.surfaceId,
    this.path = DataPath.root,
    this.value,
  }) : hasValue = true;

  /// Creates an [UpdateDataModel] message that removes the key at [path].
  const UpdateDataModel.removeKey({
    super.version,
    required this.surfaceId,
    this.path = DataPath.root,
  }) : value = null,
       hasValue = false;

  /// Creates an [UpdateDataModel] message from a JSON map body.
  factory UpdateDataModel.fromJson(JsonMap json) {
    final path = DataPath(json['path'] as String? ?? '/');
    if (json.containsKey('value')) {
      return UpdateDataModel(
        surfaceId: json[surfaceIdKey] as String,
        path: path,
        value: json['value'],
      );
    }
    return UpdateDataModel.removeKey(
      surfaceId: json[surfaceIdKey] as String,
      path: path,
    );
  }

  factory UpdateDataModel.fromCore(core.UpdateDataModelMessage message) {
    final path = DataPath(message.path ?? '/');
    if (message.hasValue) {
      return UpdateDataModel(
        version: message.version,
        surfaceId: message.surfaceId,
        path: path,
        value: message.value,
      );
    }
    return UpdateDataModel.removeKey(
      version: message.version,
      surfaceId: message.surfaceId,
      path: path,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The path in the data model to update. Defaults to root '/'.
  final DataPath path;

  /// The new value to write to the data model.
  final Object? value;

  /// Whether the wire JSON carries an explicit `value` key.
  final bool hasValue;

  @override
  core.UpdateDataModelMessage toCoreMessage() {
    if (!hasValue) {
      return core.UpdateDataModelMessage.removeKey(
        version: version,
        surfaceId: surfaceId,
        path: path.toString(),
      );
    }
    return core.UpdateDataModelMessage(
      version: version,
      surfaceId: surfaceId,
      path: path.toString(),
      value: value,
    );
  }
}

/// An A2UI message that deletes a surface.
final class DeleteSurface extends A2uiMessage {
  const DeleteSurface({super.version, required this.surfaceId});

  /// Creates a [DeleteSurface] message from a JSON map body.
  factory DeleteSurface.fromJson(JsonMap json) {
    return DeleteSurface(surfaceId: json[surfaceIdKey] as String);
  }

  factory DeleteSurface.fromCore(core.DeleteSurfaceMessage message) {
    return DeleteSurface(
      version: message.version,
      surfaceId: message.surfaceId,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  @override
  core.DeleteSurfaceMessage toCoreMessage() {
    return core.DeleteSurfaceMessage(version: version, surfaceId: surfaceId);
  }
}
