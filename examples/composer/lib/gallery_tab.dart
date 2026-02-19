// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'gallery_detail_dialog.dart';
import 'sample_parser.dart';

/// The Gallery tab displays a grid of pre-generated sample surfaces.
/// Cards show sample name and description. Clicking a card opens a dialog
/// that renders the live surface.
class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key, required this.onOpenInEditor});

  /// Called with the JSONL when the user clicks "Open in Surface Editor".
  final ValueChanged<String> onOpenInEditor;

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('GalleryTab');
  List<_GallerySampleMeta> _samples = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSampleMetadata();
  }

  /// Loads just the metadata (name, description) for each sample, without
  /// creating SurfaceControllers or rendering anything.
  Future<void> _loadSampleMetadata() async {
    try {
      final String manifestContent = await rootBundle.loadString(
        'samples/manifest.txt',
      );
      final List<String> filenames =
          manifestContent
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty && line.endsWith('.sample'))
              .toList()
            ..sort();

      final samples = <_GallerySampleMeta>[];

      for (final filename in filenames) {
        try {
          final String content = await rootBundle.loadString(
            'samples/$filename',
          );
          final Sample sample = SampleParser.parseString(content);
          samples.add(
            _GallerySampleMeta(
              name: sample.name,
              description: sample.description,
              rawContent: content,
              rawJsonl: sample.rawJsonl,
            ),
          );
        } catch (e) {
          _logger.warning('Skipping sample $filename: $e');
        }
      }

      if (mounted) {
        setState(() {
          _samples = samples;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading sample metadata', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Opens the detail dialog for a sample.
  /// Creates a SurfaceController on-demand and feeds messages to it.
  Future<void> _openSampleDetail(_GallerySampleMeta meta) async {
    final Catalog catalog = BasicCatalogItems.asCatalog();
    final controller = SurfaceController(catalogs: [catalog]);
    final List<String> surfaceIds = [];

    final sub = controller.surfaceUpdates.listen((update) {
      if (update is SurfaceAdded) {
        surfaceIds.add(update.surfaceId);
      }
    });

    try {
      final sample = SampleParser.parseString(meta.rawContent);
      await sample.messages.listen(controller.handleMessage).asFuture<void>();
    } catch (e) {
      _logger.warning('Error parsing sample ${meta.name}: $e');
    }

    await sub.cancel();

    if (!mounted) {
      controller.dispose();
      return;
    }

    if (surfaceIds.isEmpty) {
      controller.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No surfaces found in "${meta.name}"')),
        );
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => GalleryDetailDialog(
        name: meta.name,
        rawJsonl: meta.rawJsonl,
        controller: controller,
        surfaceIds: surfaceIds,
        onOpenInEditor: () {
          Navigator.of(context).pop();
          widget.onOpenInEditor(meta.rawJsonl);
        },
      ),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_samples.isEmpty) {
      return Center(
        child: Text(
          'No samples found.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text('Gallery', style: theme.textTheme.headlineSmall),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                int crossAxisCount = 2;
                if (width > 1400) {
                  crossAxisCount = 5;
                } else if (width > 1100) {
                  crossAxisCount = 4;
                } else if (width > 800) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _samples.length,
                  itemBuilder: (context, index) {
                    final meta = _samples[index];
                    return _GalleryCard(
                      meta: meta,
                      onTap: () => _openSampleDetail(meta),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight metadata for a gallery sample (no live rendering).
class _GallerySampleMeta {
  final String name;
  final String description;
  final String rawContent;
  final String rawJsonl;

  _GallerySampleMeta({
    required this.name,
    required this.description,
    required this.rawContent,
    required this.rawJsonl,
  });
}

/// A gallery card that shows only the sample name and description.
/// No live surface rendering — surfaces are created on-demand in the dialog.
class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.meta, required this.onTap});

  final _GallerySampleMeta meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.widgets_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meta.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (meta.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    meta.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
