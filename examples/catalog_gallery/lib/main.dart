// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/flutter_genui_dev.dart';

void main() {
  runApp(CatalogGalleryApp(CoreCatalogItems.asCatalog()));
}

class CatalogGalleryApp extends StatelessWidget {
  const CatalogGalleryApp(this.catalog, {super.key});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Catalog items that has "exampleData" field set'),
        ),
        body: CatalogView(catalog: catalog),
      ),
    );
  }
}
