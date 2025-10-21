// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart';

import '../core/genui_manager.dart';
import '../core/genui_surface.dart';
import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../model/chat_message.dart';
import '../primitives/simple_items.dart';

/// A widget that displays a GenUI catalog widgets.
///
/// This widget is intended for development and debugging purposes.
///
/// In order for a catalog item to be displayed, it must have example data
/// defined.
class DebugCatalogView extends StatefulWidget {
  const DebugCatalogView({
    this.onSubmit,
    required this.catalog,
    this.itemHeight,
  });

  final Catalog catalog;
  final ValueChanged<UserMessage>? onSubmit;

  /// If provided, constrains each item to the given height.
  final double? itemHeight;

  @override
  State<DebugCatalogView> createState() => _DebugCatalogViewState();
}

class _DebugCatalogViewState extends State<DebugCatalogView> {
  late final GenUiManager _genUi;
  final surfaceIds = <String>[];
  late final StreamSubscription<UserMessage>? _subscription;

  @override
  void initState() {
    super.initState();

    _genUi = GenUiManager(catalog: widget.catalog);
    if (widget.onSubmit != null) {
      _subscription = _genUi.onSubmit.listen(widget.onSubmit);
    } else {
      _subscription = null;
    }

    final examples = <String, ExampleBuilderCallback>{};

    for (final item in widget.catalog.items) {
      for (var d = 0; d < item.exampleData.length; d++) {
        final indexPart = item.exampleData.length > 1 ? '-$d' : '';
        examples['${item.name}$indexPart'] = item.exampleData[d];
      }
    }

    for (final item in examples.entries) {
      final surfaceId = item.key;
      final definition = item.value();
      final widgets = definition['widgets'] as List<Object?>;
      final components = widgets
          .map((e) {
            final widget = e as JsonMap;
            final widgetMap = widget['widget'] as JsonMap?;
            if (widgetMap != null) {
              return Component(
                id: widget['id'] as String,
                componentProperties: widgetMap,
              );
            }
            // Handle the other format.
            final type = widget['type'] as String?;
            if (type == null) {
              return null;
            }
            final properties = Map<String, Object?>.from(widget);
            properties.remove('id');
            properties.remove('type');
            return Component(
              id: widget['id'] as String,
              componentProperties: {type: properties},
            );
          })
          .whereType<Component>()
          .toList();
      _genUi.handleMessage(
        SurfaceUpdate(surfaceId: surfaceId, components: components),
      );
      _genUi.handleMessage(
        BeginRendering(
          surfaceId: surfaceId,
          root: definition['root'] as String,
        ),
      );
      surfaceIds.add(surfaceId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _genUi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: surfaceIds.length,
      itemBuilder: (BuildContext context, int index) {
        final surfaceId = surfaceIds[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '$surfaceId:',
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
            SizedBox(
              height: widget.itemHeight,
              child: GenUiSurface(host: _genUi, surfaceId: surfaceId),
            ),
          ],
        );
      },
    );
  }
}
