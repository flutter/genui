import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// A service that applies layout updates to the UI.
class LayoutPatcher {
  /// Applies a [LayoutUpdate] payload to the given [nodeMap].
  ///
  /// The operations are applied sequentially.
  void apply(Map<String, LayoutNode> nodeMap, LayoutUpdate update) {
    for (final operation in update.operations) {
      switch (operation.op) {
        case 'add':
          _handleAdd(nodeMap, operation);
          break;
        case 'remove':
          _handleRemove(nodeMap, operation);
          break;
        case 'update':
          _handleUpdate(nodeMap, operation);
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

    // Note: The FCP spec implies that 'add' can also target a specific
    // property of a parent node (e.g., adding to a 'children' list).
    // The current implementation adds the node to the main map, but doesn't
    // modify the parent. This logic will be handled by the layout engine
    // when it rebuilds the tree.
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

  void _handleUpdate(
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
