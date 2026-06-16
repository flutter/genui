// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' hide Catalog, DataContext;
import 'package:flutter/foundation.dart';

import '../model/ui_models.dart' as genui_model;
import '../primitives/logging.dart';

/// Events emitted by the [SurfaceRegistry].
sealed class RegistryEvent {}

/// An event indicating that a new surface has been added.
class SurfaceAdded extends RegistryEvent {
  SurfaceAdded(this.surfaceId, this.surface);
  final String surfaceId;
  final SurfaceModel surface;
}

/// An event indicating that a surface has been removed.
class SurfaceRemoved extends RegistryEvent {
  SurfaceRemoved(this.surfaceId);
  final String surfaceId;
}

/// An event indicating that a surface's components were updated.
class SurfaceUpdated extends RegistryEvent {
  SurfaceUpdated(this.surfaceId, this.surface);
  final String surfaceId;
  final SurfaceModel surface;
}

/// Tracks live [SurfaceModel]s by surface ID and exposes Flutter-friendly
/// [ValueListenable]s for them, plus a registry-event stream.
class SurfaceRegistry {
  final Map<String, SurfaceModel> _surfaces = {};
  final Map<String, ValueNotifier<genui_model.SurfaceDefinition?>>
  _definitions = {};
  final List<String> _surfaceOrder = [];
  final StreamController<RegistryEvent> _eventController =
      StreamController.broadcast();

  /// The stream of registry events.
  Stream<RegistryEvent> get events => _eventController.stream;

  /// The list of surface IDs in the order they were created or updated.
  List<String> get surfaceOrder => List.unmodifiable(_surfaceOrder);

  /// Returns a [ValueListenable] tracking the
  /// [genui_model.SurfaceDefinition] snapshot for [surfaceId]. The value is
  /// `null` until the surface is registered, and becomes `null` again when
  /// it is removed.
  ValueListenable<genui_model.SurfaceDefinition?> watchSurface(
    String surfaceId,
  ) => watchDefinition(surfaceId);

  /// Returns a [ValueListenable] tracking the
  /// [genui_model.SurfaceDefinition] snapshot for [surfaceId].
  ValueListenable<genui_model.SurfaceDefinition?> watchDefinition(
    String surfaceId,
  ) {
    return _definitions.putIfAbsent(
      surfaceId,
      () => ValueNotifier<genui_model.SurfaceDefinition?>(null),
    );
  }

  /// Registers a new surface, emitting a [SurfaceAdded] event. Intended
  /// for GenUI internals; external callers should drive surface lifecycle
  /// through `SurfaceController.handleMessage`.
  @internal
  void addSurface(SurfaceModel surface) {
    _surfaces[surface.id] = surface;
    _definitions
        .putIfAbsent(
          surface.id,
          () => ValueNotifier<genui_model.SurfaceDefinition?>(null),
        )
        .value = genui_model.SurfaceDefinition.fromCore(
      surface,
    );
    _surfaceOrder
      ..remove(surface.id)
      ..add(surface.id);
    genUiLogger.info('Created new surface ${surface.id}');
    _eventController.add(SurfaceAdded(surface.id, surface));
  }

  /// Signals that the components of a surface have changed. Intended for
  /// GenUI internals.
  @internal
  void notifyUpdated(SurfaceModel surface) {
    _surfaceOrder
      ..remove(surface.id)
      ..add(surface.id);
    _definitions
        .putIfAbsent(
          surface.id,
          () => ValueNotifier<genui_model.SurfaceDefinition?>(null),
        )
        .value = genui_model.SurfaceDefinition.fromCore(
      surface,
    );
    _eventController.add(SurfaceUpdated(surface.id, surface));
  }

  /// Removes a surface from the registry, emitting a [SurfaceRemoved] event.
  ///
  /// The per-id definition [ValueNotifier] is intentionally retained (reset to
  /// `null`) so widgets already listening stay connected; a later re-create of
  /// the same id updates the existing notifier. The [SurfaceModel] is owned and
  /// disposed by the substrate's `core.SurfaceGroupModel`.
  void removeSurface(String surfaceId) {
    if (_surfaces.remove(surfaceId) == null) return;
    genUiLogger.info('Deleting surface $surfaceId');
    _definitions[surfaceId]?.value = null;
    _surfaceOrder.remove(surfaceId);
    _eventController.add(SurfaceRemoved(surfaceId));
  }

  /// Returns true if the registry has a live surface for [surfaceId].
  bool hasSurface(String surfaceId) => _surfaces.containsKey(surfaceId);

  /// Returns the current [genui_model.SurfaceDefinition] snapshot for the
  /// given [surfaceId], or `null` if the surface does not exist.
  genui_model.SurfaceDefinition? getSurface(String surfaceId) =>
      _definitions[surfaceId]?.value;

  /// Returns the live core surface model for [surfaceId], or `null` if the
  /// surface does not exist. Intended for GenUI internals.
  @internal
  SurfaceModel? getLiveSurface(String surfaceId) => _surfaces[surfaceId];

  /// Disposes of the registry and all per-surface notifiers. The underlying
  /// [SurfaceModel]s are owned and disposed by the substrate's
  /// `core.SurfaceGroupModel`, not by this registry.
  void dispose() {
    _eventController.close();
    for (final ValueNotifier<genui_model.SurfaceDefinition?> notifier
        in _definitions.values) {
      notifier.dispose();
    }
    _surfaces.clear();
    _definitions.clear();
    _surfaceOrder.clear();
  }
}
