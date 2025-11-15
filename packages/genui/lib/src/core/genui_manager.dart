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
import 'surface_controller.dart';

/// A sealed class representing an update to the UI managed by [GenUiManager].
///
/// This class has two subclasses: [SurfaceAdded] and [SurfaceRemoved].
sealed class GenUiUpdate {
  /// Creates a [GenUiUpdate] for the given [surfaceId].
  const GenUiUpdate(this.controller);

  /// The controller for the surface that was updated.
  final SurfaceController controller;
}

/// Fired when a new surface is created.
class SurfaceAdded extends GenUiUpdate {
  /// Creates a [SurfaceAdded] event for the given [controller].
  const SurfaceAdded(super.controller);
}

/// Fired when a surface is deleted.
class SurfaceRemoved extends GenUiUpdate {
  /// Creates a [SurfaceRemoved] event for the given [controller].
  const SurfaceRemoved(super.controller);
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
/// `SurfaceController`. It provides the tools (`surfaceUpdate`, `deleteSurface`,
/// `beginRendering`) that the AI uses to manipulate the UI. It exposes a stream
/// of `GenUiUpdate` events so that the application can react to changes.
class GenUiManager {
  /// Creates a new [GenUiManager].
  ///
  /// The [catalog] defines the set of widgets available to the AI.
  GenUiManager({
    required this.catalog,
    this.configuration = const GenUiConfiguration(),
  });

  final GenUiConfiguration configuration;

  final _surfaceControllers = <String, SurfaceController>{};
  final _surfaceUpdates = StreamController<GenUiUpdate>.broadcast();
  final _onSubmit = StreamController<UserUiInteractionMessage>.broadcast();

  /// A stream of updates for the surfaces managed by this manager.
  Stream<GenUiUpdate> get surfaceUpdates => _surfaceUpdates.stream;

  /// A stream of user input messages generated from UI interactions.
  Stream<UserUiInteractionMessage> get onSubmit => _onSubmit.stream;

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// Returns the [SurfaceController] for the given [surfaceId].
  ///
  /// If a controller for the given [surfaceId] does not exist, a new one is
  /// created and a [SurfaceAdded] event is fired on the [surfaceUpdates]
  /// stream.
  SurfaceController getSurfaceController(String surfaceId) {
    if (!_surfaceControllers.containsKey(surfaceId)) {
      genUiLogger.fine('Creating new surface controller for $surfaceId');
      final newController = SurfaceController(
        surfaceId: surfaceId,
        catalog: catalog,
        onUiEvent: handleUiEvent,
      );
      _surfaceControllers[surfaceId] = newController;
      _surfaceUpdates.add(SurfaceAdded(newController));
      return newController;
    }
    return _surfaceControllers[surfaceId]!;
  }

  /// Disposes of the resources used by this manager.
  void dispose() {
    _surfaceUpdates.close();
    _onSubmit.close();
    for (final SurfaceController controller in _surfaceControllers.values) {
      controller.dispose();
    }
  }

  /// Handles an [A2uiMessage] and updates the UI accordingly.
  void handleMessage(A2uiMessage message) {
    switch (message) {
      case SurfaceUpdate():
        final SurfaceController controller = getSurfaceController(
          message.surfaceId,
        );
        controller.handleMessage(message);
      case BeginRendering():
        final SurfaceController controller = getSurfaceController(
          message.surfaceId,
        );
        controller.handleMessage(message);
      case DataModelUpdate():
        final SurfaceController controller = getSurfaceController(
          message.surfaceId,
        );
        controller.handleMessage(message);
      case SurfaceDeletion():
        final String surfaceId = message.surfaceId;
        if (_surfaceControllers.containsKey(surfaceId)) {
          genUiLogger.info('Deleting surface $surfaceId');
          final SurfaceController controller = _surfaceControllers.remove(
            surfaceId,
          )!;
          _surfaceUpdates.add(SurfaceRemoved(controller));
          controller.dispose();
        }
    }
  }

  /// A callback to handle an action from a surface.
  void handleUiEvent(UiEvent event) {
    if (event is! UserActionEvent) {
      // Or handle other event types if necessary
      return;
    }

    final String eventJsonString = jsonEncode({'userAction': event.toMap()});
    _onSubmit.add(UserUiInteractionMessage.text(eventJsonString));
  }
}
