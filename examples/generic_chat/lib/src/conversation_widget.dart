import 'package:flutter/material.dart';

import 'ui_models.dart';
import 'catalog.dart';

class SurfaceData {
  final String surfaceId;
  final UiDefinition definition;

  SurfaceData({required this.surfaceId, required this.definition});
}

class ConversationWidget extends StatelessWidget {
  const ConversationWidget(
      {super.key,
      required this.surfaceData,
      required this.catalog,
      required this.onEvent});

  final List<SurfaceData> surfaceData;

  /// A callback for when a user interacts with a widget.
  final void Function(Map<String, Object?> event) onEvent;

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
