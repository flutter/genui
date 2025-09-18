// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'component.dart';
import 'data_node.dart';

sealed class GulfStreamMessage {
  factory GulfStreamMessage.fromJson(Map<String, dynamic> json) {
    final type = json['messageType'];
    switch (type) {
      case 'StreamHeader':
        return StreamHeader.fromJson(json);
      case 'ComponentUpdate':
        return ComponentUpdate.fromJson(json);
      case 'DataModelUpdate':
        return DataModelUpdate.fromJson(json);
      case 'UIRoot':
        return UiRoot.fromJson(json);
      default:
        throw Exception('Unknown messageType: $type');
    }
  }

  Map<String, dynamic> toJson();
}

class StreamHeader implements GulfStreamMessage {
  const StreamHeader({required this.version});

  factory StreamHeader.fromJson(Map<String, dynamic> json) {
    return StreamHeader(version: json['version'] as String);
  }

  final String version;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'messageType': 'StreamHeader', 'version': version};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamHeader && other.version == version;
  }

  @override
  int get hashCode => version.hashCode;
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

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageType': 'ComponentUpdate',
      'components': components.map((c) => c.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComponentUpdate && listEquals(other.components, components);
  }

  @override
  int get hashCode => Object.hashAll(components);
}

class DataModelUpdate implements GulfStreamMessage {
  const DataModelUpdate({required this.nodes});

  factory DataModelUpdate.fromJson(Map<String, dynamic> json) {
    return DataModelUpdate(
      nodes: (json['nodes'] as List<dynamic>)
          .map((e) => DataModelNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<DataModelNode> nodes;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageType': 'DataModelUpdate',
      'nodes': nodes.map((n) => n.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataModelUpdate && listEquals(other.nodes, nodes);
  }

  @override
  int get hashCode => Object.hashAll(nodes);
}

class UiRoot implements GulfStreamMessage {
  const UiRoot({required this.root, required this.dataModelRoot});

  factory UiRoot.fromJson(Map<String, dynamic> json) {
    return UiRoot(
      root: json['root'] as String,
      dataModelRoot: json['dataModelRoot'] as String,
    );
  }

  final String root;
  final String dataModelRoot;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageType': 'UIRoot',
      'root': root,
      'dataModelRoot': dataModelRoot,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UiRoot &&
        other.root == root &&
        other.dataModelRoot == dataModelRoot;
  }

  @override
  int get hashCode => Object.hash(root, dataModelRoot);
}
