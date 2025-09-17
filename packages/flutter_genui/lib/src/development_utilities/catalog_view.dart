// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart';

import '../core/genui_manager.dart';
import '../core/genui_surface.dart';
import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../model/chat_message.dart';

/// A widget that displays a catalog of items using GenUI surfaces.
///
/// In order for a catalog item to be displayed, it must have example data
/// defined.
class CatalogView extends StatefulWidget {
  const CatalogView({this.onSubmit, required this.catalog});

  final Catalog catalog;
  final ValueChanged<UserMessage>? onSubmit;

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
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
      _genUi.addOrUpdateSurface(surfaceId, item.value());
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
        return ListTile(
          title: Text(
            '$surfaceId:',
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          subtitle: GenUiSurface(host: _genUi, surfaceId: surfaceId),
        );
      },
    );
  }
}
