// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'core_catalog.dart';
import 'ui_tools.dart';

/// A sealed class representing an update to the UI managed by [GenUiManager].
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

abstract interface class SurfaceBuilder {
  Stream<GenUiUpdate> get updates;
  ValueNotifier<UiDefinition?> surface(String surfaceId);
  Catalog get catalog;
  WidgetValueStore get valueStore;
}

class GenUiManager implements SurfaceBuilder {
  GenUiManager({Catalog? catalog}) : catalog = catalog ?? coreCatalog;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _updates = StreamController<GenUiUpdate>.broadcast();

  @override
  final valueStore = WidgetValueStore();

  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Stream<GenUiUpdate> get updates => _updates.stream;

  @override
  final Catalog catalog;

  /// Returns a list of [AiTool]s that can be used to manipulate the UI.
  ///
  /// These tools should be provided to the [AiClient] to allow the AI to
  /// generate and modify the UI.
  List<AiTool> getTools() {
    return [
      AddOrUpdateSurfaceTool(
        onAddOrUpdate: addOrUpdateSurface,
        catalog: catalog,
      ),
      DeleteSurfaceTool(onDelete: deleteSurface),
    ];
  }

  @override
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _surfaces.putIfAbsent(surfaceId, () => ValueNotifier(null));
  }

  void dispose() {
    _updates.close();
    for (final notifier in _surfaces.values) {
      notifier.dispose();
    }
  }

  void addOrUpdateSurface(String surfaceId, JsonMap definition) {
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

  void deleteSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final notifier = _surfaces.remove(surfaceId);
      notifier?.dispose();
      _updates.add(SurfaceRemoved(surfaceId));
    }
  }
}
