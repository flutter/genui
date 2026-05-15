// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'samples_view.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('samples', abbr: 's', help: 'Path to the samples directory');
  final ArgResults results = parser.parse(args);

  const FileSystem fs = LocalFileSystem();
  Directory? samplesDir;
  if (results.wasParsed('samples')) {
    samplesDir = fs.directory(results['samples'] as String);
  } else {
    final Directory current = fs.currentDirectory;
    final Directory defaultSamples = fs
        .directory(current.path)
        .childDirectory('samples');
    if (defaultSamples.existsSync()) {
      samplesDir = defaultSamples;
    }
  }

  runApp(CatalogGalleryApp(samplesDir: samplesDir, fs: fs));
}

class CatalogGalleryApp extends StatefulWidget {
  final Directory? samplesDir;
  final FileSystem fs;

  const CatalogGalleryApp({
    super.key,
    this.samplesDir,
    this.fs = const LocalFileSystem(),
    this.splashFactory,
  });

  final InteractiveInkFeatureFactory? splashFactory;

  @override
  State<CatalogGalleryApp> createState() => _CatalogGalleryAppState();
}

class _CatalogGalleryAppState extends State<CatalogGalleryApp> {
  final Catalog catalog = BasicCatalogItems.asCatalog();

  @override
  Widget build(BuildContext context) {
    final bool showSamples =
        widget.samplesDir != null && widget.samplesDir!.existsSync();

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
            length: showSamples ? 2 : 1,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                title: Text(
                  'Catalog Gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                bottom: showSamples
                    ? TabBar(
                        labelColor: Theme.of(context).colorScheme.onSecondary,
                        unselectedLabelColor: Theme.of(
                          context,
                        ).colorScheme.onSecondary.withValues(alpha: 0.5),
                        tabs: const [
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
                    SamplesView(
                      samplesDir: widget.samplesDir!,
                      catalog: catalog,
                      fs: widget.fs,
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
