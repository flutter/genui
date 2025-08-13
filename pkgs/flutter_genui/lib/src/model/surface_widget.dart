// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/genui_manager.dart';
import 'catalog.dart';
import 'chat_message.dart';
import 'ui_models.dart';

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It takes an initial [definition] and reports user interactions
/// via the [onEvent] callback.
class SurfaceWidget extends StatefulWidget {
  const SurfaceWidget({super.key, required this.response, required this.host});

  final UiResponseMessage response;
  final SurfaceHost host;

  @override
  State<SurfaceWidget> createState() => _SurfaceWidgetState();
}

class _SurfaceWidgetState extends State<SurfaceWidget> {
  late final String _surfaceId;
  late final UiDefinition _definition;
  late final void Function(Map<String, Object?> event) _onEvent;
  late final Catalog _catalog;

  @override
  void initState() {
    super.initState();
    _surfaceId = widget.response.surfaceId;
    _definition = UiDefinition.fromMap(widget.response.definition);
    _onEvent = widget.host.sendEvent;
    _catalog = widget.host.catalog;
  }

  /// Dispatches an event by calling the public [SurfaceWidget.onEvent]
  /// callback.
  void _dispatchEvent(UiEvent event) {
    // The event comes in without a surfaceId, which we add here.
    final eventMap = event.toMap();
    eventMap['surfaceId'] = _surfaceId;
    _onEvent(eventMap);
  }

  @override
  Widget build(BuildContext context) {
    final rootId = _definition.root;
    if (_definition.widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildWidget(rootId);
  }

  /// The main recursive build function.
  /// It reads a widget definition and its current state from
  /// `widget.definition`
  /// and constructs the corresponding Flutter widget.
  Widget _buildWidget(String widgetId) {
    var data = _definition.widgets[widgetId];
    if (data == null) {
      // TODO: Handle missing widget gracefully.
      return Text('Widget with id: $widgetId not found.');
    }

    return _catalog.buildWidget(
      data as Map<String, Object?>,
      _buildWidget,
      _dispatchEvent,
      context,
    );
  }
}
