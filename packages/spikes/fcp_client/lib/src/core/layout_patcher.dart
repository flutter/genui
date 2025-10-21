// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// A service that applies layout updates to a map of [LayoutNode]s.
class LayoutPatcher {
  /// Applies a [LayoutUpdate] payload to the given [nodeMap].
  ///
  /// The operations (`add`, `remove`, `replace`) are applied sequentially.
  void apply(Map<String, LayoutNode> nodeMap, LayoutUpdate update) {
    for (final operation in update.operations) {
      switch (operation.op) {
        case 'add':
          _handleAdd(nodeMap, operation);
          break;
        case 'remove':
          _handleRemove(nodeMap, operation);
          break;
        case 'replace':
          _handleReplace(nodeMap, operation);
          break;
        default:
          // In a real-world scenario, you might want to log this.
          debugPrint(
            'FCP Warning: Ignoring unknown layout operation "${operation.op}".',
          );
          break;
      }
    }
  }

  void _handleAdd(Map<String, LayoutNode> nodeMap, LayoutOperation operation) {
    final nodes = operation.nodes;
    if (nodes == null || nodes.isEmpty) {
      return;
    }

    for (final node in nodes) {
      nodeMap[node.id] = node;
    }

    final targetNodeId = operation.targetNodeId;
    final targetProperty = operation.targetProperty;

    if (targetNodeId == null || targetProperty == null) {
      return;
    }

    final targetNode = nodeMap[targetNodeId];
    if (targetNode == null) {
      debugPrint(
        'FCP Warning: Target node "$targetNodeId" not found for "add" '
        'operation.',
      );
      return;
    }

    final newNodeIds = nodes.map((n) => n.id).toList();
    final currentProperties = Map<String, Object?>.from(
      targetNode.properties ?? {},
    );
    final currentChildren = currentProperties[targetProperty];

    final List<String> newChildrenIds;
    if (currentChildren is List) {
      newChildrenIds = [...currentChildren.cast<String>(), ...newNodeIds];
    } else if (currentChildren is String) {
      newChildrenIds = [currentChildren, ...newNodeIds];
    } else {
      newChildrenIds = newNodeIds;
    }

    currentProperties[targetProperty] = newChildrenIds;

    final newTargetNode = LayoutNode(
      id: targetNode.id,
      type: targetNode.type,
      properties: currentProperties,
      bindings: targetNode.bindings,
      itemTemplate: targetNode.itemTemplate,
    );

    nodeMap[targetNodeId] = newTargetNode;
  }

  void _handleRemove(
    Map<String, LayoutNode> nodeMap,
    LayoutOperation operation,
  ) {
    final ids = operation.nodeIds;
    if (ids == null || ids.isEmpty) {
      return;
    }

    for (final id in ids) {
      nodeMap.remove(id);
    }
  }

  void _handleReplace(
    Map<String, LayoutNode> nodeMap,
    LayoutOperation operation,
  ) {
    final nodes = operation.nodes;
    if (nodes == null || nodes.isEmpty) {
      return;
    }

    for (final node in nodes) {
      if (nodeMap.containsKey(node.id)) {
        nodeMap[node.id] = node;
      }
    }
  }
}
