// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'component.dart';

/// A sealed class for all messages in the A2UI Streaming UI Protocol.
sealed class A2uiStreamMessage {
  /// Creates a [A2uiStreamMessage] from a JSON object.
  factory A2uiStreamMessage.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('beginRendering')) {
      return BeginRendering.fromJson(
        json['beginRendering'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('surfaceUpdate')) {
      return SurfaceUpdate.fromJson(
        json['surfaceUpdate'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('dataModelUpdate')) {
      return DataModelUpdate.fromJson(
        json['dataModelUpdate'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('surfaceDeletion')) {
      return SurfaceDeletion.fromJson(
        json['surfaceDeletion'] as Map<String, dynamic>,
      );
    }
    throw Exception('Unknown message type in JSON: $json');
  }
}

/// A message that signals the client to begin rendering the UI.
class BeginRendering implements A2uiStreamMessage {
  /// Creates a [BeginRendering].
  const BeginRendering({
    required this.surfaceId,
    required this.root,
    this.styles,
  });

  /// Creates a [BeginRendering] from a JSON object.
  factory BeginRendering.fromJson(Map<String, dynamic> json) {
    return BeginRendering(
      surfaceId: json['surfaceId'] as String,
      root: json['root'] as String,
      styles: json['styles'] as Map<String, dynamic>?,
    );
  }

  /// The ID of the surface.
  final String surfaceId;

  /// The ID of the root component.
  final String root;

  /// The styles for the UI.
  final Map<String, dynamic>? styles;
}

/// A message that contains a list of components to update.
class SurfaceUpdate implements A2uiStreamMessage {
  /// Creates a [SurfaceUpdate].
  const SurfaceUpdate({required this.surfaceId, required this.components});

  /// Creates a [SurfaceUpdate] from a JSON object.
  factory SurfaceUpdate.fromJson(Map<String, dynamic> json) {
    return SurfaceUpdate(
      surfaceId: json['surfaceId'] as String,
      components: (json['components'] as List<dynamic>)
          .map((e) => Component.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The ID of the surface.
  final String surfaceId;

  /// The list of components to update.
  final List<Component> components;
}

/// A message that contains a data model update.
class DataModelUpdate implements A2uiStreamMessage {
  /// Creates a [DataModelUpdate].
  const DataModelUpdate({
    required this.surfaceId,
    this.path,
    required this.contents,
  });

  /// Creates a [DataModelUpdate] from a JSON object.
  factory DataModelUpdate.fromJson(Map<String, dynamic> json) {
    return DataModelUpdate(
      surfaceId: json['surfaceId'] as String,
      path: json['path'] as String?,
      contents: json['contents'],
    );
  }

  /// The ID of the surface.
  final String surfaceId;

  /// The path to the data to update.
  final String? path;

  /// The new contents of the data.
  final dynamic contents;
}

/// A message that signals the client to delete a surface.
class SurfaceDeletion implements A2uiStreamMessage {
  /// Creates a [SurfaceDeletion].
  const SurfaceDeletion({required this.surfaceId});

  /// Creates a [SurfaceDeletion] from a JSON object.
  factory SurfaceDeletion.fromJson(Map<String, dynamic> json) {
    return SurfaceDeletion(surfaceId: json['surfaceId'] as String);
  }

  /// The ID of the surface to delete.
  final String surfaceId;
}
