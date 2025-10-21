// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Configuration for the actions that can be performed by the GenUI.
@immutable
class ActionsConfig {
  /// Creates a new [ActionsConfig].
  const ActionsConfig({
    this.allowCreate = true,
    this.allowUpdate = true,
    this.allowDelete = true,
  });

  /// Creates a new [ActionsConfig] that only allows creating new surfaces.
  const ActionsConfig.createOnly()
    : this(allowUpdate: false, allowDelete: false);

  /// Whether to allow creating new surfaces.
  final bool allowCreate;

  /// Whether to allow updating existing surfaces.
  final bool allowUpdate;

  /// Whether to allow deleting existing surfaces.
  final bool allowDelete;
}

/// Configuration for the GenUI.
@immutable
class GenUiConfiguration {
  /// Creates a new [GenUiConfiguration].
  const GenUiConfiguration({this.actions = const ActionsConfig.createOnly()});

  /// The configuration for the actions that can be performed by the GenUI.
  final ActionsConfig actions;
}
