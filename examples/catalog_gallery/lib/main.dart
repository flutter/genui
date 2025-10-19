// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

void main() {
  runApp(const CatalogGalleryApp());
}

class CatalogGalleryApp extends StatefulWidget {
  const CatalogGalleryApp({super.key});

  @override
  State<CatalogGalleryApp> createState() => _CatalogGalleryAppState();
}

class _CatalogGalleryAppState extends State<CatalogGalleryApp> {
  final catalog = CoreCatalogItems.asCatalog().copyWithout([
    // Excluded, because they are flexible:
    CoreCatalogItems.tabs,
    CoreCatalogItems.list,

    // Excluded, because something is wrong with image:
    // NetworkImageLoadException was thrown resolving an image codec...
    CoreCatalogItems.image,
  ]);

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
        body: DebugCatalogView(
          catalog: catalog,
          onSubmit: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User action: ${jsonEncode(message.parts.last)}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
