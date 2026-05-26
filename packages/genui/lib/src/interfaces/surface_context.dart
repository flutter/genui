// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter/foundation.dart';

import '../model/catalog.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';

/// An interface for a specific UI surface context.
///
/// This provides access to the source-compatible surface snapshot and data
/// model facade for a single surface.
abstract interface class SurfaceContext {
  /// The ID of the surface this context is bound to.
  String get surfaceId;

  /// The current snapshot definition of the UI for this surface.
  ValueListenable<SurfaceDefinition?> get definition;

  /// The data model for this surface.
  DataModel get dataModel;

  /// The catalog this surface is bound to.
  Catalog? get catalog;

  /// Handles a UI event from this surface.
  void handleUiEvent(UiEvent event);

  /// Reports an error capable of being sent back to the AI.
  void reportError(Object error, StackTrace? stack);
}

/// Internal live-surface extension used by GenUI's own controller/widget pair.
///
/// External/custom [SurfaceContext] implementations only need the legacy
/// [SurfaceContext.definition] API; when this live interface is available the
/// renderer can subscribe to per-component core updates for granular rebuilds.
@internal
abstract interface class LiveSurfaceContext implements SurfaceContext {
  /// The live core surface model for this surface.
  ValueListenable<core.SurfaceModel?> get surface;
}
