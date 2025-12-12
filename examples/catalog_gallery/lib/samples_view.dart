// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'sample_parser.dart';

class SamplesView extends StatefulWidget {
  const SamplesView({
    super.key,
    required this.samplesDir,
    required this.catalog,
    this.fs = const LocalFileSystem(),
  });

  final Directory samplesDir;
  final Catalog catalog;
  final FileSystem fs;

  @override
  State<SamplesView> createState() => _SamplesViewState();
}

class _SamplesViewState extends State<SamplesView> {
  List<File> _sampleFiles = [];
  File? _selectedFile;
  Sample? _selectedSample;
  late A2uiMessageProcessor _a2uiMessageProcessor;
  final List<String> _surfaceIds = [];
  int _currentSurfaceIndex = 0;
  StreamSubscription<GenUiUpdate>? _surfaceSubscription;
  StreamSubscription<A2uiMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [widget.catalog]);
    _loadSamples();
    _setupSurfaceListener();
  }

  @override
  void dispose() {
    _surfaceSubscription?.cancel();
    _messageSubscription?.cancel();
    _a2uiMessageProcessor.dispose();
    super.dispose();
  }

  void _setupSurfaceListener() {
    _surfaceSubscription = _a2uiMessageProcessor.surfaceUpdates.listen((
      update,
    ) {
      if (update is SurfaceAdded) {
        if (!_surfaceIds.contains(update.surfaceId)) {
          setState(() {
            _surfaceIds.add(update.surfaceId);
            // If this is the first surface, select it.
            if (_surfaceIds.length == 1) {
              _currentSurfaceIndex = 0;
            }
          });
        }
      } else if (update is SurfaceRemoved) {
        if (_surfaceIds.contains(update.surfaceId)) {
          setState(() {
            final int removeIndex = _surfaceIds.indexOf(update.surfaceId);
            _surfaceIds.removeAt(removeIndex);
            if (_surfaceIds.isEmpty) {
              _currentSurfaceIndex = 0;
            } else {
              if (_currentSurfaceIndex >= removeIndex &&
                  _currentSurfaceIndex > 0) {
                _currentSurfaceIndex--;
              }
              if (_currentSurfaceIndex >= _surfaceIds.length) {
                _currentSurfaceIndex = _surfaceIds.length - 1;
              }
            }
          });
        }
      }
    });
  }

  Future<void> _loadSamples() async {
    if (!widget.samplesDir.existsSync()) {
      return;
    }
    final List<File> files = (await widget.samplesDir.list().toList())
        .whereType<File>()
        .where((file) => file.path.endsWith('.sample'))
        .toList();
    setState(() {
      _sampleFiles = files;
    });
  }

  Future<void> _selectSample(File file) async {
    await _messageSubscription?.cancel();
    // Reset surfaces
    setState(() {
      _surfaceIds.clear();
      _currentSurfaceIndex = 0;
    });
    // Re-create A2uiMessageProcessor to ensure a clean state for the new
    // sample.
    _a2uiMessageProcessor.dispose();
    _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [widget.catalog]);
    _setupSurfaceListener();

    try {
      final Sample sample = await SampleParser.parseFile(file);
      setState(() {
        _selectedFile = file;
        _selectedSample = sample;
      });

      _messageSubscription = sample.messages.listen(
        _a2uiMessageProcessor.handleMessage,
        onError: (Object e) {
          debugPrint('Error processing message: $e');
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing sample: $e')),
          );
        },
      );
    } catch (e) {
      debugPrint('Error parsing sample: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error parsing sample: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left pane: Sample List
        SizedBox(
          width: 250,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _sampleFiles.length,
                  itemBuilder: (context, index) {
                    final File file = _sampleFiles[index];
                    final String fileName = widget.fs.path
                        .basenameWithoutExtension(file.path);

                    return ListTile(
                      title: Text(fileName),
                      selected: _selectedFile?.path == file.path,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      onTap: () => _selectSample(file),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right pane: Canvas / Surfaces
        Expanded(
          child: _selectedSample == null
              ? const Center(child: Text('Sample'))
              : Column(
                  children: [
                    // Surface Tabs
                    if (_surfaceIds.isNotEmpty)
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _surfaceIds.length,
                          itemBuilder: (context, index) {
                            final String id = _surfaceIds[index];
                            final isSelected = index == _currentSurfaceIndex;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _currentSurfaceIndex = index;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                alignment: Alignment.center,
                                child: Text(
                                  id,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const Divider(height: 1),
                    // Surface Content
                    Expanded(
                      child: _surfaceIds.isEmpty
                          ? const Center(child: Text('No surfaces'))
                          : GenUiSurface(
                              key: ValueKey(_surfaceIds[_currentSurfaceIndex]),
                              host: _a2uiMessageProcessor,
                              surfaceId: _surfaceIds[_currentSurfaceIndex],
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
