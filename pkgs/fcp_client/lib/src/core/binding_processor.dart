import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'fcp_state.dart';

/// Processes bindings from a [WidgetNode] to resolve dynamic values from
/// [FcpState].
///
/// This class handles path resolution and transformations (`format`,
/// `condition`, `map`).
class BindingProcessor {
  final FcpState _state;

  /// Creates a binding processor that resolves values against the given state.
  BindingProcessor(this._state);

  /// Resolves all bindings for a given widget node against the main state.
  Map<String, Object?> process(WidgetNode node) {
    return _processBindings(node.bindings, null);
  }

  /// Resolves all bindings for a given widget node within a specific data
  /// scope.
  ///
  /// This is used for list item templates, where `item.` paths are resolved
  /// against the `scopedData` object.
  Map<String, Object?> processScoped(
    WidgetNode node,
    Map<String, Object?> scopedData,
  ) {
    return _processBindings(node.bindings, scopedData);
  }

  Map<String, Object?> _processBindings(
    Map<String, Binding>? bindings,
    Map<String, Object?>? scopedData,
  ) {
    final resolvedProperties = <String, Object?>{};
    if (bindings == null) {
      return resolvedProperties;
    }

    for (final entry in bindings.entries) {
      final propertyName = entry.key;
      final binding = entry.value;
      resolvedProperties[propertyName] = _resolveBinding(binding, scopedData);
    }

    return resolvedProperties;
  }

  Object? _resolveBinding(Binding binding, Map<String, Object?>? scopedData) {
    Object? rawValue;
    if (binding.path.startsWith('item.')) {
      // Scoped path, resolve against the item data.
      final path = binding.path.substring(5);
      rawValue = _getValueFromMap(path, scopedData);
    } else {
      // Global path, resolve against the main state.
      rawValue = _state.getValue(binding.path);
    }

    if (rawValue == null) {
      debugPrint(
        'FCP Warning: Binding path "${binding.path}" resolved to null.',
      );
      // TODO: Return a sensible default based on the property type.
      return null;
    }

    return _applyTransformation(rawValue, binding);
  }

  Object? _getValueFromMap(String path, Map<String, Object?>? map) {
    if (map == null) return null;
    // For now, we only support top-level keys in item data.
    // A more robust implementation would handle nested paths.
    return map[path];
  }

  Object? _applyTransformation(Object? value, Binding binding) {
    if (binding.format != null) {
      return binding.format!.replaceAll('{}', value?.toString() ?? '');
    }

    if (binding.condition != null) {
      final condition = binding.condition!;
      if (value == true) {
        return condition.ifValue;
      } else {
        return condition.elseValue;
      }
    }

    if (binding.map != null) {
      final map = binding.map!;
      final key = value?.toString();
      return map.mapping[key] ?? map.fallback;
    }

    return value;
  }
}
