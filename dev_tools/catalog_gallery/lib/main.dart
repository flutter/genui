// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'sample_source.dart';
import 'samples_view.dart';

void main(List<String> args) {
  SampleSource sampleSource = const AssetSampleSource();

  // The `--samples <dir>` override loads samples from the local filesystem and
  // is therefore desktop/mobile only. On web we never touch `dart:io` and
  // always use the bundled assets.
  if (!kIsWeb) {
    final parser = ArgParser()
      ..addOption('samples', abbr: 's', help: 'Path to the samples directory');
    final ArgResults results = parser.parse(args);
    if (results.wasParsed('samples')) {
      const FileSystem fs = LocalFileSystem();
      sampleSource = DirectorySampleSource(
        fs.directory(results['samples'] as String),
      );
    }
  }

  runApp(CatalogGalleryApp(sampleSource: sampleSource));
}

class CatalogGalleryApp extends StatefulWidget {
  const CatalogGalleryApp({
    super.key,
    this.sampleSource = const AssetSampleSource(),
    this.splashFactory,
  });

  final SampleSource sampleSource;
  final InteractiveInkFeatureFactory? splashFactory;

  @override
  State<CatalogGalleryApp> createState() => _CatalogGalleryAppState();
}

class _CatalogGalleryAppState extends State<CatalogGalleryApp> {
  final Catalog catalog = BasicCatalogItems.asCatalog();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        splashFactory: widget.splashFactory,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        splashFactory: widget.splashFactory,
      ),
      home: Builder(
        builder: (context) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                title: Text(
                  'Catalog Gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                bottom: TabBar(
                  labelColor: Theme.of(context).colorScheme.onSecondary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSecondary.withValues(alpha: 0.5),
                  tabs: const [
                    Tab(text: 'Catalog'),
                    Tab(text: 'Samples'),
                  ],
                ),
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
                  SamplesView(
                    sampleSource: widget.sampleSource,
                    catalog: catalog,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
