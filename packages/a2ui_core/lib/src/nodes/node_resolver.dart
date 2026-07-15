// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../core/catalog.dart';
import '../core/component_model.dart';
import '../core/contexts.dart';
import '../core/messages.dart';
import '../core/surface_model.dart';
import '../primitives/errors.dart';
import '../primitives/reactivity.dart';
import '../rendering/binder.dart';
import 'component_node.dart';
import 'ref_fields.dart';

const String _rootComponentId = 'root';
const String _rootDataPath = '/';
const String _rootEdgeKey = '>root>root@/';

class _NodeRecord {
  final ComponentNode node;
  final String edgeKey;

  /// The node whose props reference this one; null for the root.
  final ComponentNode? parent;
  final RefFields refFields;
  final ComponentModel? componentModel;
  final GenericBinder? binder;
  void Function()? binderUnsubscribe;

  /// Children this node currently references, keyed by edge. This parent
  /// owns their disposal.
  Map<String, ComponentNode> childEdges = {};

  _NodeRecord({
    required this.node,
    required this.edgeKey,
    required this.parent,
    required this.refFields,
    this.componentModel,
    this.binder,
  });
}

/// The tree engine of the node layer: turns a surface's flat component map
/// into a live tree of resolved [ComponentNode]s rooted at [rootNode]. Child
/// references become [ComponentNode] objects, template `ChildList`s spawn one
/// node per array item, not-yet-arrived components appear as placeholder
/// nodes and are upgraded in place, and every node's binder and data
/// subscriptions are torn down when its parent stops referencing it or the
/// resolver is disposed.
///
/// Construction requires the same catalog instance the surface was
/// constructed with. Resolution executes catalog functions, so it needs a
/// catalog with implementations; [Catalog] only holds
/// [FunctionImplementation]s, so every constructable catalog qualifies.
///
/// Node identity is parent-scoped: each referencing position gets its own
/// node, so one component id mounted at two positions yields two nodes and
/// dropping one position never tears down the other.
class NodeResolver<T extends ComponentApi> {
  final SurfaceModel<T> _surface;
  final Catalog<T> _catalog;

  final Signal<ComponentNode?> _rootNode = signal(null);

  /// The resolved root of the tree; null until the root component arrives.
  ReadonlySignal<ComponentNode?> get rootNode => _rootNode;

  final Map<ComponentNode, _NodeRecord> _records = {};
  final Map<String, ComponentNode> _nodesByEdge = {};
  final Map<String, Set<ComponentNode>> _nodesByComponentId = {};

  /// Parents holding a placeholder for a component id, awaiting its arrival.
  final Map<String, Set<ComponentNode>> _pendingParents = {};

  late final void Function(ComponentModel) _onCreatedListener;
  late final void Function(String) _onDeletedListener;
  _NodeRecord? _rootRecord;
  bool _disposed = false;

  NodeResolver(this._surface, this._catalog) {
    if (!identical(_catalog, _surface.catalog)) {
      throw A2uiStateError(
        'NodeResolver requires the same catalog instance its surface was '
        'constructed with.',
      );
    }
    _onCreatedListener = _onComponentCreated;
    _onDeletedListener = _onComponentDeleted;
    _surface.componentsModel.onCreated.addListener(_onCreatedListener);
    _surface.componentsModel.onDeleted.addListener(_onDeletedListener);

    if (_surface.componentsModel.get(_rootComponentId) != null) {
      _buildRoot();
    }
  }

  /// Number of live nodes (including placeholders). Exposed for tests and
  /// devtools.
  int get activeNodeCount => _records.length;

  bool get disposed => _disposed;

  /// Tears down the whole tree and stops tracking the surface. Idempotent.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _surface.componentsModel.onCreated.removeListener(_onCreatedListener);
    _surface.componentsModel.onDeleted.removeListener(_onDeletedListener);
    for (final ComponentNode node in List.of(_records.keys)) {
      _disposeNode(node);
    }
    _pendingParents.clear();
    _rootRecord = null;
    _rootNode.value = null;
  }

  void _buildRoot() {
    final ComponentNode node = _createNode(
      _rootComponentId,
      _rootDataPath,
      _rootEdgeKey,
      null,
    );
    _rootRecord = _records[node];
    _rootNode.value = node;
  }

  void _onComponentCreated(ComponentModel component) {
    if (_disposed) {
      return;
    }
    if (component.id == _rootComponentId && _rootRecord == null) {
      _buildRoot();
    }
    final Set<ComponentNode>? waiting = _pendingParents.remove(component.id);
    if (waiting != null) {
      for (final ComponentNode parent in waiting) {
        final _NodeRecord? record = _records[parent];
        if (record != null && !parent.disposed) {
          _materialize(record);
        }
      }
    }
  }

  void _onComponentDeleted(String id) {
    if (_disposed) {
      return;
    }
    final Set<ComponentNode>? affected = _nodesByComponentId[id];
    if (affected == null) {
      return;
    }
    final parentsToRefresh = <ComponentNode>{};
    var rootDeleted = false;
    for (final ComponentNode node in List.of(affected)) {
      final _NodeRecord? record = _records[node];
      if (record == null) {
        continue;
      }
      if (record.parent != null) {
        parentsToRefresh.add(record.parent!);
      } else {
        rootDeleted = true;
      }
    }
    if (rootDeleted && _rootRecord != null) {
      _disposeNode(_rootRecord!.node);
      _rootRecord = null;
      _rootNode.value = null;
    }
    for (final parent in parentsToRefresh) {
      final _NodeRecord? record = _records[parent];
      if (record != null && !parent.disposed) {
        _materialize(record);
      }
    }
  }

  /// Creates a node for one (componentId, dataPath) edge. A missing
  /// component definition yields a placeholder node and registers the parent
  /// for a refresh when the definition arrives.
  ComponentNode _createNode(
    String componentId,
    String dataPath,
    String edgeKey,
    ComponentNode? parent,
  ) {
    final ComponentModel? model = _surface.componentsModel.get(componentId);
    if (model == null) {
      final _NodeRecord record = _registerNode(
        _placeholderNode(componentId, dataPath),
        edgeKey: edgeKey,
        parent: parent,
        refFields: RefFields.empty,
      );
      if (parent != null) {
        _pendingParents.putIfAbsent(componentId, () => {}).add(parent);
      }
      return record.node;
    }

    final T? api = _catalog.components[model.type];
    if (api == null) {
      _surface.dispatchError(
        A2uiClientError(
          code: 'UNKNOWN_COMPONENT_TYPE',
          surfaceId: _surface.id,
          message:
              "Component '$componentId' has type '${model.type}', which is "
              "not in catalog '${_catalog.id}'.",
        ),
      );
      return _registerNode(
        _placeholderNode(componentId, dataPath),
        edgeKey: edgeKey,
        parent: parent,
        refFields: RefFields.empty,
      ).node;
    }

    final Schema schema = api.schema;
    final binder = GenericBinder(
      ComponentContext(_surface, model, basePath: dataPath),
      schema,
    );
    final _NodeRecord record = _registerNode(
      ComponentNode(
        _instanceIdFor(componentId, dataPath),
        componentId,
        model.type,
        dataPath,
        const {},
      ),
      edgeKey: edgeKey,
      parent: parent,
      refFields: extractRefFields(schema),
      componentModel: model,
      binder: binder,
    );
    // subscribe fires synchronously with the current value, which seeds the
    // first materialization.
    record.binderUnsubscribe = binder.resolvedProps.subscribe((_) {
      _materialize(record);
    });
    return record.node;
  }

  ComponentNode _placeholderNode(String componentId, String dataPath) {
    return ComponentNode(
      _instanceIdFor(componentId, dataPath),
      componentId,
      placeholderType,
      dataPath,
      const {},
    );
  }

  _NodeRecord _registerNode(
    ComponentNode node, {
    required String edgeKey,
    required ComponentNode? parent,
    required RefFields refFields,
    ComponentModel? componentModel,
    GenericBinder? binder,
  }) {
    final record = _NodeRecord(
      node: node,
      edgeKey: edgeKey,
      parent: parent,
      refFields: refFields,
      componentModel: componentModel,
      binder: binder,
    );
    _records[node] = record;
    _nodesByEdge[edgeKey] = node;
    _nodesByComponentId.putIfAbsent(node.componentId, () => {}).add(node);
    return record;
  }

  /// Returns the node for a child edge, reusing the cached node when the
  /// edge is unchanged and replacing it (placeholder upgrade or downgrade,
  /// id change, type change) when it is not.
  ComponentNode _childNode(
    String componentId,
    String dataPath,
    String edgeKey,
    ComponentNode parent,
  ) {
    final ComponentNode? existing = _nodesByEdge[edgeKey];
    if (_isCyclic(componentId, dataPath, parent)) {
      // Node identity is parent-scoped, so a cyclic payload would otherwise
      // recurse forever; render the repeated reference as a placeholder.
      if (existing != null && !existing.disposed && existing.isPlaceholder) {
        return existing;
      }
      if (existing != null && !existing.disposed) {
        _disposeNode(existing);
      }
      _surface.dispatchError(
        A2uiClientError(
          code: 'CYCLIC_REFERENCE',
          surfaceId: _surface.id,
          message:
              "Component '$componentId' at '$dataPath' is referenced by one "
              'of its own descendants; rendering a placeholder instead.',
        ),
      );
      return _registerNode(
        _placeholderNode(componentId, dataPath),
        edgeKey: edgeKey,
        parent: parent,
        refFields: RefFields.empty,
      ).node;
    }
    if (existing != null && !existing.disposed) {
      final ComponentModel? model = _surface.componentsModel.get(componentId);
      final T? api = model == null ? null : _catalog.components[model.type];
      // A placeholder stays up to date while its component is missing, and
      // also while the component exists but has no catalog entry; recreating
      // it cannot improve either situation.
      final bool upToDate =
          existing.componentId == componentId &&
          existing.dataPath == dataPath &&
          (existing.isPlaceholder
              ? model == null || api == null
              : model != null && existing.type == model.type);
      if (upToDate) {
        return existing;
      }
      _disposeNode(existing);
    }
    return _createNode(componentId, dataPath, edgeKey, parent);
  }

  /// True when (componentId, dataPath) already appears in the parent chain.
  bool _isCyclic(String componentId, String dataPath, ComponentNode parent) {
    for (
      ComponentNode? node = parent;
      node != null;
      node = _records[node]?.parent
    ) {
      if (node.componentId == componentId && node.dataPath == dataPath) {
        return true;
      }
    }
    return false;
  }

  /// Rebuilds a node's resolved props from its binder output: child
  /// reference properties become live [ComponentNode]s, children this parent
  /// no longer references are disposed, and unchanged values keep reference
  /// identity so the node's shallow emission gate stays exact.
  void _materialize(_NodeRecord record) {
    if (record.node.disposed) {
      return;
    }
    final Map<String, Object?> raw =
        record.binder?.resolvedProps.peek() ?? const {};
    final next = Map<String, Object?>.from(raw);
    final newEdges = <String, ComponentNode>{};

    ComponentNode resolveChild(
      String slot,
      String componentId,
      String dataPath,
    ) {
      final edgeKey = '${record.edgeKey}>$slot>$componentId@$dataPath';
      final ComponentNode child = _childNode(
        componentId,
        dataPath,
        edgeKey,
        record.node,
      );
      newEdges[edgeKey] = child;
      return child;
    }

    for (final String key in record.refFields.single) {
      final Object? value = next[key];
      if (value is String && value.isNotEmpty) {
        next[key] = resolveChild(key, value, record.node.dataPath);
      }
    }

    for (final String key in record.refFields.list) {
      final Object? value = next[key];
      if (value is! List) {
        continue;
      }
      next[key] = List<Object?>.generate(value.length, (index) {
        final Object? item = value[index];
        if (item is ChildNode) {
          return resolveChild('$key[$index]', item.id, item.basePath);
        }
        if (item is String && item.isNotEmpty) {
          return resolveChild('$key[$index]', item, record.node.dataPath);
        }
        return item;
      });
    }

    for (final MapEntry<String, Set<String>> nested
        in record.refFields.nested.entries) {
      final Object? value = next[nested.key];
      if (value is! List) {
        continue;
      }
      next[nested.key] = List<Object?>.generate(value.length, (index) {
        final Object? item = value[index];
        if (item is! Map) {
          return item;
        }
        Map<String, Object?>? resolved;
        for (final String subKey in nested.value) {
          final Object? childId = item[subKey];
          if (childId is String && childId.isNotEmpty) {
            resolved ??= Map<String, Object?>.from(item);
            resolved[subKey] = resolveChild(
              '${nested.key}[$index].$subKey',
              childId,
              record.node.dataPath,
            );
          }
        }
        return resolved ?? item;
      });
    }

    for (final MapEntry<String, ComponentNode> edge
        in record.childEdges.entries) {
      if (newEdges.containsKey(edge.key)) {
        continue;
      }
      final ComponentNode child = edge.value;
      _disposeNode(child);
      if (child.isPlaceholder) {
        final bool stillWaiting = newEdges.values.any(
          (other) =>
              other.isPlaceholder && other.componentId == child.componentId,
        );
        if (!stillWaiting) {
          _pendingParents[child.componentId]?.remove(record.node);
        }
      }
    }
    record.childEdges = newEdges;

    final NodeProps previous = record.node.props.peek();
    for (final String key in List.of(next.keys)) {
      next[key] = _stabilize(previous[key], next[key]);
    }
    record.node.setProps(next);
  }

  /// Disposes a node and, through parent-scoped ownership, its subtree.
  void _disposeNode(ComponentNode node) {
    if (node.disposed) {
      return;
    }
    final _NodeRecord? record = _records[node];
    if (record != null) {
      for (final ComponentNode child in record.childEdges.values) {
        _disposeNode(child);
      }
      record.childEdges.clear();
      record.binderUnsubscribe?.call();
      record.binderUnsubscribe = null;
      record.binder?.dispose();
      if (identical(_nodesByEdge[record.edgeKey], node)) {
        _nodesByEdge.remove(record.edgeKey);
      }
      _records.remove(node);
    }
    final Set<ComponentNode>? byId = _nodesByComponentId[node.componentId];
    if (byId != null) {
      byId.remove(node);
      if (byId.isEmpty) {
        _nodesByComponentId.remove(node.componentId);
      }
    }
    for (final Set<ComponentNode> waiting in _pendingParents.values) {
      waiting.remove(node);
    }
    node.dispose();
  }
}

String _instanceIdFor(String componentId, String dataPath) {
  if (dataPath == _rootDataPath) {
    return componentId;
  }
  String trimmed = dataPath.replaceAll(RegExp(r'/+$'), '');
  if (trimmed.isEmpty) {
    trimmed = _rootDataPath;
  }
  return '$componentId-[$trimmed]';
}

/// Returns `prev` whenever `next` is structurally identical to it, so
/// unchanged props keep reference identity across rebuilds. Child
/// [ComponentNode]s, action closures, and other non-container objects
/// compare by identity.
Object? _stabilize(Object? prev, Object? next) {
  if (sameValue(prev, next)) {
    return next;
  }
  if (prev is ComponentNode || next is ComponentNode) {
    return next;
  }
  if (prev is List && next is List && prev.length == next.length) {
    var allSame = true;
    final out = List<Object?>.generate(next.length, (index) {
      final Object? stabilized = _stabilize(prev[index], next[index]);
      if (!sameValue(stabilized, prev[index])) {
        allSame = false;
      }
      return stabilized;
    });
    return allSame ? prev : out;
  }
  if (prev is Map && next is Map && prev.length == next.length) {
    var allSame = true;
    final out = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in next.entries) {
      final key = entry.key as String;
      final Object? stabilized = _stabilize(prev[key], entry.value);
      out[key] = stabilized;
      if (!prev.containsKey(key) || !sameValue(stabilized, prev[key])) {
        allSame = false;
      }
    }
    return allSame ? prev : out;
  }
  return next;
}
