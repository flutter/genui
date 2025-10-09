// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

import '../primitives/simple_items.dart';

/// A sealed class representing a message in the A2UI stream.
sealed class A2uiMessage {
  /// Creates an [A2uiMessage].
  const A2uiMessage({required this.surfaceId});

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// Creates an [A2uiMessage] from a JSON map.
  factory A2uiMessage.fromJson(JsonMap json) {
    final surfaceId = json['surfaceId'] as String? ?? '';
    if (json.containsKey('surfaceUpdate')) {
      return SurfaceUpdate.fromJson(
        surfaceId,
        json['surfaceUpdate'] as JsonMap,
      );
    }
    if (json.containsKey('dataModelUpdate')) {
      return DataModelUpdate.fromJson(
        surfaceId,
        json['dataModelUpdate'] as JsonMap,
      );
    }
    if (json.containsKey('beginRendering')) {
      return BeginRendering.fromJson(
        surfaceId,
        json['beginRendering'] as JsonMap,
      );
    }
    if (json.containsKey('surfaceDeletion')) {
      return SurfaceDeletion(surfaceId: surfaceId);
    }
    throw ArgumentError('Unknown A2UI message type: $json');
  }
}

/// An A2UI message that updates a surface with new components.
final class SurfaceUpdate extends A2uiMessage {
  /// Creates a [SurfaceUpdate] message.
  const SurfaceUpdate({required super.surfaceId, required this.components});

  /// Creates a [SurfaceUpdate] message from a JSON map.
  factory SurfaceUpdate.fromJson(String surfaceId, JsonMap json) {
    return SurfaceUpdate(
      surfaceId: surfaceId,
      components: (json['components'] as List<Object?>)
          .map((e) => Component.fromJson(e as JsonMap))
          .toList(),
    );
  }

  /// The list of components to add or update.
  final List<Component> components;
}

/// An A2UI message that updates the data model.
final class DataModelUpdate extends A2uiMessage {
  /// Creates a [DataModelUpdate] message.
  const DataModelUpdate({
    required super.surfaceId,
    this.path,
    required this.contents,
  });

  /// Creates a [DataModelUpdate] message from a JSON map.
  factory DataModelUpdate.fromJson(String surfaceId, JsonMap json) {
    return DataModelUpdate(
      surfaceId: surfaceId,
      path: json['path'] as String?,
      contents: json['contents'] as Object,
    );
  }

  /// The path in the data model to update.
  final String? path;

  /// The new contents to write to the data model.
  final Object contents;
}

/// An A2UI message that signals the client to begin rendering.
final class BeginRendering extends A2uiMessage {
  /// Creates a [BeginRendering] message.
  const BeginRendering({
    required super.surfaceId,
    required this.root,
    this.catalogUri,
    this.styles,
  });

  /// Creates a [BeginRendering] message from a JSON map.
  factory BeginRendering.fromJson(String surfaceId, JsonMap json) {
    return BeginRendering(
      surfaceId: surfaceId,
      root: json['root'] as String,
      catalogUri: json['catalogUri'] as String?,
      styles: json['styles'] as JsonMap?,
    );
  }

  /// The ID of the root component.
  final String root;

  /// The URI of the component catalog to use.
  final String? catalogUri;

  /// The styles to apply to the UI.
  final JsonMap? styles;
}

/// An A2UI message that deletes a surface.
final class SurfaceDeletion extends A2uiMessage {
  /// Creates a [SurfaceDeletion] message.
  const SurfaceDeletion({required super.surfaceId});
}

/// A component in the UI.
final class Component {
  /// Creates a [Component].
  const Component({required this.id, required this.componentProperties});

  /// Creates a [Component] from a JSON map.
  factory Component.fromJson(JsonMap json) {
    return Component(
      id: json['id'] as String,
      componentProperties: json['componentProperties'] as JsonMap,
    );
  }

  /// The unique ID of the component.
  final String id;

  /// The properties of the component.
  final JsonMap componentProperties;

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {'id': id, 'componentProperties': componentProperties};
  }

  /// The type of the component.
  String get type => componentProperties.keys.first;

  @override
  bool operator ==(Object other) =>
      other is Component &&
      id == other.id &&
      const DeepCollectionEquality().equals(
        componentProperties,
        other.componentProperties,
      );

  @override
  int get hashCode =>
      Object.hash(id, const DeepCollectionEquality().hash(componentProperties));
}
