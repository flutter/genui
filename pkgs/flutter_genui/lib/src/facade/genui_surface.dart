// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/surface_controller.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It reports user interactions via the [onEvent] callback.
class GenUiSurface extends StatelessWidget {
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

  void _dispatchEvent(UiEvent event) {
    final onEvent = controller.onEvent;
    if (onEvent == null) {
      return;
    }
    // The event comes in without a surfaceId, which we add here.
    final eventMap = event.toMap();
    eventMap['surfaceId'] = controller.surfaceId;
    onEvent(UiEvent.fromMap(eventMap));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: controller.definitionNotifier,
      builder: (context, definition, child) {
        genUiLogger.info('Building surface ${controller.surfaceId}');
        if (definition == null) {
          genUiLogger
              .info('Surface ${controller.surfaceId} has no definition.');
          return defaultBuilder?.call(context) ?? const SizedBox.shrink();
        }
        final rootId = definition.root;
        if (definition.widgets.isEmpty) {
          genUiLogger.warning('Surface ${controller.surfaceId} has no widgets.');
          return const SizedBox.shrink();
        }
        return _buildWidget(definition, rootId, context);
      },
    );
  }

  /// The main recursive build function.
  /// It reads a widget definition and its current state from
  /// `widget.definition`
  /// and constructs the corresponding Flutter widget.
  Widget _buildWidget(
    UiDefinition definition,
    String widgetId,
    BuildContext context,
  ) {
    var data = definition.widgets[widgetId];
    if (data == null) {
      genUiLogger.severe('Widget with id: $widgetId not found.');
      return Placeholder(child: Text('Widget with id: $widgetId not found.'));
    }

    return controller.catalog.buildWidget(
      data as JsonMap,
      (String childId) => _buildWidget(definition, childId, context),
      _dispatchEvent,
      context,
    );
  }
}