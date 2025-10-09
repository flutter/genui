// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'component.dart';

/// A sealed class for all messages in the A2UI Streaming UI Protocol.
sealed class A2uiStreamMessage {
  /// Creates a [A2uiStreamMessage] from a JSON object.
  factory A2uiStreamMessage.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('streamHeader')) {
      return StreamHeader.fromJson(
        json['streamHeader'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('beginRendering')) {
      return BeginRendering.fromJson(
        json['beginRendering'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('componentUpdate')) {
      return ComponentUpdate.fromJson(
        json['componentUpdate'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('dataModelUpdate')) {
      return DataModelUpdate.fromJson(
        json['dataModelUpdate'] as Map<String, dynamic>,
      );
    }
    throw Exception('Unknown message type in JSON: $json');
  }
}

/// A message that contains the version of the protocol.
class StreamHeader implements A2uiStreamMessage {
  /// Creates a [StreamHeader].
  const StreamHeader({required this.version});

  /// Creates a [StreamHeader] from a JSON object.
  factory StreamHeader.fromJson(Map<String, dynamic> json) {
    return StreamHeader(version: json['version'] as String);
  }

  /// The version of the protocol.
  final String version;
}

/// A message that signals the client to begin rendering the UI.
class BeginRendering implements A2uiStreamMessage {
  /// Creates a [BeginRendering].
  const BeginRendering({required this.root, this.styles});

  /// Creates a [BeginRendering] from a JSON object.
  factory BeginRendering.fromJson(Map<String, dynamic> json) {
    return BeginRendering(
      root: json['root'] as String,
      styles: json['styles'] as Map<String, dynamic>?,
    );
  }

  /// The ID of the root component.
  final String root;

  /// The styles for the UI.
  final Map<String, dynamic>? styles;
}

/// A message that contains a list of components to update.
class ComponentUpdate implements A2uiStreamMessage {
  /// Creates a [ComponentUpdate].
  const ComponentUpdate({required this.components});

  /// Creates a [ComponentUpdate] from a JSON object.
  factory ComponentUpdate.fromJson(Map<String, dynamic> json) {
    return ComponentUpdate(
      components: (json['components'] as List<dynamic>)
          .map((e) => Component.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The list of components to update.
  final List<Component> components;
}

/// A message that contains a data model update.
class DataModelUpdate implements A2uiStreamMessage {
  /// Creates a [DataModelUpdate].
  const DataModelUpdate({this.path, required this.contents});

  /// Creates a [DataModelUpdate] from a JSON object.
  factory DataModelUpdate.fromJson(Map<String, dynamic> json) {
    return DataModelUpdate(
      path: json['path'] as String?,
      contents: json['contents'],
    );
  }

  /// The path to the data to update.
  final String? path;

  /// The new contents of the data.
  final dynamic contents;
}
