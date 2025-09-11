// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/genui_manager.dart';
import '../core/genui_surface.dart';
import '../model/catalog.dart';
import '../model/catalog_item.dart';

/// A widget that displays a catalog of items using GenUI surfaces.
///
/// In order for a catalog item to be displayed, it must have example data
/// defined.
class CatalogView extends StatefulWidget {
  const CatalogView({required this.catalog});

  final Catalog catalog;

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  late final GenUiManager _genUi;
  final surfaceIds = <String>[];

  @override
  void initState() {
    super.initState();

    _genUi = GenUiManager(catalog: widget.catalog);

    final items = widget.catalog.items.where(
      (CatalogItem item) => item.exampleData != null,
    );

    for (final item in items) {
      final data = item.exampleData!;
      final surfaceId = item.name;
      _genUi.addOrUpdateSurface(surfaceId, data);
      surfaceIds.add(surfaceId);
    }
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
