// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'json_highlighter.dart';

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
  late TextEditingController _jsonController;
  late TextEditingController _dataController;
  late SurfaceController _surfaceController;
  final List<String> _surfaceIds = [];
  StreamSubscription<SurfaceUpdate>? _surfaceSub;
  String? _parseError;
  String? _dataError;

  /// The current components JSON text for display/edit.
  late String _currentJson;

  /// The current data model JSON for display/edit.
  String _currentDataJson = '{}';

  /// Whether the user is currently editing the components JSON.
  bool _isEditingComponents = false;

  /// Whether the user is currently editing the data model JSON.
  bool _isEditingData = false;

  @override
  void initState() {
    super.initState();

    _currentJson = _normalizeToComponentsJson(widget.initialJsonl);
    if (widget.initialDataJson != null &&
        widget.initialDataJson!.trim().isNotEmpty) {
      _currentDataJson = widget.initialDataJson!;
    }
    _jsonController = TextEditingController(text: _currentJson);
    _dataController = TextEditingController(text: _currentDataJson);

    final Catalog catalog = BasicCatalogItems.asCatalog();
    _surfaceController = SurfaceController(catalogs: [catalog]);
    _setupSurfaceListener();
    _applyJson(_currentJson);
  }

  /// Normalizes input JSON to the clean components-array format.
  String _normalizeToComponentsJson(String input) {
    final trimmed = input.trim();

    if (trimmed.startsWith('[')) {
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is List) {
          return const JsonEncoder.withIndent('  ').convert(parsed);
        }
      } catch (_) {}
    }

    final Map<String, Map<String, dynamic>> componentMap = {};
    final objects = _extractJsonObjects(trimmed);

    for (final objStr in objects) {
      try {
        final obj = jsonDecode(objStr);
        if (obj is Map<String, dynamic>) {
          final updateComp = obj['updateComponents'];
          if (updateComp is Map<String, dynamic>) {
            _mergeComponents(componentMap, updateComp['components']);
          }
          final components = obj['components'];
          if (components is List) {
            _mergeComponents(componentMap, components);
          }
        }
      } catch (_) {}
    }

    if (componentMap.isNotEmpty) {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(componentMap.values.toList());
    }

    return JsonHighlighter.prettyPrintJsonl(input);
  }

  void _mergeComponents(
    Map<String, Map<String, dynamic>> map,
    dynamic components,
  ) {
    if (components is! List) return;
    for (final comp in components) {
      if (comp is Map<String, dynamic> && comp['id'] != null) {
        map[comp['id'] as String] = comp;
      }
    }
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
    if (_surfaceIds.isEmpty || _isEditingData) return;

    final surfaceId = _surfaceIds.first;
    final dataModel = _surfaceController.store.getDataModel(surfaceId);
    final dataJson = const JsonEncoder.withIndent('  ').convert(dataModel.data);

    setState(() {
      _currentDataJson = dataJson;
      _dataController.text = dataJson;
    });
  }

  void _applyJson(String json) {
    _surfaceSub?.cancel();
    _surfaceController.dispose();

    final Catalog catalog = BasicCatalogItems.asCatalog();
    _surfaceController = SurfaceController(catalogs: [catalog]);
    _surfaceIds.clear();
    _setupSurfaceListener();

    setState(() {
      _parseError = null;
    });

    try {
      final trimmed = json.trim();

      if (trimmed.startsWith('[')) {
        try {
          final parsed = jsonDecode(trimmed);
          if (parsed is List) {
            _applyComponentsArray(parsed);

            // Re-apply data model if we have one
            if (_currentDataJson.trim().isNotEmpty &&
                _currentDataJson.trim() != '{}') {
              _applyDataModel(_currentDataJson);
            }
            return;
          }
        } catch (_) {}
      }

      final objects = _extractJsonObjects(trimmed);
      if (objects.isNotEmpty) {
        for (final objStr in objects) {
          final obj = jsonDecode(objStr);
          if (obj is Map<String, dynamic>) {
            final message = A2uiMessage.fromJson(obj);
            _surfaceController.handleMessage(message);
          }
        }
        _refreshDataModelDisplay();
        return;
      }

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

    final referencedIds = <String>{};
    for (final comp in components) {
      if (comp is Map<String, dynamic>) {
        final child = comp['child'];
        if (child is String) referencedIds.add(child);
        final children = comp['children'];
        if (children is List) {
          for (final c in children) {
            if (c is String) referencedIds.add(c);
          }
        }
        final tabItems = comp['tabItems'];
        if (tabItems is List) {
          for (final item in tabItems) {
            if (item is Map<String, dynamic>) {
              final itemChild = item['child'];
              if (itemChild is String) referencedIds.add(itemChild);
            }
          }
        }
        final entryPointChild = comp['entryPointChild'];
        if (entryPointChild is String) referencedIds.add(entryPointChild);
        final contentChild = comp['contentChild'];
        if (contentChild is String) referencedIds.add(contentChild);
      }
    }

    final rootCandidates = allIds.difference(referencedIds);
    final rootId = rootCandidates.isNotEmpty ? rootCandidates.first : 'root';

    _surfaceController.handleMessage(
      A2uiMessage.fromJson({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'editor',
          'catalogId':
              'https://a2ui.org/specification/v0_9/standard_catalog.json',
          'sendDataModel': true,
        },
      }),
    );

    _surfaceController.handleMessage(
      A2uiMessage.fromJson({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'editor',
          'root': rootId,
          'components': components,
        },
      }),
    );

    // Auto-generate a default data model from path references in components.
    // Scan all component properties for {"path": "..."} bindings and create
    // skeleton values so the Data pane shows the relevant state variables.
    final dataModel = _extractDataModelFromPaths(components);
    if (dataModel.isNotEmpty) {
      _surfaceController.handleMessage(
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateDataModel': {
            'surfaceId': 'editor',
            'path': '/',
            'value': dataModel,
          },
        }),
      );
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
        _setDefaultAtPath(model, path, '');
      } else {
        // Recurse into all values
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

  /// Sets a default value at a path in the data model if not already set.
  /// Path format: "/segment1/segment2/..."
  void _setDefaultAtPath(
    Map<String, dynamic> model,
    String path,
    Object defaultValue,
  ) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    Map<String, dynamic> current = model;
    for (int i = 0; i < segments.length - 1; i++) {
      current.putIfAbsent(segments[i], () => <String, dynamic>{});
      final next = current[segments[i]];
      if (next is Map<String, dynamic>) {
        current = next;
      } else {
        return; // Path conflict, skip
      }
    }

    // Only set if not already present
    current.putIfAbsent(segments.last, () => defaultValue);
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
            'version': 'v0.9',
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

  List<String> _extractJsonObjects(String text) {
    final objects = <String>[];
    int depth = 0;
    int? start;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0 && start != null) {
          objects.add(text.substring(start, i + 1));
          start = null;
        }
      }
    }
    return objects;
  }

  void _onComponentsChanged(String value) {
    setState(() {
      _currentJson = value;
    });
    _applyJson(value);
  }

  void _onDataChanged(String value) {
    setState(() {
      _currentDataJson = value;
    });
    _applyDataModel(value);
  }

  void _toggleEditingComponents() {
    setState(() {
      _isEditingComponents = !_isEditingComponents;
      if (_isEditingComponents) {
        _jsonController.text = _currentJson;
      }
    });
  }

  void _toggleEditingData() {
    setState(() {
      _isEditingData = !_isEditingData;
      if (_isEditingData) {
        _dataController.text = _currentDataJson;
      } else {
        // When exiting edit mode, re-apply the current text
        _applyDataModel(_currentDataJson);
      }
    });
  }

  @override
  void dispose() {
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
                        content: _currentJson,
                        controller: _jsonController,
                        isEditing: _isEditingComponents,
                        onToggleEdit: _toggleEditingComponents,
                        onChanged: _onComponentsChanged,
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
                        content: _currentDataJson,
                        controller: _dataController,
                        isEditing: _isEditingData,
                        onToggleEdit: _toggleEditingData,
                        onChanged: _onDataChanged,
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
    required String content,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onToggleEdit,
    required ValueChanged<String> onChanged,
    required String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(isEditing ? Icons.visibility : Icons.edit, size: 18),
                onPressed: onToggleEdit,
                tooltip: isEditing ? 'View highlighted' : 'Edit',
                visualDensity: VisualDensity.compact,
              ),
            ],
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
              child: isEditing
                  ? TextField(
                      controller: controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: onChanged,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectionArea(
                        child: Text.rich(
                          JsonHighlighter.instance.highlight(content),
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
