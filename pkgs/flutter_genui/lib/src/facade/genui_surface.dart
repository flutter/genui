// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/surface_controller.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It reports user interactions via the [onEvent] callback.
class GenUiSurface extends StatefulWidget {
  /// Creates a new [GenUiSurface].
  const GenUiSurface({
    super.key,
    required this.controller,
    this.defaultBuilder,
  });

  /// The controller that holds the state of the UI.
  final SurfaceController controller;

  /// A builder for the widget to display when the surface has no definition.
  final WidgetBuilder? defaultBuilder;

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  /// Dispatches an event by calling the public [GenUiSurface.onEvent]
  /// callback.
  void _dispatchEvent(UiEvent event) {
    // The event comes in without a surfaceId, which we add here.
    final eventMap = event.toMap();
    eventMap['surfaceId'] =
        widget.controller.definitionNotifier.value?.surfaceId;
    final callback = widget.controller.onEvent;
    if (callback != null) {
      callback(UiEvent.fromMap(eventMap));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: widget.controller.definitionNotifier,
      builder: (context, definition, child) {
        genUiLogger.info(
          'Building surface ${widget.controller.definitionNotifier.value?.surfaceId}',
        );
        if (definition == null) {
          genUiLogger.info(
            'Surface ${widget.controller.definitionNotifier.value?.surfaceId} has no definition.',
          );
          return widget.defaultBuilder?.call(context) ??
              const SizedBox.shrink();
        }
        final rootId = definition.root;
        if (definition.widgets.isEmpty) {
          genUiLogger.warning(
            'Surface ${widget.controller.definitionNotifier.value?.surfaceId} has no widgets.',
          );
          return const SizedBox.shrink();
        }
        return _buildWidget(definition, rootId);
      },
    );
  }

  /// The main recursive build function.
  /// It reads a widget definition and its current state from
  /// `widget.definition`
  /// and constructs the corresponding Flutter widget.
  Widget _buildWidget(UiDefinition definition, String widgetId) {
    var data = definition.widgets[widgetId];
    if (data == null) {
      genUiLogger.severe('Widget with id: $widgetId not found.');
      return Placeholder(child: Text('Widget with id: $widgetId not found.'));
    }

    return widget.controller.catalog.buildWidget(
      data as Map<String, Object?>,
      (String childId) => _buildWidget(definition, childId),
      _dispatchEvent,
      context,
    );
  }
}
