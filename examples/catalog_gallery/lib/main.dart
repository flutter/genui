// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

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
    final Directory defaultSamples = fs.directory('${current.path}/samples');
    if (defaultSamples.existsSync()) {
      samplesDir = defaultSamples;
    }
  }

  configureGenUiLogging(level: Level.ALL);

  runApp(CatalogGalleryApp(samplesDir: samplesDir, fs: fs));
}

class CatalogGalleryApp extends StatefulWidget {
  final Directory? samplesDir;
  final FileSystem fs;

  const CatalogGalleryApp({
    super.key,
    this.samplesDir,
    this.fs = const LocalFileSystem(),
  });

  @override
  State<CatalogGalleryApp> createState() => _CatalogGalleryAppState();
}

class _CatalogGalleryAppState extends State<CatalogGalleryApp> {
  final Catalog catalog = Catalog([
    CoreCatalogItems.audioPlayer,
    CoreCatalogItems.button,
    CoreCatalogItems.card,
    CoreCatalogItems.checkBox,
    CoreCatalogItems.column,
    CoreCatalogItems.dateTimeInput,
    CoreCatalogItems.divider,
    CoreCatalogItems.icon,
    CoreCatalogItems.image,
    CoreCatalogItems.list,
    CoreCatalogItems.modal,
    CoreCatalogItems.choicePicker,
    CoreCatalogItems.row,
    CoreCatalogItems.slider,
    CoreCatalogItems.tabs,
    CoreCatalogItems.text,
    CoreCatalogItems.textField,
    CoreCatalogItems.video,
  ], catalogId: 'default');

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
                SamplesView(
                  samplesDir: widget.samplesDir!,
                  catalog: catalog,
                  fs: widget.fs,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
