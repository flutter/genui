// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart';

import '../primitives/event_notifier.dart';
import '../primitives/reactivity.dart';

final _log = Logger('a2ui_core.nodes');

/// The `type` of a node whose component definition has not arrived yet.
const String placeholderType = 'Placeholder';

/// Resolved node properties, keyed by the component's schema property names.
typedef NodeProps = Map<String, Object?>;

/// One resolved component instance in the rendered tree.
///
/// A node's [props] hold fully resolved values: primitives for dynamic
/// values, ready-to-call closures for actions, and live [ComponentNode]
/// references (or lists of them) for child properties.
///
/// Emission contract: [props] emits when this node's own resolved properties
/// change, including when a child *reference* is replaced (a placeholder
/// upgrade, a deletion, a list change). It does not emit when a child's
/// internal properties change; subscribe to the child's [props] for that.
class ComponentNode {
  /// Identifier for this node in the rendered tree. The bare component id at
  /// the root data scope; for template-spawned items the scoped data path is
  /// appended (e.g. `item-card-[/items/0]`) so sibling keys are distinct.
  ///
  /// Until the spec provides data-derived child keys (a2ui#1745), this id
  /// names a list position, not a data item: it is not stable across array
  /// insertions or reorders.
  final String instanceId;

  /// The component id from the payload.
  final String componentId;

  /// The catalog component type, or `'Placeholder'`.
  final String type;

  /// The data model scope this node resolves against, e.g. `/items/0`.
  final String dataPath;

  final Signal<NodeProps> _props;

  /// Resolved, reactive properties. Read without subscribing via `peek()`.
  ReadonlySignal<NodeProps> get props => _props;

  final _onDestroyed = EventNotifier<void>();

  /// Fires exactly once, when this node is disposed.
  EventListenable<void> get onDestroyed => _onDestroyed;

  List<void Function()> _cleanups = [];
  bool _disposed = false;

  ComponentNode(
    this.instanceId,
    this.componentId,
    this.type,
    this.dataPath,
    NodeProps initialProps,
  ) : _props = signal(initialProps);

  bool get disposed => _disposed;

  bool get isPlaceholder => type == placeholderType;

  /// Registers teardown work to run when this node is disposed.
  void addCleanup(void Function() cleanup) {
    _cleanups.add(cleanup);
  }

  /// Replaces the resolved props, emitting only if a shallow comparison shows
  /// a change. Callers keep unchanged values reference-identical (child nodes
  /// come from the resolver's cache; untouched lists keep their identity), so
  /// shallow comparison is exact rather than heuristic.
  void setProps(NodeProps next) {
    if (_disposed) {
      return;
    }
    final NodeProps previous = _props.peek();
    if (!_shallowEqual(previous, next)) {
      _props.value = next;
    }
  }

  /// Tears down this node: runs registered cleanups, then fires
  /// [onDestroyed]. Idempotent.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final void Function() cleanup in _cleanups) {
      try {
        cleanup();
      } catch (error, stackTrace) {
        // A failing cleanup must not prevent the remaining ones from running.
        _log.severe(
          'ComponentNode cleanup error ($instanceId)',
          error,
          stackTrace,
        );
      }
    }
    _cleanups = [];
    _onDestroyed.emit(null);
    _onDestroyed.dispose();
  }

  /// Serializes the resolved tree for debugging and headless assertions.
  /// Child nodes serialize recursively; action closures and setters
  /// serialize as the string `'<Action>'`.
  Map<String, Object?> toJson() {
    if (isPlaceholder) {
      return {'id': componentId, 'type': placeholderType};
    }
    final serialized = <String, Object?>{'id': componentId, 'type': type};
    for (final MapEntry<String, Object?> entry in _props.peek().entries) {
      serialized[entry.key] = _serializeValue(entry.value);
    }
    return serialized;
  }
}

/// Whether two prop values are the same by the emission gate's standards:
/// reference identity, with value equality for primitives (equal strings are
/// not always [identical], so identity alone would report equal-value
/// updates as changes).
bool sameValue(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is String && b is String) return a == b;
  if (a is num && b is num) return a == b;
  if (a is bool && b is bool) return a == b;
  return false;
}

Object? _serializeValue(Object? value) {
  if (value is ComponentNode) {
    return value.toJson();
  }
  if (value is Function) {
    return '<Action>';
  }
  if (value is List) {
    return value.map(_serializeValue).toList();
  }
  if (value is Map) {
    return <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in value.entries)
        entry.key as String: _serializeValue(entry.value),
    };
  }
  return value;
}

bool _shallowEqual(NodeProps a, NodeProps b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<String, Object?> entry in a.entries) {
    if (!b.containsKey(entry.key) || !sameValue(entry.value, b[entry.key])) {
      return false;
    }
  }
  return true;
}
