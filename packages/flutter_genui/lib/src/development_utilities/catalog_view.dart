// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show StreamSubscription;
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../core/genui_manager.dart';
import '../core/genui_surface.dart';
import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';
import '../primitives/simple_items.dart';

/// A widget that displays a GenUI catalog widgets.
///
/// This widget is intended for development and debugging purposes.
///
/// In order for a catalog item to be displayed, it must have example data
/// defined.
class DebugCatalogView extends StatefulWidget {
  const DebugCatalogView({
    super.key,
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

    for (final item in widget.catalog.items) {
      for (var i = 0; i < item.exampleData.length; i++) {
        final exampleBuilder = item.exampleData[i];
        final indexPart = item.exampleData.length > 1 ? '-$i' : '';
        final surfaceId = '${item.name}$indexPart';

        final exampleJsonString = exampleBuilder();
        final exampleData = jsonDecode(exampleJsonString) as List<Object?>;

        final components = exampleData
            .map((e) => Component.fromJson(e as JsonMap))
            .toList();

        Component? rootComponent;
        rootComponent = components.firstWhereOrNull((c) => c.id == 'root');

        if (rootComponent == null) {
          debugPrint(
            'Skipping example for ${item.name} because it is missing a root '
            'component.',
          );
          continue;
        }

        _genUi.handleMessage(
          SurfaceUpdate(surfaceId: surfaceId, components: components),
        );
        _genUi.handleMessage(
          BeginRendering(surfaceId: surfaceId, root: rootComponent.id),
        );
        surfaceIds.add(surfaceId);
      }
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
