// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';

/// A controller that manages the state of a single UI surface.
///
/// This class is responsible for maintaining the [UiDefinition] and [DataModel]
/// for a surface, and for handling messages and events related to that surface.
class SurfaceController {
  /// Creates a new [SurfaceController].
  SurfaceController({
    required this.surfaceId,
    required this.catalog,
    required this.onUiEvent,
  }) : _uiDefinitionNotifier = ValueNotifier(null);

  /// The unique ID of the surface that this controller manages.
  final String surfaceId;

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// A callback to handle a UI event from the surface.
  final ValueChanged<UiEvent> onUiEvent;

  final ValueNotifier<UiDefinition?> _uiDefinitionNotifier;

  /// A [ValueListenable] that provides the current [UiDefinition] for the
  /// surface.
  ValueListenable<UiDefinition?> get uiDefinitionNotifier =>
      _uiDefinitionNotifier;

  /// The data model for storing the UI state of the surface.
  final DataModel dataModel = DataModel();

  /// Disposes of the resources used by this controller.
  void dispose() {
    _uiDefinitionNotifier.dispose();
  }

  /// Handles an [A2uiMessage] and updates the UI accordingly.
  void handleMessage(A2uiMessage message) {
    if (message is SurfaceUpdate && message.surfaceId != surfaceId) {
      throw ArgumentError(
        'Mismatched surfaceId in message: '
        'expected $surfaceId, got ${message.surfaceId}',
      );
    }
    if (message is BeginRendering && message.surfaceId != surfaceId) {
      throw ArgumentError(
        'Mismatched surfaceId in message: '
        'expected $surfaceId, got ${message.surfaceId}',
      );
    }
    if (message is DataModelUpdate && message.surfaceId != surfaceId) {
      throw ArgumentError(
        'Mismatched surfaceId in message: '
        'expected $surfaceId, got ${message.surfaceId}',
      );
    }

    switch (message) {
      case SurfaceUpdate():
        UiDefinition uiDefinition =
            _uiDefinitionNotifier.value ?? UiDefinition(surfaceId: surfaceId);
        final Map<String, Component> newComponents = Map.of(
          uiDefinition.components,
        );
        for (final Component component in message.components) {
          newComponents[component.id] = component;
        }
        uiDefinition = uiDefinition.copyWith(components: newComponents);
        _uiDefinitionNotifier.value = uiDefinition;
      case BeginRendering():
        final UiDefinition uiDefinition =
            _uiDefinitionNotifier.value ?? UiDefinition(surfaceId: surfaceId);
        final UiDefinition newUiDefinition = uiDefinition.copyWith(
          rootComponentId: message.root,
        );
        _uiDefinitionNotifier.value = newUiDefinition;
      case DataModelUpdate():
        final String path = message.path ?? '/';
        genUiLogger.info(
          'Updating data model for surface $surfaceId at path '
          '$path with contents:\n'
          '${message.contents}',
        );
        dataModel.update(DataPath(path), message.contents);
      case SurfaceDeletion():
      // This is handled by the GenUiManager, which owns the lifecycle of
      // the SurfaceControllers.
    }
  }
}
