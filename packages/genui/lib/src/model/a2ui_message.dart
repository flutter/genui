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
    if (json.containsKey('surfaceUpdate')) {
      return SurfaceUpdate.fromJson(json['surfaceUpdate'] as JsonMap);
    }
    if (json.containsKey('dataModelUpdate')) {
      return DataModelUpdate.fromJson(json['dataModelUpdate'] as JsonMap);
    }
    if (json.containsKey('beginRendering')) {
      return BeginRendering.fromJson(json['beginRendering'] as JsonMap);
    }
    if (json.containsKey('deleteSurface')) {
      return SurfaceDeletion.fromJson(json['deleteSurface'] as JsonMap);
    }
    throw ArgumentError('Unknown A2UI message type: $json');
  }

  /// Returns the JSON schema for an A2UI message.
  static Schema a2uiMessageSchema(Catalog catalog) {
    return S.object(
      title: 'A2UI Message Schema',
      description:
          """Describes a JSON payload for an A2UI (Agent to UI) message, which is used to dynamically construct and update user interfaces. A message MUST contain exactly ONE of the action properties: 'beginRendering', 'surfaceUpdate', 'dataModelUpdate', or 'deleteSurface'.""",
      properties: {
        'surfaceUpdate': A2uiSchemas.surfaceUpdateSchema(catalog),
        'dataModelUpdate': A2uiSchemas.dataModelUpdateSchema(),
        'beginRendering': A2uiSchemas.beginRenderingSchema(),
        'deleteSurface': A2uiSchemas.surfaceDeletionSchema(),
      },
    );
  }
}

/// An A2UI message that updates a surface with new components.
final class SurfaceUpdate extends A2uiMessage {
  /// Creates a [SurfaceUpdate] message.
  const SurfaceUpdate({required this.surfaceId, required this.components});

  /// Creates a [SurfaceUpdate] message from a JSON map.
  factory SurfaceUpdate.fromJson(JsonMap json) {
    return SurfaceUpdate(
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
final class DataModelUpdate extends A2uiMessage {
  /// Creates a [DataModelUpdate] message.
  const DataModelUpdate({
    required this.surfaceId,
    this.path,
    required this.contents,
  });

  /// Creates a [DataModelUpdate] message from a JSON map.
  factory DataModelUpdate.fromJson(JsonMap json) {
    return DataModelUpdate(
      surfaceId: json[surfaceIdKey] as String,
      path: json['path'] as String?,
      contents: json['contents'] as Object,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The path in the data model to update.
  final String? path;

  /// The new contents to write to the data model.
  final Object contents;
}

/// An A2UI message that signals the client to begin rendering.
final class BeginRendering extends A2uiMessage {
  /// Creates a [BeginRendering] message.
  const BeginRendering({
    required this.surfaceId,
    required this.root,
    this.styles,
    this.catalogId,
  });

  /// Creates a [BeginRendering] message from a JSON map.
  factory BeginRendering.fromJson(JsonMap json) {
    return BeginRendering(
      surfaceId: json[surfaceIdKey] as String,
      root: json['root'] as String,
      styles: json['styles'] as JsonMap?,
      catalogId: json['catalogId'] as String?,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The ID of the root component.
  final String root;

  /// The styles to apply to the UI.
  final JsonMap? styles;

  /// The ID of the catalog to use for rendering this surface.
  final String? catalogId;
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
