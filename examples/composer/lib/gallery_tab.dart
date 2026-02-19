// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

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

  void _openSampleInEditor(_GallerySampleMeta meta) {
    widget.onOpenInEditor(meta.rawJsonl);
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
                if (width > 1200) {
                  crossAxisCount = 3;
                }

                return SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int col = 0; col < crossAxisCount; col++) ...[
                        if (col > 0) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = col;
                                  i < _samples.length;
                                  i += crossAxisCount) ...[
                                if (i >= crossAxisCount)
                                  const SizedBox(height: 12),
                                _GalleryCard(
                                  meta: _samples[i],
                                  onTap: () => _openSampleInEditor(_samples[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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

class _GalleryCardState extends State<_GalleryCard>
    with AutomaticKeepAliveClientMixin {
  SurfaceController? _controller;
  List<String> _surfaceIds = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Small name label at top
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Tooltip(
                message: widget.meta.description,
                child: Text(
                  widget.meta.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Surface preview area
            ClipRect(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _buildPreview(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
            ),
          ),
        ),
      );
    }

    if (_hasError || _surfaceIds.isEmpty || _controller == null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Icon(
            Icons.widgets_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(60),
          ),
        ),
      );
    }

    final String surfaceId = _surfaceIds.first;
    final SurfaceContext surfaceContext = _controller!.contextFor(surfaceId);

    return RepaintBoundary(
      child: IgnorePointer(
        child: Surface(
          key: ValueKey(surfaceId),
          surfaceContext: surfaceContext,
        ),
      ),
    );
  }
}
