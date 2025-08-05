import 'package:flutter/material.dart';

import 'catalog.dart';
import 'ui_models.dart';

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It takes an initial [definition] and reports user interactions
/// via the [onEvent] callback.
class SurfaceWidget extends StatefulWidget {
  const SurfaceWidget({
    super.key,
    required this.catalog,
    required this.surfaceId,
    required this.definition,
    required this.onEvent,
  });

  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// The initial UI structure.
  final UiDefinition definition;

  /// A callback for when a user interacts with a widget.
  final void Function(Map<String, Object?> event) onEvent;

  final Catalog catalog;

  @override
  State<SurfaceWidget> createState() => _SurfaceWidgetState();
}

class _SurfaceWidgetState extends State<SurfaceWidget> {
  /// Dispatches an event by calling the public [SurfaceWidget.onEvent]
  /// callback.
  void _dispatchEvent({
    required String widgetId,
    required String eventType,
    required Object? value,
  }) {
    final event = UiEvent(
      surfaceId: widget.surfaceId,
      widgetId: widgetId,
      eventType: eventType,
      value: value,
      timestamp: DateTime.now().toUtc(),
    );
    widget.onEvent(event.toMap());
  }

  @override
  Widget build(BuildContext context) {
    final rootId = widget.definition.root;
    if (widget.definition.widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildWidget(rootId);
  }

  /// The main recursive build function.
  /// It reads a widget definition and its current state from
  /// `widget.definition`
  /// and constructs the corresponding Flutter widget.
  Widget _buildWidget(String widgetId) {
    var data = widget.definition.widgets[widgetId];
    if (data == null) {
      // TODO: Handle missing widget gracefully.
      return Text('Widget with id: $widgetId not found.');
    }

    return widget.catalog.buildWidget(
      data as Map<String, Object?>,
      _buildWidget,
      _dispatchEvent,
      context,
    );
  }
}
