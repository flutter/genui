// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:genui/genui.dart';

/// Renders surfaces through the experimental node layer (`NodeSurface`)
/// instead of `Surface`. Enable with `--dart-define=nodes=true`.
const bool _useNodeLayer = bool.fromEnvironment('nodes');

class Message {
  Message({this.text, this.surfaceId, this.isUser = false})
    : assert((surfaceId == null) != (text == null));

  String? text;
  final String? surfaceId;
  final bool isUser;
}

class MessageView extends StatelessWidget {
  const MessageView(this.message, this.host, {super.key});

  final Message message;

  /// The surface host used to render generative UI surfaces. Required only
  /// when [Message.surfaceId] is non-null.
  final SurfaceHost? host;

  @override
  Widget build(BuildContext context) {
    final String? surfaceId = message.surfaceId;

    if (surfaceId == null) {
      if (message.isUser) {
        return Text(message.text ?? '');
      } else {
        return MarkdownBody(data: message.text ?? '');
      }
    }

    assert(
      host != null,
      'A SurfaceHost is required to render surface $surfaceId',
    );
    final SurfaceHost surfaceHost = host!;
    if (_useNodeLayer && surfaceHost is SurfaceController) {
      return _NodeLayerMessageSurface(
        controller: surfaceHost,
        surfaceId: surfaceId,
      );
    }
    return Surface(surfaceContext: surfaceHost.contextFor(surfaceId));
  }
}

/// Renders a surface through [NodeSurface] once its core model exists,
/// watching the definition snapshot only to learn about creation.
class _NodeLayerMessageSurface extends StatelessWidget {
  const _NodeLayerMessageSurface({
    required this.controller,
    required this.surfaceId,
  });

  final SurfaceController controller;
  final String surfaceId;

  @override
  Widget build(BuildContext context) {
    final SurfaceContext surfaceContext = controller.contextFor(surfaceId);
    return ValueListenableBuilder<SurfaceDefinition?>(
      valueListenable: surfaceContext.definition,
      builder: (context, definition, _) {
        final core.SurfaceModel<core.ComponentApi>? surface = controller
            .liveSurfaceFor(surfaceId);
        final Catalog? catalog = surfaceContext.catalog;
        if (definition == null || surface == null || catalog == null) {
          return const SizedBox.shrink();
        }
        return NodeSurface(
          surface: surface,
          catalog: catalog,
          onEvent: surfaceContext.handleUiEvent,
          reportError: surfaceContext.reportError,
        );
      },
    );
  }
}
