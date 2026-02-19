// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'json_highlighter.dart';

/// A modal dialog showing a gallery surface preview and its backing A2UI JSON.
class GalleryDetailDialog extends StatelessWidget {
  const GalleryDetailDialog({
    super.key,
    required this.name,
    required this.rawJsonl,
    required this.controller,
    required this.surfaceIds,
    required this.onOpenInEditor,
  });

  final String name;
  final String rawJsonl;
  final SurfaceController controller;
  final List<String> surfaceIds;
  final VoidCallback onOpenInEditor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final formattedJson = JsonHighlighter.prettyPrintJsonl(rawJsonl);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: screenSize.width * 0.85,
        height: screenSize.height * 0.8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: onOpenInEditor,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open in Surface Editor'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Row(
                  children: [
                    // Left: Preview
                    Expanded(
                      child: Container(
                        color: theme.colorScheme.surfaceContainerLowest,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              for (final surfaceId in surfaceIds)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Surface(
                                    key: ValueKey(surfaceId),
                                    surfaceContext: controller.contextFor(
                                      surfaceId,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Right: JSON with syntax highlighting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: theme.dividerColor),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'A2UI JSONL',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: theme.colorScheme.surfaceContainerLowest,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: SelectionArea(
                                  child: Text.rich(
                                    JsonHighlighter.instance.highlight(
                                      formattedJson,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
