// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import 'genui_configuration.dart';

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
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId);

  /// The catalog of UI components available to the AI.
  Catalog get catalog;

  /// A map of data models for storing the UI state of each surface.
  Map<String, DataModel> get dataModels;

  /// The data model for storing the UI state for a given surface.
  DataModel dataModelForSurface(String surfaceId);

  /// A callback to handle an action from a surface.
  void handleUiEvent(UiEvent event);
}

/// Manages the state of all dynamic UI surfaces.
///
/// This class is the core state manager for the dynamic UI. It maintains a map
/// of all active UI "surfaces", where each surface is represented by a
/// `UiDefinition`. It provides the tools (`surfaceUpdate`, `deleteSurface`,
/// `beginRendering`) that the AI uses to manipulate the UI. It exposes a stream
/// of `GenUiUpdate` events so that the application can react to changes.
class GenUiManager implements GenUiHost {
  /// Creates a new [GenUiManager].
  ///
  /// The [catalog] defines the set of widgets available to the AI.
  GenUiManager({
    required this.catalog,
    this.configuration = const GenUiConfiguration(),
  });

  final GenUiConfiguration configuration;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _surfaceUpdates = StreamController<GenUiUpdate>.broadcast();
  final _onSubmit = StreamController<UserUiInteractionMessage>.broadcast();

  final _dataModels = <String, DataModel>{};

  @override
  Map<String, DataModel> get dataModels => Map.unmodifiable(_dataModels);

  @override
  DataModel dataModelForSurface(String surfaceId) {
    return _dataModels.putIfAbsent(surfaceId, DataModel.new);
  }

  /// A map of all the surfaces managed by this manager, keyed by surface ID.
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _surfaceUpdates.stream;

  /// A stream of user input messages generated from UI interactions.
  Stream<UserUiInteractionMessage> get onSubmit => _onSubmit.stream;

  @override
  void handleUiEvent(UiEvent event) {
    if (event is! UserActionEvent) {
      // Or handle other event types if necessary
      return;
    }

    final String eventJsonString = jsonEncode({'userAction': event.toMap()});
    _onSubmit.add(UserUiInteractionMessage.text(eventJsonString));
  }

  @override
  final Catalog catalog;

  @override
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId) {
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

  /// Disposes of the resources used by this manager.
  void dispose() {
    _surfaceUpdates.close();
    _onSubmit.close();
    for (final ValueNotifier<UiDefinition?> notifier in _surfaces.values) {
      notifier.dispose();
    }
  }

  /// Handles an [A2uiMessage] and updates the UI accordingly.
  void handleMessage(A2uiMessage message) {
    switch (message) {
      case SurfaceUpdate():
        // No need for SurfaceAdded here because A2uiMessage will never generate
        // those. We decide here if the surface is new or not, and generate a
        // SurfaceAdded event if so.
        final String surfaceId = message.surfaceId;
        final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(
          surfaceId,
        );
        final isNew = notifier.value == null;
        UiDefinition uiDefinition =
            notifier.value ?? UiDefinition(surfaceId: surfaceId);
        final Map<String, Component> newComponents = Map.of(
          uiDefinition.components,
        );
        for (final Component component in message.components) {
          newComponents[component.id] = component;
        }
        uiDefinition = uiDefinition.copyWith(components: newComponents);
        notifier.value = uiDefinition;
        if (isNew) {
          genUiLogger.info('Adding surface $surfaceId');
          _surfaceUpdates.add(SurfaceAdded(surfaceId, uiDefinition));
        } else {
          genUiLogger.info('Updating surface $surfaceId');
          _surfaceUpdates.add(SurfaceUpdated(surfaceId, uiDefinition));
        }
      case BeginRendering():
        dataModelForSurface(message.surfaceId);
        final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(
          message.surfaceId,
        );
        final UiDefinition uiDefinition =
            notifier.value ?? UiDefinition(surfaceId: message.surfaceId);
        final UiDefinition newUiDefinition = uiDefinition.copyWith(
          rootComponentId: message.root,
        );
        notifier.value = newUiDefinition;
        genUiLogger.info('Started rendering ${message.surfaceId}');
        _surfaceUpdates.add(SurfaceUpdated(message.surfaceId, newUiDefinition));
      case DataModelUpdate():
        final String path = message.path ?? '/';
        genUiLogger.info(
          'Updating data model for surface ${message.surfaceId} at path '
          '$path with contents:\n'
          '${const JsonEncoder.withIndent('  ').convert(message.contents)}',
        );
        final DataModel dataModel = dataModelForSurface(message.surfaceId);
        dataModel.update(DataPath(path), message.contents);
      case SurfaceDeletion():
        final String surfaceId = message.surfaceId;
        if (_surfaces.containsKey(surfaceId)) {
          genUiLogger.info('Deleting surface $surfaceId');
          final ValueNotifier<UiDefinition?>? notifier = _surfaces.remove(
            surfaceId,
          );
          notifier?.dispose();
          _dataModels.remove(surfaceId);
          _surfaceUpdates.add(SurfaceRemoved(surfaceId));
        }
    }
  }
}
