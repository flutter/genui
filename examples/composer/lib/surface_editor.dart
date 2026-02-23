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

const _kProtocolVersion = 'v0.9';
const _kEditorSurfaceId = 'editor';
const _kDebounceDuration = Duration(milliseconds: 400);

/// A surface editor view that shows A2UI component JSON and data model
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

  /// The current components JSON text for display/edit.
  late String _currentJson;

  /// The current data model JSON for display/edit.
  String _currentDataJson = '{}';

  /// Flag to suppress listener notifications during programmatic updates.
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    _catalog = BasicCatalogItems.asCatalog();
    _currentJson = _normalizeToComponentsJson(widget.initialJsonl);
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

  /// Normalizes input JSON to the clean components-array format.
  String _normalizeToComponentsJson(String input) {
    final trimmed = input.trim();

    // Try as a JSON array directly.
    if (trimmed.startsWith('[')) {
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is List) {
          return const JsonEncoder.withIndent('  ').convert(parsed);
        }
      } catch (_) {}
    }

    // Try as JSONL — extract components from A2UI messages.
    final Map<String, Map<String, dynamic>> componentMap = {};
    final lines = const LineSplitter()
        .convert(trimmed)
        .where((line) => line.trim().isNotEmpty);

    for (final line in lines) {
      try {
        final obj = jsonDecode(line.trim());
        if (obj is Map<String, dynamic>) {
          final updateComp = obj['updateComponents'];
          if (updateComp is Map<String, dynamic>) {
            mergeComponentsById(
              updateComp['components'] as List? ?? [],
              componentMap,
            );
          }
          final components = obj['components'];
          if (components is List) {
            mergeComponentsById(components, componentMap);
          }
        }
      } catch (_) {}
    }

    if (componentMap.isNotEmpty) {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(componentMap.values.toList());
    }

    // Fallback: pretty-print each line as JSON.
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

      // Try as a components array.
      if (trimmed.startsWith('[')) {
        try {
          final parsed = jsonDecode(trimmed);
          if (parsed is List) {
            _applyComponentsArray(parsed);

            // Re-apply data model if we have one.
            if (_currentDataJson.trim().isNotEmpty &&
                _currentDataJson.trim() != '{}') {
              _applyDataModel(_currentDataJson);
            }
            return;
          }
        } catch (_) {}
      }

      // Fallback: try as JSONL (one JSON object per line).
      final lines = const LineSplitter()
          .convert(trimmed)
          .where(
            (line) => line.trim().isNotEmpty && line.trim().startsWith('{'),
          );

      for (final line in lines) {
        final obj = jsonDecode(line.trim());
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

  void _applyComponentsArray(List<dynamic> components) {
    final allIds = components
        .whereType<Map<String, dynamic>>()
        .map((c) => c['id'] as String?)
        .whereType<String>()
        .toSet();

    // Find which IDs are referenced by other components by scanning all string
    // values in every component. This is intentionally broad so it works with
    // any child-reference property (child, children, tabItems, etc.) without
    // hardcoding property names.
    final referencedIds = <String>{};
    for (final comp in components) {
      if (comp is Map<String, dynamic>) {
        _collectStringValues(comp, allIds, referencedIds);
      }
    }

    final rootCandidates = allIds.difference(referencedIds);
    final rootId = rootCandidates.isNotEmpty ? rootCandidates.first : 'root';

    _surfaceController.handleMessage(
      A2uiMessage.fromJson({
        'version': _kProtocolVersion,
        'createSurface': {
          'surfaceId': _kEditorSurfaceId,
          'catalogId': basicCatalogId,
          'sendDataModel': true,
        },
      }),
    );

    _surfaceController.handleMessage(
      A2uiMessage.fromJson({
        'version': _kProtocolVersion,
        'updateComponents': {
          'surfaceId': _kEditorSurfaceId,
          'root': rootId,
          'components': components,
        },
      }),
    );

    // Auto-generate a default data model from path references in components.
    final dataModel = _extractDataModelFromPaths(components);
    if (dataModel.isNotEmpty) {
      _surfaceController.handleMessage(
        A2uiMessage.fromJson({
          'version': _kProtocolVersion,
          'updateDataModel': {
            'surfaceId': _kEditorSurfaceId,
            'path': '/',
            'value': dataModel,
          },
        }),
      );
    }
  }

  /// Recursively walks [obj] and adds any string values that appear in
  /// [knownIds] to [result]. Skips the component's own 'id' key.
  void _collectStringValues(
    Object? obj,
    Set<String> knownIds,
    Set<String> result, {
    String? parentKey,
  }) {
    if (obj is Map<String, dynamic>) {
      for (final entry in obj.entries) {
        _collectStringValues(
          entry.value,
          knownIds,
          result,
          parentKey: entry.key,
        );
      }
    } else if (obj is List) {
      for (final item in obj) {
        _collectStringValues(item, knownIds, result);
      }
    } else if (obj is String && parentKey != 'id' && knownIds.contains(obj)) {
      result.add(obj);
    }
  }

  /// Scans component definitions for `{"path": "..."}` data bindings and
  /// builds a default data model with empty string values at those paths.
  Map<String, dynamic> _extractDataModelFromPaths(List<dynamic> components) {
    final Map<String, dynamic> model = {};

    for (final comp in components) {
      if (comp is Map<String, dynamic>) {
        _findPathRefs(comp, model);
      }
    }

    return model;
  }

  /// Recursively finds {"path": "/..."} references in a JSON structure
  /// and sets default empty values at those paths in [model].
  void _findPathRefs(Object? obj, Map<String, dynamic> model) {
    if (obj is Map<String, dynamic>) {
      // Check if this map IS a path reference (e.g. {"path": "/display"})
      if (obj.length <= 2 && obj.containsKey('path') && obj['path'] is String) {
        final String path = obj['path'] as String;
        setNestedValue(model, path, '');
      } else {
        for (final value in obj.values) {
          _findPathRefs(value, model);
        }
      }
    } else if (obj is List) {
      for (final item in obj) {
        _findPathRefs(item, model);
      }
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
            'version': _kProtocolVersion,
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
              // Left pane: JSON editors (components + data)
              Expanded(
                child: Column(
                  children: [
                    // Components editor (upper)
                    Expanded(
                      flex: 3,
                      child: _buildEditorSection(
                        theme: theme,
                        label: 'Components',
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

  /// Builds a reusable editor section (used for both components and data).
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
