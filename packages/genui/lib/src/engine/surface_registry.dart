// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/ui_models.dart';
import '../primitives/logging.dart';

/// Events emitted by the [SurfaceRegistry].
sealed class RegistryEvent {}

class SurfaceAdded extends RegistryEvent {
  SurfaceAdded(this.surfaceId, this.definition);
  final String surfaceId;
  final UiDefinition definition;
}

class SurfaceRemoved extends RegistryEvent {
  SurfaceRemoved(this.surfaceId);
  final String surfaceId;
}

class SurfaceUpdated extends RegistryEvent {
  SurfaceUpdated(this.surfaceId, this.definition);
  final String surfaceId;
  final UiDefinition definition;
}

/// Manages the lifecycle and storage of [UiDefinition]s.
class SurfaceRegistry {
  final Map<String, ValueNotifier<UiDefinition?>> _surfaces = {};
  // Track creation/update order for cleanup policies
  final List<String> _surfaceOrder = [];
  final StreamController<RegistryEvent> _eventController =
      StreamController.broadcast();

  Stream<RegistryEvent> get events => _eventController.stream;

  List<String> get surfaceOrder => List.unmodifiable(_surfaceOrder);

  ValueListenable<UiDefinition?> watchSurface(String surfaceId) {
    if (!_surfaces.containsKey(surfaceId)) {
      genUiLogger.fine('Adding new surface $surfaceId');
    } else {
      genUiLogger.fine('Fetching surface notifier for $surfaceId');
    }
    return _surfaces.putIfAbsent(
      surfaceId,
      () => ValueNotifier<UiDefinition?>(null),
    );
  }

  void updateSurface(
    String surfaceId,
    UiDefinition definition, {
    bool isNew = false,
  }) {
    final ValueNotifier<UiDefinition?> notifier = _surfaces.putIfAbsent(
      surfaceId,
      () => ValueNotifier(null),
    );
    notifier.value = definition;

    _surfaceOrder.remove(surfaceId);
    _surfaceOrder.add(surfaceId);

    if (isNew) {
      genUiLogger.info('Created new surface $surfaceId');
      _eventController.add(SurfaceAdded(surfaceId, definition));
    } else {
      // genUiLogger.info('Updated surface $surfaceId'); // Optional logging
      _eventController.add(SurfaceUpdated(surfaceId, definition));
    }
  }

  void removeSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final ValueNotifier<UiDefinition?>? notifier = _surfaces.remove(
        surfaceId,
      );
      notifier?.dispose();
      _surfaceOrder.remove(surfaceId);
      _eventController.add(SurfaceRemoved(surfaceId));
    }
  }

  bool hasSurface(String surfaceId) => _surfaces.containsKey(surfaceId);

  UiDefinition? getSurface(String surfaceId) => _surfaces[surfaceId]?.value;

  void dispose() {
    _eventController.close();
    for (final ValueNotifier<UiDefinition?> notifier in _surfaces.values) {
      notifier.dispose();
    }
  }
}
