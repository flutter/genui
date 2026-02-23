// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'gallery_detail_dialog.dart';
import 'sample_parser.dart';
import 'surface_utils.dart';

/// The Gallery tab displays a grid of pre-generated sample surfaces.
/// Cards show sample name and description. Clicking a card opens a dialog
/// that renders the live surface.
class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key, required this.onOpenInEditor});

  /// Called with the JSONL (and optional data JSON) when the user clicks
  /// "Open in Surface Editor".
  final void Function(String jsonl, {String? dataJson}) onOpenInEditor;

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
    final result = await loadSampleSurface(meta.rawContent);

    if (!mounted) {
      result.controller.dispose();
      return;
    }

    if (result.surfaceIds.isEmpty) {
      result.controller.dispose();
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
        controller: result.controller,
        surfaceIds: result.surfaceIds,
        onOpenInEditor: () {
          // Extract data model from the controller before closing.
          String? dataJson;
          if (result.surfaceIds.isNotEmpty) {
            final dm = result.controller.store
                .getDataModel(result.surfaceIds.first);
            if (dm.data.isNotEmpty) {
              dataJson =
                  const JsonEncoder.withIndent('  ').convert(dm.data);
            }
          }
          Navigator.of(context).pop();
          widget.onOpenInEditor(meta.rawJsonl, dataJson: dataJson);
        },
      ),
    );

    result.controller.dispose();
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

/// A gallery card that renders a live, sandboxed surface preview.
///
/// Each card creates its own [SurfaceController] on init, feeds the sample
/// messages into it, and renders the resulting surface scaled down to fit the
/// card. The preview is non-interactive (taps pass through to the card's
/// InkWell) and fully clipped to prevent layout overflow.
class _GalleryCard extends StatefulWidget {
  const _GalleryCard({required this.meta, required this.onTap});

  final _GallerySampleMeta meta;
  final VoidCallback onTap;

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  SurfaceController? _controller;
  List<String> _surfaceIds = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSurface();
  }

  Future<void> _loadSurface() async {
    try {
      final result = await loadSampleSurface(widget.meta.rawContent);
      if (mounted) {
        setState(() {
          _controller = result.controller;
          _surfaceIds = result.surfaceIds;
          _isLoading = false;
        });
      } else {
        result.controller.dispose();
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Surface preview area
            Expanded(child: _buildPreview(theme)),
            // Name bar at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Tooltip(
                message: widget.meta.description,
                child: Text(
                  widget.meta.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
        ),
      );
    }

    if (_hasError || _surfaceIds.isEmpty || _controller == null) {
      return Center(
        child: Icon(
          Icons.widgets_outlined,
          size: 32,
          color: theme.colorScheme.onSurfaceVariant.withAlpha(60),
        ),
      );
    }

    // Render the surface at a large virtual width with unconstrained height
    // (matching how the modal dialog renders surfaces). OverflowBox replaces
    // the parent's tight constraints so the Surface lays out as if it had
    // real screen space. Transform.scale shrinks the result visually, and
    // ClipRect clips anything beyond the card bounds.
    return ClipRect(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const virtualWidth = 500.0;
              final scale = constraints.maxWidth / virtualWidth;

              return Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxWidth: virtualWidth,
                  minWidth: virtualWidth,
                  maxHeight: double.infinity,
                  minHeight: 0,
                  child: Surface(
                    key: ValueKey(_surfaceIds.first),
                    surfaceContext: _controller!.contextFor(
                      _surfaceIds.first,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
