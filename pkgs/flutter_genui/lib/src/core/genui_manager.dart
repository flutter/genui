// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import 'core_catalog.dart';
import 'ui_tools.dart';
import 'surface_controller.dart';

/// A sealed class representing an update to the UI managed by [GenUiManager].
///
/// This class has three subclasses: [SurfaceAdded], [SurfaceUpdated], and
/// [SurfaceRemoved].
sealed class GenUiUpdate {
  /// Creates a [GenUiUpdate] for the given [surfaceId].
  const GenUiUpdate();
}

/// Fired when a new surface is created.
class SurfaceAdded extends GenUiUpdate {
  /// Creates a [SurfaceAdded] event for the given [surfaceId] and
  /// [definition].
  const SurfaceAdded(this.controller);

  /// The definition of the new surface.
  final SurfaceController controller;
}

/// Fired when a surface is deleted.
class SurfaceRemoved extends GenUiUpdate {
  /// Creates a [SurfaceRemoved] event for the given [surfaceId].
  const SurfaceRemoved(this.surfaceId);

  /// The ID of the surface that was updated.
  final String surfaceId;
}

class GenUiManager {
  GenUiManager({Catalog? catalog}) : catalog = catalog ?? coreCatalog;

  final Catalog catalog;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _controllers = <String, SurfaceController>{};
  final _updates = StreamController<GenUiUpdate>.broadcast();

  Stream<GenUiUpdate> get updates => _updates.stream;

  /// Returns a list of [AiTool]s that can be used to manipulate the UI.
  ///
  /// These tools should be provided to the [AiClient] to allow the AI to
  /// generate and modify the UI.
  List<AiTool> getTools() {
    return [AddOrUpdateSurfaceTool(this), DeleteSurfaceTool(this)];
  }

  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _surfaces.putIfAbsent(surfaceId, () => ValueNotifier(null));
  }

  void dispose() {
    _updates.close();
    for (final notifier in _surfaces.values) {
      notifier.dispose();
    }
  }

  void addOrUpdateSurface(String surfaceId, Map<String, Object?> definition) {
    final uiDefinition = UiDefinition.fromMap({
      'surfaceId': surfaceId,
      ...definition,
    });

    final notifier = _surfaces.putIfAbsent(
      surfaceId,
      () => ValueNotifier(null),
    );
    final isNew = notifier.value == null;
    notifier.value = uiDefinition;
    if (isNew) {
      final controller = SurfaceController(
        catalog: catalog,
        definitionNotifier: notifier,
      );
      _controllers[surfaceId] = controller;

      _updates.add(SurfaceAdded(controller));
    }
  }

  void deleteSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final notifier = _surfaces.remove(surfaceId);
      notifier?.dispose();
      _updates.add(SurfaceRemoved(surfaceId));
    }
  }
}
