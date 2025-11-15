// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/surface_controller.dart';
import '../model/catalog_item.dart';
import '../model/data_model.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

/// A callback for when a user interacts with a widget.
typedef UiEventCallback = void Function(UiEvent event);

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It reports user interactions via the [controller].
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
  @override
  Widget build(BuildContext context) {
    genUiLogger.fine('Outer Building surface ${widget.controller.surfaceId}');
    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: widget.controller.uiDefinitionNotifier,
      builder: (context, definition, child) {
        genUiLogger.fine('Building surface ${widget.controller.surfaceId}');
        if (definition == null) {
          genUiLogger.info(
            'Surface ${widget.controller.surfaceId} has no definition.',
          );
          return widget.defaultBuilder?.call(context) ??
              const SizedBox.shrink();
        }
        final String? rootId = definition.rootComponentId;
        if (rootId == null || definition.components.isEmpty) {
          genUiLogger.warning(
            'Surface ${widget.controller.surfaceId} has no widgets.',
          );
          return const SizedBox.shrink();
        }
        return _buildWidget(
          definition,
          rootId,
          DataContext(widget.controller.dataModel, '/'),
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
    Component? data = definition.components[widgetId];
    if (data == null) {
      genUiLogger.severe('Widget with id: $widgetId not found.');
      return Placeholder(child: Text('Widget with id: $widgetId not found.'));
    }

    final JsonMap widgetData = data.componentProperties;
    genUiLogger.finest('Building widget $widgetId');
    return widget.controller.catalog.buildWidget(
      CatalogItemContext(
        id: widgetId,
        data: widgetData,
        buildChild: (String childId, [DataContext? childDataContext]) =>
            _buildWidget(definition, childId, childDataContext ?? dataContext),
        dispatchEvent: _dispatchEvent,
        buildContext: context,
        dataContext: dataContext,
        getComponent: (String componentId) =>
            definition.components[componentId],
        surfaceId: widget.controller.surfaceId,
      ),
    );
  }

  void _dispatchEvent(UiEvent event) {
    if (event is UserActionEvent && event.name == 'showModal') {
      final UiDefinition? definition =
          widget.controller.uiDefinitionNotifier.value;
      if (definition == null) return;
      final modalId = event.context['modalId'] as String;
      final Component? modalComponent = definition.components[modalId];
      if (modalComponent == null) return;
      final contentChildId =
          (modalComponent.componentProperties['Modal'] as Map)['contentChild']
              as String;
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => _buildWidget(
          definition,
          contentChildId,
          DataContext(widget.controller.dataModel, '/'),
        ),
      );
      return;
    }

    // The event comes in without a surfaceId, which we add here.
    final Map<String, Object?> eventMap = {
      ...event.toMap(),
      surfaceIdKey: widget.controller.surfaceId,
    };
    final UiEvent newEvent = event is UserActionEvent
        ? UserActionEvent.fromMap(eventMap)
        : UiEvent.fromMap(eventMap);
    widget.controller.onUiEvent(newEvent);
  }
}
