// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../model/chat_message.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'core_catalog.dart';
import 'genui_configuration.dart';
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

/// An interface for a class that hosts UI surfaces.
///
/// This is used by `GenUiSurface` to get the UI definition for a surface,
/// listen for updates, and notify the host of user interactions.
abstract interface class GenUiHost {
  /// A stream of updates for the surfaces managed by this host.
  Stream<GenUiUpdate> get surfaceUpdates;

  /// Returns a [ValueNotifier] for the surface with the given [surfaceId].
  ValueNotifier<UiDefinition?> surface(String surfaceId);

  /// The catalog of UI components available to the AI.
  Catalog get catalog;

  /// The value store for storing the widget state.
  WidgetValueStore get valueStore;

  /// A callback to handle an action from a surface.
  void handleUiEvent(UiEvent event);
}

/// Manages the state of all dynamic UI surfaces.
///
/// This class is the core state manager for the dynamic UI. It maintains a map
/// of all active UI "surfaces", where each surface is represented by a
/// `UiDefinition`. It provides the tools (`addOrUpdateSurface`,
/// `deleteSurface`) that the AI uses to manipulate the UI. It exposes a stream
/// of `GenUiUpdate` events so that the application can react to changes.
class GenUiManager implements GenUiHost {
  /// Creates a new [GenUiManager].
  ///
  /// The [catalog] defines the set of widgets available to the AI.
  /// [CoreCatalogItems.asCatalog] can be called to construct a catalog of
  /// widgets that can power simple UIs.
  GenUiManager({
    required this.catalog,
    this.configuration = const GenUiConfiguration(),
  });

  final GenUiConfiguration configuration;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _surfaceUpdates = StreamController<GenUiUpdate>.broadcast();
  final _onSubmit = StreamController<UserMessage>.broadcast();

  @override
  final valueStore = WidgetValueStore();

  /// A map of all the surfaces managed by this manager, keyed by surface ID.
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _surfaceUpdates.stream;

  /// A stream of user input messages generated from UI interactions.
  Stream<UserMessage> get onSubmit => _onSubmit.stream;

  @override
  void handleUiEvent(UiEvent event) {
    if (event is! UiActionEvent) throw ArgumentError('Unexpected event type');
    final stateValue = valueStore.forSurface(event.surfaceId);
    final eventString =
        'Action: ${jsonEncode(event.value)}\n'
        'Current state: ${jsonEncode(stateValue)}';
    _onSubmit.add(UserMessage([TextPart(eventString)]));
  }

  @override
  final Catalog catalog;

  /// Returns a list of [AiTool]s that can be used to manipulate the UI.
  ///
  /// These tools should be provided to the [AiClient] to allow the AI to
  /// generate and modify the UI.
  List<AiTool> getTools() {
    return [
      if (configuration.actions.allowCreate ||
          configuration.actions.allowUpdate)
        AddOrUpdateSurfaceTool(
          onAddOrUpdate: addOrUpdateSurface,
          catalog: catalog,
          configuration: configuration,
        ),
      if (configuration.actions.allowDelete)
        DeleteSurfaceTool(onDelete: deleteSurface),
    ];
  }

  @override
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _surfaces.putIfAbsent(surfaceId, () => ValueNotifier(null));
  }

  /// Disposes of the resources used by this manager.
  void dispose() {
    _surfaceUpdates.close();
    _onSubmit.close();
    for (final notifier in _surfaces.values) {
      notifier.dispose();
    }
  }

  /// Adds or updates a surface with the given [surfaceId] and [definition].
  ///
  /// If a surface with the given ID does not exist, a new one is created.
  /// Otherwise, the existing surface is updated.
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
      _surfaceUpdates.add(SurfaceAdded(surfaceId, uiDefinition));
    } else {
      genUiLogger.info('Updating surface $surfaceId');
      _surfaceUpdates.add(SurfaceUpdated(surfaceId, uiDefinition));
    }
  }

  /// Deletes the surface with the given [surfaceId].
  void deleteSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final notifier = _surfaces.remove(surfaceId);
      notifier?.dispose();
      _surfaceUpdates.add(SurfaceRemoved(surfaceId));
    }
  }
}
