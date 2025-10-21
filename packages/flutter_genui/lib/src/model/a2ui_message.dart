// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

import '../primitives/simple_items.dart';

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
}

/// An A2UI message that updates a surface with new components.
final class SurfaceUpdate extends A2uiMessage {
  /// Creates a [SurfaceUpdate] message.
  const SurfaceUpdate({required this.surfaceId, required this.components});

  /// Creates a [SurfaceUpdate] message from a JSON map.
  factory SurfaceUpdate.fromJson(JsonMap json) {
    return SurfaceUpdate(
      surfaceId: json['surfaceId'] as String,
      components: (json['components'] as List<Object?>)
          .map((e) => Component.fromJson(e as JsonMap))
          .toList(),
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The list of components to add or update.
  final List<Component> components;
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
      surfaceId: json['surfaceId'] as String,
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
  });

  /// Creates a [BeginRendering] message from a JSON map.
  factory BeginRendering.fromJson(JsonMap json) {
    return BeginRendering(
      surfaceId: json['surfaceId'] as String,
      root: json['root'] as String,
      styles: json['styles'] as JsonMap?,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The ID of the root component.
  final String root;

  /// The styles to apply to the UI.
  final JsonMap? styles;
}

/// An A2UI message that deletes a surface.
final class SurfaceDeletion extends A2uiMessage {
  /// Creates a [SurfaceDeletion] message.
  const SurfaceDeletion({required this.surfaceId});

  /// Creates a [SurfaceDeletion] message from a JSON map.
  factory SurfaceDeletion.fromJson(JsonMap json) {
    return SurfaceDeletion(surfaceId: json['surfaceId'] as String);
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;
}

/// A component in the UI.
final class Component {
  /// Creates a [Component].
  const Component({required this.id, required this.componentProperties});

  /// Creates a [Component] from a JSON map.
  factory Component.fromJson(JsonMap json) {
    return Component(
      id: json['id'] as String,
      componentProperties: json['component'] as JsonMap,
    );
  }

  /// The unique ID of the component.
  final String id;

  /// The properties of the component.
  final JsonMap componentProperties;

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {'id': id, 'component': componentProperties};
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
