// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_patch/json_patch.dart';

import '../models/models.dart';
import 'fcp_state.dart';

/// A service that applies state updates to the [FcpState].
class StatePatcher {
  /// Applies a [StateUpdate] payload to the given [state].
  ///
  /// The patches are applied using the JSON Patch (RFC 6902) standard.
  /// If the patch operation is successful, the [FcpState] will be updated
  /// and notify its listeners.
  void apply(FcpState state, StateUpdate update) {
    final result = JsonPatch.apply(state.state, update.patches, strict: true);

    // The json_patch package returns a new map. We need to update the state
    // with this new map to trigger the change notification.
    state.state = result as Map<String, Object?>;
  }
}
