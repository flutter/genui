// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'chat_message.dart';
import 'ui_models.dart';

abstract class SurfaceHost {
  Catalog get catalog;
  void sendEvent(Map<String, Object?> event);
}

/// A widget that builds a UI surface dynamically from data returned by the LLM.
///
/// A surface is similar to a "turn" in a chat conversation.
class SurfaceWidget extends StatefulWidget {
  const SurfaceWidget({super.key, required this.response, required this.host});

  final UiResponseMessage response;
  final SurfaceHost host;

  @override
  State<SurfaceWidget> createState() => _SurfaceWidgetState();
}

class _SurfaceWidgetState extends State<SurfaceWidget> {
  late final UiDefinition _definition;

  @override
  void initState() {
    super.initState();
    _definition = UiDefinition.fromMap(widget.response.definition);
  }

  /// Dispatches an event by propagating it to the host.
  void _dispatchEvent(UiEvent event) {
    // The event comes in without a surfaceId, which we add here.
    final eventMap = event.toMap();
    eventMap['surfaceId'] = widget.response.surfaceId;
    widget.host.sendEvent(eventMap);
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

    return widget.host.catalog.buildWidget(
      data as Map<String, Object?>,
      _buildWidget,
      _dispatchEvent,
      context,
    );
  }
}
