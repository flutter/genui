// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../genui.dart' show GenUiContext;

import '../model/ui_models.dart';
import 'gen_ui_context.dart';

/// An interface for a host that manages UI surfaces.
///
/// This host provides updates when surfaces are added, removed, or changed.
/// It also acts as a factory for [GenUiContext]s, which provide access to the
/// state of minimal, individual surfaces.
abstract interface class GenUiHost {
  /// A stream of updates for the surfaces managed by this host.
  ///
  /// Implementations may choose to filter redundant updates. Consumers should
  /// reply on [contextFor] to get the context for a specific surface.
  Stream<GenUiUpdate> get surfaceUpdates;

  /// Returns a [GenUiContext] for the surface with the given [surfaceId].
  GenUiContext contextFor(String surfaceId);
}
