// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:genui/genui.dart';
import 'package:highlight/languages/json.dart' as json_lang;

import 'surface_utils.dart';

const _kEditorSurfaceId = 'editor';
const _kDebounceDuration = Duration(milliseconds: 400);

/// A surface editor view that shows A2UI JSONL and data model
/// on the left and a live rendered preview on the right.
class SurfaceEditorView extends StatefulWidget {
  const SurfaceEditorView({
    super.key,
    required this.initialJsonl,
    this.initialDataJson,
    required this.onClose,
  });

  /// The initial JSON string to load. Can be either:
  /// - A JSON array of components (clean format from Create tab)
  /// - JSONL with A2UI protocol messages (from Gallery samples)
  final String initialJsonl;

  /// Optional initial data model JSON to pre-populate the Data pane.
  final String? initialDataJson;

  /// Called when the user wants to close the editor and go back.
  final VoidCallback onClose;

  @override
  State<SurfaceEditorView> createState() => _SurfaceEditorViewState();
}

class _SurfaceEditorViewState extends State<SurfaceEditorView> {
  late CodeController _jsonController;
  late CodeController _dataController;
  late SurfaceController _surfaceController;
  late final Catalog _catalog;
  final List<String> _surfaceIds = [];
  StreamSubscription<SurfaceUpdate>? _surfaceSub;
  Timer? _jsonDebounce;
  Timer? _dataDebounce;
  String? _parseError;
  String? _dataError;

  /// The current JSONL text for display/edit.
  late String _currentJson;

  /// The current data model JSON for display/edit.
  String _currentDataJson = '{}';

  /// Flag to suppress listener notifications during programmatic updates.
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    _catalog = BasicCatalogItems.asCatalog();
    _currentJson = _toJsonl(widget.initialJsonl, widget.initialDataJson);
    if (widget.initialDataJson != null &&
        widget.initialDataJson!.trim().isNotEmpty) {
      _currentDataJson = widget.initialDataJson!;
    }
    _jsonController = CodeController(
      text: _currentJson,
      language: json_lang.json,
    );
    _dataController = CodeController(
      text: _currentDataJson,
      language: json_lang.json,
    );

    _surfaceController = SurfaceController(catalogs: [_catalog]);
    _setupSurfaceListener();
    _applyJson(_currentJson);

    // Add listeners after initial setup to avoid spurious triggers.
    _jsonController.addListener(_onJsonControllerChanged);
    _dataController.addListener(_onDataControllerChanged);
  }

  /// Converts input to pretty-printed JSONL. If the input is already JSONL,
  /// pretty-prints each line. If it's a components array, wraps it in
  /// protocol envelopes.
  static String _toJsonl(String input, String? dataJson) {
    final trimmed = input.trim();

    // If it's a components array, convert to full JSONL.
    if (trimmed.startsWith('[')) {
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is List) {
          return componentsToJsonl(
            trimmed,
            dataJson: dataJson,
            surfaceId: _kEditorSurfaceId,
          );
        }
      } catch (_) {}
    }

    // Already JSONL — pretty-print each line.
    final lines = const LineSplitter()
        .convert(trimmed)
        .where((line) => line.trim().isNotEmpty);
    final formatted = <String>[];
    for (final line in lines) {
      try {
        final parsed = jsonDecode(line.trim());
        formatted.add(const JsonEncoder.withIndent('  ').convert(parsed));
      } catch (_) {
        formatted.add(line);
      }
    }
    return formatted.join('\n\n');
  }

  void _setupSurfaceListener() {
    _surfaceSub = _surfaceController.surfaceUpdates.listen((update) {
      if (update is SurfaceAdded) {
        if (!_surfaceIds.contains(update.surfaceId)) {
          setState(() {
            _surfaceIds.add(update.surfaceId);
          });
          _refreshDataModelDisplay();
        }
      } else if (update is SurfaceRemoved) {
        setState(() {
          _surfaceIds.remove(update.surfaceId);
        });
      } else if (update is ComponentsUpdated) {
        _refreshDataModelDisplay();
      }
    });
  }

  /// Refreshes the data model display from the current SurfaceController state.
  void _refreshDataModelDisplay() {
    if (_surfaceIds.isEmpty) return;

    final surfaceId = _surfaceIds.first;
    final dataModel = _surfaceController.store.getDataModel(surfaceId);
    final dataJson = const JsonEncoder.withIndent('  ').convert(dataModel.data);

    _isInternalUpdate = true;
    _dataController.text = dataJson;
    _isInternalUpdate = false;
    setState(() {
      _currentDataJson = dataJson;
    });
  }

  void _applyJson(String json) {
    _surfaceSub?.cancel();
    _surfaceController.dispose();

    _surfaceController = SurfaceController(catalogs: [_catalog]);
    _surfaceIds.clear();
    _setupSurfaceListener();

    setState(() {
      _parseError = null;
    });

    try {
      final trimmed = json.trim();

      // Split on blank lines to separate pretty-printed JSON messages.
      final chunks = trimmed.split(RegExp(r'\n\s*\n'));

      for (final chunk in chunks) {
        final trimmedChunk = chunk.trim();
        if (trimmedChunk.isEmpty || !trimmedChunk.startsWith('{')) continue;

        final obj = jsonDecode(trimmedChunk);
        if (obj is Map<String, dynamic>) {
          final message = A2uiMessage.fromJson(obj);
          _surfaceController.handleMessage(message);
        }
      }
      _refreshDataModelDisplay();
    } catch (e) {
      setState(() {
        _parseError = e.toString();
      });
    }
  }

  /// Applies data model JSON to the current surface.
  void _applyDataModel(String dataJson) {
    if (_surfaceIds.isEmpty) return;

    setState(() {
      _dataError = null;
    });

    try {
      final parsed = jsonDecode(dataJson.trim());
      if (parsed is Map<String, dynamic>) {
        final surfaceId = _surfaceIds.first;
        _surfaceController.handleMessage(
          A2uiMessage.fromJson({
            'version': kProtocolVersion,
            'updateDataModel': {
              'surfaceId': surfaceId,
              'path': '/',
              'value': parsed,
            },
          }),
        );
      } else {
        setState(() {
          _dataError = 'Data model must be a JSON object';
        });
      }
    } catch (e) {
      setState(() {
        _dataError = e.toString();
      });
    }
  }

  void _onJsonControllerChanged() {
    final text = _jsonController.text;
    if (text == _currentJson) return;
    _currentJson = text;
    _jsonDebounce?.cancel();
    _jsonDebounce = Timer(_kDebounceDuration, () => _applyJson(text));
  }

  void _onDataControllerChanged() {
    if (_isInternalUpdate) return;
    final text = _dataController.text;
    if (text == _currentDataJson) return;
    _currentDataJson = text;
    _dataDebounce?.cancel();
    _dataDebounce = Timer(_kDebounceDuration, () => _applyDataModel(text));
  }

  @override
  void dispose() {
    _jsonDebounce?.cancel();
    _dataDebounce?.cancel();
    _jsonController.removeListener(_onJsonControllerChanged);
    _dataController.removeListener(_onDataControllerChanged);
    _surfaceSub?.cancel();
    _surfaceController.dispose();
    _jsonController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onClose,
                tooltip: 'Back to Create',
              ),
              const SizedBox(width: 8),
              Text('Surface Editor', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        // Editor body
        Expanded(
          child: Row(
            children: [
              // Left pane: JSON editors (JSONL + data)
              Expanded(
                child: Column(
                  children: [
                    // JSONL editor (upper)
                    Expanded(
                      flex: 3,
                      child: _buildEditorSection(
                        theme: theme,
                        label: 'JSONL',
                        controller: _jsonController,
                        error: _parseError,
                      ),
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    // Data model editor (lower)
                    Expanded(
                      flex: 2,
                      child: _buildEditorSection(
                        theme: theme,
                        label: 'Data',
                        controller: _dataController,
                        error: _dataError,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              const VerticalDivider(width: 1),
              // Right pane: Preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Preview',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(4, 0, 8, 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                          color: theme.colorScheme.surfaceContainerLowest,
                        ),
                        child: _surfaceIds.isEmpty
                            ? Center(
                                child: Text(
                                  _parseError != null
                                      ? 'Fix the JSON to see a preview'
                                      : 'No surfaces to display',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    for (final surfaceId in _surfaceIds)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Surface(
                                          key: ValueKey(surfaceId),
                                          surfaceContext: _surfaceController
                                              .contextFor(surfaceId),
                                        ),
                                      ),
                                  ],
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
    );
  }

  /// Builds a reusable editor section (used for both JSONL and data).
  Widget _buildEditorSection({
    required ThemeData theme,
    required String label,
    required CodeController controller,
    required String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceContainerLowest,
              ),
              clipBehavior: Clip.antiAlias,
              child: CodeTheme(
                data: CodeThemeData(styles: vsTheme),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: controller,
                    gutterStyle: GutterStyle.none,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onErrorContainer,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}
