// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:travel_app/travel_app.dart' as travel_app;

void main() {
  runApp(const CatalogGalleryApp());
}

class CatalogGalleryApp extends StatelessWidget {
  const CatalogGalleryApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Map<String, Catalog> catalogs = {
    'core catalog': coreCatalog,
    'travel app catalog': travel_app.catalog,
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: catalogs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Catalog items that has "exampleData" field set'),
          bottom: TabBar(
            tabs: catalogs.keys.map((String key) => Tab(text: key)).toList(),
          ),
        ),
        body: TabBarView(
          children: catalogs.values
              .map((Catalog catalog) => CatalogView(catalog: catalog))
              .toList(),
        ),
      ),
    );
  }
}

class CatalogView extends StatelessWidget {
  const CatalogView({super.key, required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: catalog.items
          .where((CatalogItem item) => item.exampleData != null)
          .map(
            (CatalogItem item) => ListTile(
              title: Text(item.name),
              subtitle: item.widgetBuilder(
                context: context,
                data: item.exampleData!,
                id: item.name,
                buildChild: (String id) => const SizedBox.shrink(),
                dispatchEvent: (UiEvent event) {},
              ),
            ),
          )
          .toList(),
    );
  }
}
