// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'fallback_widget.dart';
import 'surface.dart';

/// Experimental sibling of [Surface] backed by the a2ui_core node layer.
///
/// Where [Surface] rebuilds the whole widget tree from an immutable
/// [SurfaceDefinition] snapshot on every update, this widget renders the
/// live resolved tree from a [core.NodeResolver]: each node's subtree
/// rebuilds only when that node's own resolved properties change.
///
/// Catalog views are reused unchanged. They receive the component's raw
/// properties and bind dynamic values and dispatch actions themselves,
/// exactly as under [Surface]; the node layer contributes the children:
/// child-reference properties arrive as resolved nodes (templates expanded
/// one node per data item, missing components as placeholders swapped in
/// place, list changes reconciled with surviving nodes reused). Properties
/// the engine cannot classify as child references fall back to the legacy
/// id-walking path, so catalogs work before their schemas declare
/// references.
class NodeSurface extends StatefulWidget {
  /// Creates a [NodeSurface].
  const NodeSurface({
    super.key,
    required this.surface,
    required this.catalog,
    required this.onEvent,
    this.defaultBuilder,
    this.reportError,
  });

  /// The live surface model to resolve and render.
  final core.SurfaceModel<core.ComponentApi> surface;

  /// The catalog providing the widget builders.
  final Catalog catalog;

  /// Called with every UI event dispatched from this surface's widgets.
  final UiEventCallback onEvent;

  /// A builder for the widget to display before the root component arrives.
  final WidgetBuilder? defaultBuilder;

  /// Called when building a component fails. Defaults to logging.
  final void Function(Object error, StackTrace? stackTrace)? reportError;

  @override
  State<NodeSurface> createState() => _NodeSurfaceState();
}

class _NodeSurfaceState extends State<NodeSurface> {
  late core.NodeResolver<core.ComponentApi> _resolver;
  late InMemoryDataModel _dataModel;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(NodeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.surface, widget.surface)) {
      _detach();
      _attach();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _attach() {
    genUiLogger.info(
      'NodeSurface attached to surface ${widget.surface.id}; rendering '
      'through the node layer',
    );
    _dataModel = InMemoryDataModel.wrap(widget.surface.dataModel);
    _resolver = core.NodeResolver<core.ComponentApi>(
      widget.surface,
      widget.surface.catalog,
    );
  }

  void _detach() {
    _resolver.dispose();
    _dataModel.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SignalBuilder<core.ComponentNode?>(
      signal: _resolver.rootNode,
      builder: (context, root) {
        if (root == null) {
          return widget.defaultBuilder?.call(context) ??
              const SizedBox.shrink();
        }
        return _buildNode(root);
      },
    );
  }

  Widget _buildNode(core.ComponentNode node) {
    return _SignalBuilder<core.NodeProps>(
      // Keyed by node identity: when the resolver replaces a node (a
      // placeholder upgrade, an id change), the old element's subscription
      // is disposed with it.
      key: ObjectKey(node),
      signal: node.props,
      builder: (context, resolvedProps) =>
          _buildNodeWidget(context, node, resolvedProps),
    );
  }

  Widget _buildNodeWidget(
    BuildContext context,
    core.ComponentNode node,
    core.NodeProps resolvedProps,
  ) {
    if (node.isPlaceholder) {
      // The parent re-emits with the real node when the definition arrives.
      return const SizedBox.shrink();
    }
    try {
      final core.ComponentModel? model = widget.surface.componentsModel.get(
        node.componentId,
      );
      if (model == null) {
        return const SizedBox.shrink();
      }

      final JsonMap data = JsonMap.from(model.properties);
      final childByInstanceId = <String, core.ComponentNode>{};

      String adopt(core.ComponentNode child) {
        childByInstanceId[child.instanceId] = child;
        return child.instanceId;
      }

      final core.ComponentApi? api =
          widget.surface.catalog.components[node.type];
      final core.RefFields refFields = api == null
          ? core.RefFields.empty
          : core.extractRefFields(api.schema);

      for (final String key in refFields.single) {
        final Object? value = resolvedProps[key];
        if (value is core.ComponentNode) {
          data[key] = adopt(value);
        }
      }
      for (final String key in refFields.list) {
        final Object? value = resolvedProps[key];
        if (value is List) {
          data[key] = [
            for (final Object? item in value)
              if (item is core.ComponentNode) adopt(item) else item,
          ];
        }
      }
      for (final MapEntry<String, Set<String>> nested
          in refFields.nested.entries) {
        final Object? value = resolvedProps[nested.key];
        if (value is List) {
          data[nested.key] = [
            for (final Object? item in value)
              if (item is Map)
                <String, Object?>{
                  for (final MapEntry<Object?, Object?> entry in item.entries)
                    entry.key as String: entry.value is core.ComponentNode
                        ? adopt(entry.value as core.ComponentNode)
                        : entry.value,
                }
              else
                item,
          ];
        }
      }

      final dataContext = DataContext(
        _dataModel,
        DataPath(node.dataPath),
        functions: widget.catalog.functions,
      );

      return _buildCatalogWidget(
        context: context,
        componentId: node.componentId,
        type: node.type,
        data: data,
        dataContext: dataContext,
        buildChild: (String id, [DataContext? childDataContext]) {
          final core.ComponentNode? child = childByInstanceId[id];
          if (child != null) {
            return _buildNode(child);
          }
          // The schema did not mark this property as a child reference, so
          // the engine resolved no node for it; walk the raw definition the
          // way [Surface] does.
          return _buildLegacyWidget(
            context,
            id,
            childDataContext ?? dataContext,
          );
        },
      );
    } catch (exception, stackTrace) {
      _reportError(exception, stackTrace);
      return FallbackWidget(error: exception, stackTrace: stackTrace);
    }
  }

  /// The legacy fallback: renders a component and its descendants directly
  /// from the raw definitions, bypassing the node layer. Used for child
  /// references the engine could not classify from the schema.
  Widget _buildLegacyWidget(
    BuildContext context,
    String componentId,
    DataContext dataContext,
  ) {
    try {
      final core.ComponentModel? model = widget.surface.componentsModel.get(
        componentId,
      );
      if (model == null) {
        return const SizedBox.shrink();
      }
      return _buildCatalogWidget(
        context: context,
        componentId: componentId,
        type: model.type,
        data: JsonMap.from(model.properties),
        dataContext: dataContext,
        buildChild: (String id, [DataContext? childDataContext]) =>
            _buildLegacyWidget(context, id, childDataContext ?? dataContext),
      );
    } catch (exception, stackTrace) {
      _reportError(exception, stackTrace);
      return FallbackWidget(error: exception, stackTrace: stackTrace);
    }
  }

  Widget _buildCatalogWidget({
    required BuildContext context,
    required String componentId,
    required String type,
    required JsonMap data,
    required DataContext dataContext,
    required ChildBuilderCallback buildChild,
  }) {
    return widget.catalog.buildWidget(
      CatalogItemContext(
        id: componentId,
        type: type,
        data: data,
        buildChild: buildChild,
        dispatchEvent: _dispatchEvent,
        buildContext: context,
        dataContext: dataContext,
        getComponent: _getComponent,
        getCatalogItem: (String type) =>
            widget.catalog.items.firstWhereOrNull((item) => item.name == type),
        surfaceId: widget.surface.id,
        reportError: _reportError,
      ),
    );
  }

  /// Resolves both raw component ids and node instance ids (which layout
  /// views receive as children and pass back for weight lookups).
  Component? _getComponent(String id) {
    final String componentId = _instanceComponentId(id);
    final core.ComponentModel? model = widget.surface.componentsModel.get(
      componentId,
    );
    return model == null ? null : Component.fromCore(model);
  }

  /// A template-spawned instance id has the scoped data path appended
  /// (`item-card-[/items/0]`); everywhere else the instance id is the
  /// component id.
  static String _instanceComponentId(String id) {
    if (!id.endsWith(']')) {
      return id;
    }
    final int marker = id.lastIndexOf('-[');
    return marker == -1 ? id : id.substring(0, marker);
  }

  void _dispatchEvent(UiEvent event) {
    final Map<String, Object?> eventMap = {
      ...event.toMap(),
      surfaceIdKey: widget.surface.id,
    };
    final UiEvent newEvent = event.isUserAction
        ? UserActionEvent.fromMap(eventMap)
        : UiEvent.fromMap(eventMap);
    widget.onEvent(newEvent);
  }

  void _reportError(Object error, StackTrace? stackTrace) {
    if (widget.reportError != null) {
      widget.reportError!(error, stackTrace);
      return;
    }
    genUiLogger.severe(
      'Error building node surface ${widget.surface.id}',
      error,
      stackTrace,
    );
  }
}

/// Rebuilds when a [core.ReadonlySignal] emits a new value.
class _SignalBuilder<T> extends StatefulWidget {
  const _SignalBuilder({
    super.key,
    required this.signal,
    required this.builder,
  });

  final core.ReadonlySignal<T> signal;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<_SignalBuilder<T>> createState() => _SignalBuilderState<T>();
}

class _SignalBuilderState<T> extends State<_SignalBuilder<T>> {
  late T _value;
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(_SignalBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.signal, widget.signal)) {
      _unsubscribe?.call();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  void _subscribe() {
    _value = widget.signal.peek();
    // subscribe fires synchronously with the current value; the identity
    // check absorbs that first call so no setState happens during
    // initState/didUpdateWidget.
    _unsubscribe = widget.signal.subscribe((value) {
      if (identical(value, _value)) {
        return;
      }
      _value = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
