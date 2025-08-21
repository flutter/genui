// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/genui_manager.dart';
import '../core/logging.dart';
import 'ui_models.dart';

/// A callback for when a user interacts with a widget.
typedef UiEventCallback = void Function(UiEvent event);

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It reports user interactions via the [onEvent] callback.
class GenUiSurface extends StatefulWidget {
  /// Creates a new [GenUiSurface].
  const GenUiSurface({
    super.key,
    required this.manager,
    required this.surfaceId,
    required this.onEvent,
    this.defaultBuilder,
  });

  /// The manager that holds the state of the UI.
  final GenUiManager manager;

  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// A callback for when a user interacts with a widget.
  final UiEventCallback onEvent;

  /// A builder for the widget to display when the surface has no definition.
  final WidgetBuilder? defaultBuilder;

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  late final ValueNotifier<UiDefinition?> _definitionNotifier;

  @override
  void initState() {
    super.initState();
    _definitionNotifier = widget.manager.surface(widget.surfaceId);
  }

  /// Dispatches an event by calling the public [GenUiSurface.onEvent]
  /// callback.
  void _dispatchEvent(UiEvent event) {
    // The event comes in without a surfaceId, which we add here.
    final eventMap = event.toMap();
    eventMap['surfaceId'] = widget.surfaceId;
    widget.onEvent(UiEvent.fromMap(eventMap));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: _definitionNotifier,
      builder: (context, definition, child) {
        genUiLogger.info('Building surface ${widget.surfaceId}');
        if (definition == null) {
          genUiLogger.info('Surface ${widget.surfaceId} has no definition.');
          return widget.defaultBuilder?.call(context) ??
              const SizedBox.shrink();
        }
        final rootId = definition.root;
        if (definition.widgets.isEmpty) {
          genUiLogger.warning('Surface ${widget.surfaceId} has no widgets.');
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

    return widget.manager.catalog.buildWidget(
      data as Map<String, Object?>,
      (String childId) => _buildWidget(definition, childId),
      _dispatchEvent,
      context,
    );
  }
}
