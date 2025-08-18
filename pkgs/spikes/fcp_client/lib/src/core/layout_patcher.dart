// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_patch/json_patch.dart';

import '../models/models.dart';

/// A service that applies layout updates to a map of [LayoutNode]s.
class LayoutPatcher {
  /// Applies a [LayoutUpdate] payload to the given [nodeMap].
  ///
  /// The operations are applied sequentially using the JSON Patch (RFC 6902)
  /// standard.
  void apply(Map<String, LayoutNode> nodeMap, LayoutUpdate update) {
    final layoutJson = {
      'nodes': nodeMap.map((k, v) => MapEntry(k, v.toJson())),
    };
    final patchedJson = JsonPatch.apply(
      layoutJson,
      update.patches,
      strict: true,
    );
    final patchedNodes = (patchedJson['nodes'] as Map<String, Object?>).map(
      (k, v) => MapEntry(k, LayoutNode.fromMap(v as Map<String, Object?>)),
    );
    nodeMap
      ..clear()
      ..addAll(patchedNodes);
  }
}
