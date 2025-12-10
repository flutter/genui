// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../primitives/simple_items.dart';
import 'a2ui_schemas.dart';
import 'catalog.dart';
import 'tools.dart';
import 'ui_models.dart';

/// A sealed class representing a message in the A2UI stream.
sealed class A2uiMessage {
  /// Creates an [A2uiMessage].
  const A2uiMessage();

  /// Creates an [A2uiMessage] from a JSON map.
  factory A2uiMessage.fromJson(JsonMap json) {
    if (json.containsKey('updateComponents')) {
      return UpdateComponents.fromJson(json['updateComponents'] as JsonMap);
    }
    if (json.containsKey('updateDataModel')) {
      return UpdateDataModel.fromJson(json['updateDataModel'] as JsonMap);
    }
    if (json.containsKey('createSurface')) {
      return CreateSurface.fromJson(json['createSurface'] as JsonMap);
    }
    if (json.containsKey('deleteSurface')) {
      return SurfaceDeletion.fromJson(json['deleteSurface'] as JsonMap);
    }
    if (json.containsKey('error')) {
      return ErrorMessage.fromJson(json['error'] as JsonMap);
    }
    throw ArgumentError('Unknown A2UI message type: $json');
  }

  /// Returns the JSON schema for an A2UI message.
  static Schema a2uiMessageSchema(Catalog catalog) {
    return S.object(
      title: 'A2UI Message Schema',
      description:
          """Describes a JSON payload for an A2UI (Agent to UI) message, which is used to dynamically construct and update user interfaces. A message MUST contain exactly ONE of the action properties: 'createSurface', 'updateComponents', 'updateDataModel', or 'deleteSurface'.""",
      properties: {
        'updateComponents': A2uiSchemas.updateComponentsSchema(catalog),
        'updateDataModel': A2uiSchemas.updateDataModelSchema(),
        'createSurface': A2uiSchemas.createSurfaceSchema(),
        'deleteSurface': A2uiSchemas.surfaceDeletionSchema(),
        'error': A2uiSchemas.errorSchema(),
      },
    );
  }
}

/// An A2UI message that updates a surface with new components.
final class UpdateComponents extends A2uiMessage {
  /// Creates a [UpdateComponents] message.
  const UpdateComponents({required this.surfaceId, required this.components});

  /// Creates a [UpdateComponents] message from a JSON map.
  factory UpdateComponents.fromJson(JsonMap json) {
    return UpdateComponents(
      surfaceId: json[surfaceIdKey] as String,
      components: (json['components'] as List<Object?>)
          .map((e) => Component.fromJson(e as JsonMap))
          .toList(),
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The list of components to add or update.
  final List<Component> components;

  /// Converts this object to a JSON representation.
  JsonMap toJson() {
    return {
      surfaceIdKey: surfaceId,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }
}

/// An A2UI message that updates the data model.
final class UpdateDataModel extends A2uiMessage {
  /// Creates a [UpdateDataModel] message.
  const UpdateDataModel({
    required this.surfaceId,
    this.path,
    this.op = 'replace',
    required this.value,
  });

  /// Creates a [UpdateDataModel] message from a JSON map.
  factory UpdateDataModel.fromJson(JsonMap json) {
    return UpdateDataModel(
      surfaceId: json[surfaceIdKey] as String,
      path: json['path'] as String?,
      op: json['op'] as String? ?? 'replace',
      value: json['value'] as Object,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The path in the data model to update.
  final String? path;

  /// The operation to perform (add, replace, remove).
  final String op;

  /// The new value to write to the data model.
  final Object value;
}

/// An A2UI message that signals the client to begin rendering.
final class CreateSurface extends A2uiMessage {
  /// Creates a [CreateSurface] message.
  const CreateSurface({required this.surfaceId, required this.catalogId});

  /// Creates a [CreateSurface] message from a JSON map.
  factory CreateSurface.fromJson(JsonMap json) {
    return CreateSurface(
      surfaceId: json[surfaceIdKey] as String,
      catalogId: json['catalogId'] as String,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The catalog ID used for this surface.
  final String catalogId;
}

/// An A2UI message that deletes a surface.
final class SurfaceDeletion extends A2uiMessage {
  /// Creates a [SurfaceDeletion] message.
  const SurfaceDeletion({required this.surfaceId});

  /// Creates a [SurfaceDeletion] message from a JSON map.
  factory SurfaceDeletion.fromJson(JsonMap json) {
    return SurfaceDeletion(surfaceId: json[surfaceIdKey] as String);
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;
}

/// An A2UI message that reports an error.
final class ErrorMessage extends A2uiMessage {
  /// Creates a [ErrorMessage] message.
  const ErrorMessage({
    required this.code,
    required this.message,
    this.surfaceId,
    this.path,
  });

  /// Creates a [ErrorMessage] message from a JSON map.
  factory ErrorMessage.fromJson(JsonMap json) {
    return ErrorMessage(
      code: json['code'] as String,
      message: json['message'] as String,
      surfaceId: json['surfaceId'] as String?,
      path: json['path'] as String?,
    );
  }

  /// The error code.
  final String code;

  /// The error message.
  final String message;

  /// The ID of the surface that this error applies to.
  final String? surfaceId;

  /// The path in the data model that this error applies to.
  final String? path;
}
