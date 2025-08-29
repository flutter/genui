// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/catalog.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import 'core_catalog.dart';
import 'genui_configuration.dart';

/// A sealed class representing an update to the UI managed by [SurfaceManager].
///
/// This class has three subclasses: [SurfaceAdded], [SurfaceUpdated], and
/// [SurfaceRemoved].
sealed class GenUiUpdate {
  /// Creates a [GenUiUpdate] for the given [surfaceId].
  const GenUiUpdate(this.surfaceId);

  /// The ID of the surface that was updated.
  final String surfaceId;
}

/// Fired when a new surface is created.
class SurfaceAdded extends GenUiUpdate {
  /// Creates a [SurfaceAdded] event for the given [surfaceId] and
  /// [definition].
  const SurfaceAdded(super.surfaceId, this.definition);

  /// The definition of the new surface.
  final UiDefinition definition;
}

/// Fired when an existing surface is modified.
class SurfaceUpdated extends GenUiUpdate {
  /// Creates a [SurfaceUpdated] event for the given [surfaceId] and
  /// [definition].
  const SurfaceUpdated(super.surfaceId, this.definition);

  /// The new definition of the surface.
  final UiDefinition definition;
}

/// Fired when a surface is deleted.
class SurfaceRemoved extends GenUiUpdate {
  /// Creates a [SurfaceRemoved] event for the given [surfaceId].
  const SurfaceRemoved(super.surfaceId);
}

/// Manages a collection of UI surfaces that can be updated dynamically.
class SurfaceManager {
  /// Creates a [SurfaceManager].
  ///
  /// A [catalog] of UI components can be provided, otherwise the
  /// [coreCatalog] will be used.
  SurfaceManager({Catalog? catalog, required this.configuration})
      : catalog = catalog ?? coreCatalog;

  /// The catalog of UI components that can be used to build the UI.
  final Catalog catalog;

  /// The configuration of the Gen UI system.
  final GenUiConfiguration configuration;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _updates = StreamController<GenUiUpdate>.broadcast();

  /// A map of surface IDs to their [ValueNotifier]s.
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  /// A stream of [GenUiUpdate]s that are fired when the UI is updated.
  Stream<GenUiUpdate> get updates => _updates.stream;

  /// Returns a [ValueNotifier] for the surface with the given [surfaceId].
  ///
  /// If a notifier for the given [surfaceId] does not exist, a new one is
  /// created.
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _surfaces.putIfAbsent(surfaceId, () => ValueNotifier(null));
  }

  /// Disposes of all the [ValueNotifier]s and closes the stream.
  void dispose() {
    for (final notifier in _surfaces.values) {
      notifier.dispose();
    }
    _updates.close();
  }

  /// Adds a new surface or updates an existing one.
  ///
  /// If a surface with the given [surfaceId] does not exist, a new one is
  /// created with the given [definition]. Otherwise, the existing surface is
  /// updated with the new [definition].
  void addOrUpdateSurface(String surfaceId, Map<String, Object?> definition) {
    final uiDefinition = UiDefinition.fromMap({
      'surfaceId': surfaceId,
      ...definition,
    });
    final notifier = surface(surfaceId); // Gets or creates the notifier.
    final isNew = notifier.value == null;
    notifier.value = uiDefinition;
    if (isNew) {
      genUiLogger.info('Adding surface $surfaceId');
      _updates.add(SurfaceAdded(surfaceId, uiDefinition));
    } else {
      genUiLogger.info('Updating surface $surfaceId');
      _updates.add(SurfaceUpdated(surfaceId, uiDefinition));
    }
  }

  /// Deletes the surface with the given [surfaceId].
  void deleteSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final notifier = _surfaces.remove(surfaceId);
      notifier?.dispose();
      _updates.add(SurfaceRemoved(surfaceId));
    }
  }
}