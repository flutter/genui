// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';

/// An interface for a message sink that accepts [A2uiMessage]s.
abstract interface class A2uiMessageSink {
  /// Handles a message from the client.
  void handleMessage(A2uiMessage message);
}

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

/// An interface for a specific UI surface context.
///
/// This provides access to the state and definition of a single surface.
abstract interface class GenUiContext {
  /// The ID of the surface this context is bound to.
  String get surfaceId;

  /// The current definition of the UI for this surface.
  ValueListenable<UiDefinition?> get definition;

  /// The data model for this surface.
  DataModel get dataModel;

  /// The catalogs available to this surface.
  Iterable<Catalog> get catalogs;

  /// Handles a UI event from this surface.
  void handleUiEvent(UiEvent event);
}
