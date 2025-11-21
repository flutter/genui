// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'samples_view.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('samples', abbr: 's', help: 'Path to the samples directory');
  final ArgResults results = parser.parse(args);

  Directory? samplesDir;
  if (results.wasParsed('samples')) {
    samplesDir = Directory(results['samples'] as String);
  } else {
    final Directory current = Directory.current;
    final defaultSamples = Directory('${current.path}/samples');
    if (defaultSamples.existsSync()) {
      samplesDir = defaultSamples;
    }
  }

  runApp(CatalogGalleryApp(samplesDir: samplesDir));
}

class CatalogGalleryApp extends StatefulWidget {
  final Directory? samplesDir;

  const CatalogGalleryApp({super.key, this.samplesDir});

  @override
  State<CatalogGalleryApp> createState() => _CatalogGalleryAppState();
}

class _CatalogGalleryAppState extends State<CatalogGalleryApp> {
  final Catalog catalog = CoreCatalogItems.asCatalog();

  @override
  Widget build(BuildContext context) {
    final bool showSamples =
        widget.samplesDir != null && widget.samplesDir!.existsSync();

    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: DefaultTabController(
        length: showSamples ? 2 : 1,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Catalog Gallery'),
            bottom: showSamples
                ? const TabBar(
                    tabs: [
                      Tab(text: 'Catalog'),
                      Tab(text: 'Samples'),
                    ],
                  )
                : null,
          ),
          body: TabBarView(
            children: [
              DebugCatalogView(
                catalog: catalog,
                onSubmit: (message) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'User action: '
                        '${jsonEncode(message.parts.last)}',
                      ),
                    ),
                  );
                },
              ),
              if (showSamples)
                SamplesView(samplesDir: widget.samplesDir!, catalog: catalog),
            ],
          ),
        ),
      ),
    );
  }
}
