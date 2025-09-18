// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart' show DeepCollectionEquality;
import 'package:flutter/material.dart';

import '../core/binding_processor.dart';
import '../core/data_type_validator.dart';
import '../core/fcp_state.dart';
import '../core/layout_patcher.dart';
import '../core/state_patcher.dart';
import '../core/widget_catalog_registry.dart';
import '../models/models.dart';
import 'fcp_provider.dart';
import 'fcp_view_controller.dart';

/// The main entry point for rendering a UI from the Flutter Composition
/// Protocol.
///
/// This widget takes a [packet] containing the layout and state, a [catalog]
/// defining the data types, and a [registry] of widget builders, and
/// constructs the corresponding Flutter widget tree. It manages the dynamic
/// state and updates the UI when the state changes.
class FcpView extends StatefulWidget {
  /// Creates a widget that renders a UI from an FCP [packet].
  ///
  /// The [catalog] and [registry] are required to interpret the packet. The
  /// [onEvent] callback is invoked when a widget triggers an event. The
  /// [controller] can be used to programmatically update the view.
  const FcpView({
    super.key,
    required this.packet,
    required this.catalog,
    required this.registry,
    this.onEvent,
    this.controller,
  });

  /// The self-contained UI packet from the server.
  final DynamicUIPacket packet;

  /// The widget library catalog defining the capabilities of the client.
  final WidgetCatalog catalog;

  /// The registry mapping widget types to builder functions.
  final WidgetCatalogRegistry registry;

  /// A callback function that is invoked when an event is triggered by a
  /// widget.
  final ValueChanged<EventPayload>? onEvent;

  /// A controller to programmatically update the view's state or layout.
  final FcpViewController? controller;

  @override
  State<FcpView> createState() => _FcpViewState();
}

class _FcpViewState extends State<FcpView> {
  FcpState? _state;
  StatePatcher? _statePatcher;
  DataTypeValidator? _dataTypeValidator;
  BindingProcessor? _bindingProcessor;
  _LayoutEngine? _engine;
  Listenable? _listenable;

  StreamSubscription? _stateUpdateSubscription;
  StreamSubscription? _layoutUpdateSubscription;

  bool _isStateInvalid = false;
  String _invalidStateMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeFromPacket();
    _listenToController();
  }

  void _initializeFromPacket() {
    _dataTypeValidator = DataTypeValidator();
    _state = FcpState(
      widget.packet.state,
      validator: _dataTypeValidator!,
      catalog: widget.catalog,
    );
    _statePatcher = StatePatcher();
    _bindingProcessor = BindingProcessor(_state!);
    _engine = _LayoutEngine(
      registry: widget.registry,
      catalog: widget.catalog,
      layout: widget.packet.layout,
      bindingProcessor: _bindingProcessor!,
    );

    _listenable = Listenable.merge([_state!, _engine!]);
    _validateInitialState();
  }

  void _validateInitialState() async {
    if (!await _state!.validate(_state!.state)) {
      if (!mounted) return;
      setState(() {
        _isStateInvalid = true;
        _invalidStateMessage = 'Initial state is invalid.';
      });
    }
  }

  @override
  void didUpdateWidget(FcpView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _unlistenToController();
      _listenToController();
    }

    if (!const DeepCollectionEquality().equals(
      widget.packet.toJson(),
      oldWidget.packet.toJson(),
    )) {
      _initializeFromPacket();
    }
  }

  void _listenToController() {
    _stateUpdateSubscription = widget.controller?.onStateUpdate.listen((
      update,
    ) {
      _statePatcher!.apply(_state!, update);
    });
    _layoutUpdateSubscription = widget.controller?.onLayoutUpdate.listen((
      update,
    ) {
      _engine!.patch(update);
    });
  }

  void _unlistenToController() {
    _stateUpdateSubscription?.cancel();
    _layoutUpdateSubscription?.cancel();
  }

  @override
  void dispose() {
    _unlistenToController();
    _engine?.dispose();
    _state?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStateInvalid) {
      return _ErrorWidget(_invalidStateMessage);
    }
    return FcpProvider(
      onEvent: widget.onEvent,
      // ListenableBuilder listens to both state and layout changes and rebuilds
      // the entire tree. Flutter's diffing is efficient enough for this to be
      // performant for most cases.
      child: ListenableBuilder(
        listenable: _listenable!,
        builder: (context, _) {
          return _engine!.build(context);
        },
      ),
    );
  }
}

/// The internal engine that builds the widget tree from the layout.
/// It uses a [BindingProcessor] to handle dynamic data.
class _LayoutEngine with ChangeNotifier {
  _LayoutEngine({
    required this.registry,
    required this.catalog,
    required Layout layout,
    required this.bindingProcessor,
  }) {
    reset(layout);
  }

  final WidgetCatalogRegistry registry;
  final WidgetCatalog catalog;
  final BindingProcessor bindingProcessor;
  final LayoutPatcher _patcher = LayoutPatcher();

  late Layout _layout;
  late Map<String, LayoutNode> _nodesById;

  /// Resets the engine to a new, clean layout.
  void reset(Layout newLayout) {
    _layout = newLayout;
    _nodesById = {for (var node in _layout.nodes) node.id: node};
    notifyListeners();
  }

  /// Patches the current layout with an update and notifies listeners.
  void patch(LayoutUpdate update) {
    _patcher.apply(_nodesById, update);
    notifyListeners();
  }

  /// Builds the entire widget tree.
  Widget build(BuildContext context) {
    return _buildNode(context, _layout.root);
  }

  /// Recursively builds a single layout node and its descendants.
  Widget _buildNode(
    BuildContext context,
    String nodeId, [
    Set<String> visited = const {},
  ]) {
    // Check for cyclical dependencies.
    if (visited.contains(nodeId)) {
      return _ErrorWidget(
        'Cyclical layout detected. Node "$nodeId" is already in the build '
        'path.',
      );
    }
    final currentPath = {...visited, nodeId};

    final node = _nodesById[nodeId];
    if (node == null) {
      return _ErrorWidget('Node with id "$nodeId" not found in layout.');
    }

    // Handle special-cased list view builder.
    if (node.type == 'ListViewBuilder') {
      return _buildListView(context, node, currentPath);
    }

    final builder = registry.getBuilder(node.type);
    if (builder == null) {
      return _ErrorWidget(
        'No builder registered for widget type "${node.type}".',
      );
    }

    // Validate required properties.
    final itemDefMap = catalog.items[node.type];
    if (itemDefMap == null) {
      return _ErrorWidget(
        'Catalog item type "${node.type}" not found in catalog.',
      );
    }
    final itemDef = WidgetDefinition.fromMap(
      itemDefMap as Map<String, Object?>,
    );

    // Resolve dynamic properties from bindings.
    final boundProperties = bindingProcessor.process(node);

    // Merge static and dynamic properties. Bound properties override static
    // ones.
    final resolvedProperties = {...?node.properties, ...boundProperties};

    final requiredProperties = itemDef.properties.required ?? [];
    for (final propName in requiredProperties) {
      if (!resolvedProperties.containsKey(propName)) {
        return _ErrorWidget(
          'Missing required property "$propName" for widget type '
          '"${node.type}".',
        );
      }
    }

    // Recursively build all children defined in the properties.
    final builtChildren = <String, List<Widget>>{};
    for (final entry in resolvedProperties.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String && _nodesById.containsKey(value)) {
        // This is a single child reference by ID.
        builtChildren[key] = [_buildNode(context, value, currentPath)];
      } else if (value is List) {
        // This could be a list of child references by ID.
        final childWidgets = <Widget>[];
        for (final item in value) {
          if (item is String && _nodesById.containsKey(item)) {
            childWidgets.add(_buildNode(context, item, currentPath));
          }
        }
        if (childWidgets.isNotEmpty) {
          builtChildren[key] = childWidgets;
        }
      }
    }

    // Build the current widget.
    return builder(context, node, resolvedProperties, builtChildren);
  }

  Widget _buildListView(
    BuildContext context,
    LayoutNode node,
    Set<String> visited,
  ) {
    final itemDefMap = catalog.items[node.type];
    if (itemDefMap == null) {
      return _ErrorWidget(
        'Catalog item type "${node.type}" not found in catalog.',
      );
    }
    final boundProperties = bindingProcessor.process(node);
    final data = boundProperties['data'] as List<dynamic>? ?? [];
    final itemTemplate = node.itemTemplate;

    if (itemTemplate == null) {
      return _ErrorWidget(
        'ListViewBuilder "${node.id}" is missing itemTemplate.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final itemData = data[index] as Map<String, Object?>;
        return _buildListItem(context, itemTemplate, itemData, visited);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    LayoutNode templateNode,
    Map<String, Object?> itemData,
    Set<String> visited,
  ) {
    // Cycle checking is handled by passing the `visited` set to _buildNode.
    final builder = registry.getBuilder(templateNode.type);
    if (builder == null) {
      return _ErrorWidget(
        'No builder for itemTemplate type "${templateNode.type}".',
      );
    }

    final itemDefMap = catalog.items[templateNode.type];
    if (itemDefMap == null) {
      return _ErrorWidget(
        'Catalog item type "${templateNode.type}" not found in catalog for '
        'itemTemplate.',
      );
    }

    final boundProperties = bindingProcessor.processScoped(
      templateNode,
      itemData,
    );
    final resolvedProperties = {
      ...?templateNode.properties,
      ...boundProperties,
    };

    // Recursively build children.
    final builtChildren = <String, List<Widget>>{};
    for (final entry in resolvedProperties.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String && _nodesById.containsKey(value)) {
        builtChildren[key] = [_buildNode(context, value, visited)];
      } else if (value is List) {
        final childWidgets = <Widget>[];
        for (final item in value) {
          if (item is String && _nodesById.containsKey(item)) {
            childWidgets.add(_buildNode(context, item, visited));
          }
        }
        if (childWidgets.isNotEmpty) {
          builtChildren[key] = childWidgets;
        }
      }
    }

    return builder(context, templateNode, resolvedProperties, builtChildren);
  }
}

/// A simple, visible error widget for displaying issues during rendering.
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red.shade100,
          child: Text(
            'FCP Error: $message',
            style: TextStyle(color: Colors.red.shade900),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
