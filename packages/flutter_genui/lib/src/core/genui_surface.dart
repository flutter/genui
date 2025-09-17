// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/genui_manager.dart';

import '../model/ui_models.dart';
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
  ValueNotifier<UiDefinition?>? _definitionNotifier;
  StreamSubscription<GenUiUpdate>? _allUpdatesSubscription;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant GenUiSurface oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.surfaceId != widget.surfaceId ||
        oldWidget.host != widget.host) {
      _init();
    }
  }

  void _init() {
    // Reset previous subscription for updates.
    _allUpdatesSubscription?.cancel();
    _allUpdatesSubscription = widget.host.surfaceUpdates.listen((update) {
      if (update.surfaceId == widget.surfaceId) _init();
    });

    // Update definition if it is changed.
    final newDefinitionNotifier = widget.host.surface(widget.surfaceId);
    if (newDefinitionNotifier == _definitionNotifier) return;
    _definitionNotifier = newDefinitionNotifier;
    setState(() {});
  }

  /// Dispatches an event.
  void _dispatchEvent(UiEvent event) {
    // The event comes in without a surfaceId, which we add here.
    final eventMap = event.toMap();
    eventMap['surfaceId'] = widget.surfaceId;
    widget.host.handleUiEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = _definitionNotifier;
    if (notifier == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: notifier,
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

    return widget.host.catalog.buildWidget(
      data as JsonMap,
      (String childId) => _buildWidget(definition, childId),
      _dispatchEvent,
      context,
      widget.host.valueStore.forSurface(widget.surfaceId),
    );
  }

  @override
  void dispose() {
    _allUpdatesSubscription?.cancel();
    // We should not dispose _definitionNotifier,
    // because it is owned by the manager.
    super.dispose();
  }
}
