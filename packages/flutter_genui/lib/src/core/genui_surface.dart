// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../core/genui_manager.dart';

import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';

/// A callback for when a user interacts with a widget.
typedef UiEventCallback = void Function(UiEvent event);

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It reports user interactions via the [host].
class GenUiSurface extends StatefulWidget {
  /// Creates a new [GenUiSurface].
  const GenUiSurface({
    super.key,
    required this.host,
    required this.surfaceId,
    this.defaultBuilder,
  });

  /// The manager that holds the state of the UI.
  final GenUiHost host;

  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// A builder for the widget to display when the surface has no definition.
  final WidgetBuilder? defaultBuilder;

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: widget.host.surface(widget.surfaceId),
      builder: (context, definition, child) {
        genUiLogger.info('Building surface ${widget.surfaceId}');
        if (definition == null) {
          genUiLogger.info('Surface ${widget.surfaceId} has no definition.');
          return widget.defaultBuilder?.call(context) ??
              const SizedBox.shrink();
        }

        var rootId = definition.rootComponentId;

        if (rootId == null && definition.components.isNotEmpty) {
          genUiLogger.warning(
            'Surface ${widget.surfaceId} has no rootComponentId specified.',
          );
          // This should happen less after fix of
          // https://github.com/flutter/genui/issues/400
          // If there's only one component, use last as the root.
          rootId = definition.components.keys.last;
        }

        if (rootId == null) {
          genUiLogger.warning('Surface ${widget.surfaceId} has no components.');
          return const SizedBox.shrink();
        }

        return _buildWidget(
          definition,
          rootId,
          DataContext(widget.host.dataModelForSurface(widget.surfaceId), '/'),
        );
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
    DataContext dataContext,
  ) {
    var data = definition.components[widgetId];
    if (data == null) {
      genUiLogger.severe('Widget with id: $widgetId not found.');
      return Placeholder(child: Text('Widget with id: $widgetId not found.'));
    }

    final widgetData = data.componentProperties;

    return widget.host.catalog.buildWidget(
      id: widgetId,
      widgetData: widgetData,
      buildChild: (String childId) =>
          _buildWidget(definition, childId, dataContext),
      dispatchEvent: _dispatchEvent,
      context: context,
      dataContext: dataContext,
    );
  }

  void _dispatchEvent(UiEvent event) {
    if (event is UserActionEvent && event.name == 'showModal') {
      final definition = widget.host.surface(widget.surfaceId).value;
      if (definition == null) return;
      final modalId = event.context['modalId'] as String;
      final modalComponent = definition.components[modalId];
      if (modalComponent == null) return;
      final contentChildId =
          (modalComponent.componentProperties['Modal'] as Map)['contentChild']
              as String;
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => _buildWidget(
          definition,
          contentChildId,
          DataContext(widget.host.dataModelForSurface(widget.surfaceId), '/'),
        ),
      );
      return;
    }

    // The event comes in without a surfaceId, which we add here.
    final eventMap = {...event.toMap(), 'surfaceId': widget.surfaceId};
    final newEvent = event is UserActionEvent
        ? UserActionEvent.fromMap(eventMap)
        : UiEvent.fromMap(eventMap);
    widget.host.handleUiEvent(newEvent);
  }
}
