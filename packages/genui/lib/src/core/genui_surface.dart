// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../core/genui_manager.dart';
import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../model/data_model.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/constants.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

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
    genUiLogger.fine('Outer Building surface ${widget.surfaceId}');
    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: widget.host.getSurfaceNotifier(widget.surfaceId),
      builder: (context, definition, child) {
        genUiLogger.fine('Building surface ${widget.surfaceId}');
        if (definition == null) {
          genUiLogger.info('Surface ${widget.surfaceId} has no definition.');
          return widget.defaultBuilder?.call(context) ??
              const SizedBox.shrink();
        }
        final String? rootId = definition.rootComponentId;
        if (rootId == null || definition.components.isEmpty) {
          genUiLogger.warning('Surface ${widget.surfaceId} has no widgets.');
          return const SizedBox.shrink();
        }

        final Catalog? catalog = _findCatalogForDefinition(definition);
        if (catalog == null) {
          return Container();
        }

        return _buildWidget(
          definition,
          catalog,
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
    Catalog catalog,
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
    return catalog.buildWidget(
      CatalogItemContext(
        id: widgetId,
        data: widgetData,
        buildChild: (String childId, [DataContext? childDataContext]) =>
            _buildWidget(
              definition,
              catalog,
              childId,
              childDataContext ?? dataContext,
            ),
        dispatchEvent: _dispatchEvent,
        buildContext: context,
        dataContext: dataContext,
        getComponent: (String componentId) =>
            definition.components[componentId],
        surfaceId: widget.surfaceId,
      ),
    );
  }

  void _dispatchEvent(UiEvent event) {
    if (event is UserActionEvent && event.name == 'showModal') {
      final UiDefinition? definition = widget.host
          .getSurfaceNotifier(widget.surfaceId)
          .value;
      if (definition == null) return;

      final Catalog? catalog = _findCatalogForDefinition(definition);
      if (catalog == null) {
        genUiLogger.severe(
          'Cannot show modal for surface "${widget.surfaceId}" because '
          'a catalog was not found.',
        );
        return;
      }

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
          catalog,
          contentChildId,
          DataContext(widget.host.dataModelForSurface(widget.surfaceId), '/'),
        ),
      );
      return;
    }

    // The event comes in without a surfaceId, which we add here.
    final Map<String, Object?> eventMap = {
      ...event.toMap(),
      surfaceIdKey: widget.surfaceId,
    };
    final UiEvent newEvent = event is UserActionEvent
        ? UserActionEvent.fromMap(eventMap)
        : UiEvent.fromMap(eventMap);
    widget.host.handleUiEvent(newEvent);
  }

  Catalog? _findCatalogForDefinition(UiDefinition definition) {
    final String catalogId = definition.catalogId ?? standardCatalogId;
    final Catalog? catalog = widget.host.catalogs.firstWhereOrNull(
      (c) => c.catalogId == catalogId,
    );

    if (catalog == null) {
      genUiLogger.severe(
        'Catalog with id "$catalogId" not found for surface '
        '"${widget.surfaceId}". Ensure the catalog is provided to '
        'GenUiManager.',
      );
    }
    return catalog;
  }
}
