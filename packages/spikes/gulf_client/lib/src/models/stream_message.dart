// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'component.dart';

sealed class GulfStreamMessage {
  factory GulfStreamMessage.fromJson(Map<String, dynamic> json) {
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

class StreamHeader implements GulfStreamMessage {
  const StreamHeader({required this.version});

  factory StreamHeader.fromJson(Map<String, dynamic> json) {
    return StreamHeader(version: json['version'] as String);
  }

  final String version;
}

class BeginRendering implements GulfStreamMessage {
  const BeginRendering({required this.root, this.styles});

  factory BeginRendering.fromJson(Map<String, dynamic> json) {
    return BeginRendering(
      root: json['root'] as String,
      styles: json['styles'] as Map<String, dynamic>?,
    );
  }

  final String root;
  final Map<String, dynamic>? styles;
}

class ComponentUpdate implements GulfStreamMessage {
  const ComponentUpdate({required this.components});

  factory ComponentUpdate.fromJson(Map<String, dynamic> json) {
    return ComponentUpdate(
      components: (json['components'] as List<dynamic>)
          .map((e) => Component.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<Component> components;
}

class DataModelUpdate implements GulfStreamMessage {
  const DataModelUpdate({this.path, required this.contents});

  factory DataModelUpdate.fromJson(Map<String, dynamic> json) {
    return DataModelUpdate(
      path: json['path'] as String?,
      contents: json['contents'],
    );
  }

  final String? path;
  final dynamic contents;
}
