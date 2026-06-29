// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'sample_parser.dart';
import 'sample_source.dart';

class SamplesView extends StatefulWidget {
  const SamplesView({
    super.key,
    required this.sampleSource,
    required this.catalog,
  });

  final SampleSource sampleSource;
  final Catalog catalog;

  @override
  State<SamplesView> createState() => _SamplesViewState();
}

class _SamplesViewState extends State<SamplesView> {
  List<SampleRef> _samples = [];
  SampleRef? _selectedRef;
  Sample? _selectedSample;
  late SurfaceController _surfaceController;
  final List<String> _surfaceIds = [];
  int _currentSurfaceIndex = 0;
  StreamSubscription<SurfaceUpdate>? _surfaceSubscription;
  StreamSubscription<core.A2uiMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _surfaceController = SurfaceController(catalogs: [widget.catalog]);
    _loadSamples();
    _setupSurfaceListener();
  }

  @override
  void dispose() {
    _surfaceSubscription?.cancel();
    _messageSubscription?.cancel();
    _surfaceController.dispose();
    super.dispose();
  }

  void _setupSurfaceListener() {
    _surfaceSubscription = _surfaceController.surfaceUpdates.listen((update) {
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
    final List<SampleRef> samples = await widget.sampleSource.listSamples();
    if (!mounted) return;
    setState(() {
      _samples = samples;
    });
  }

  Future<void> _selectSample(SampleRef ref) async {
    await _messageSubscription?.cancel();
    // Reset surfaces
    setState(() {
      _surfaceIds.clear();
      _currentSurfaceIndex = 0;
    });
    // Re-create SurfaceController to ensure a clean state for the new
    // sample.
    _surfaceController.dispose();
    _surfaceController = SurfaceController(catalogs: [widget.catalog]);
    _setupSurfaceListener();

    try {
      genUiLogger.info('Displaying sample ${ref.name}');
      final String content = await ref.load();
      final Sample sample = SampleParser.parseString(content);
      if (!mounted) return;
      setState(() {
        _selectedRef = ref;
        _selectedSample = sample;
      });

      _messageSubscription = sample.messages.listen(
        _surfaceController.handleMessage,
        onError: (Object e) {
          genUiLogger.severe('Error processing message: $e');
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing sample: $e')),
          );
        },
      );
    } catch (exception, stackTrace) {
      genUiLogger.severe(
        'Error parsing sample ${ref.name}: $exception\n$stackTrace',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing sample: $exception')),
      );
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
                  itemCount: _samples.length,
                  itemBuilder: (context, index) {
                    final SampleRef ref = _samples[index];

                    return ListTile(
                      title: Text(ref.name),
                      selected: _selectedRef?.name == ref.name,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      onTap: () => _selectSample(ref),
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
                          : SingleChildScrollView(
                              child: Surface(
                                key: ValueKey(
                                  _surfaceIds[_currentSurfaceIndex],
                                ),
                                surfaceContext: _surfaceController.contextFor(
                                  _surfaceIds[_currentSurfaceIndex],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
