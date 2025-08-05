// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'fcp_state.dart';

/// Processes bindings from a [LayoutNode] to resolve dynamic values from
/// [FcpState].
///
/// This class handles path resolution and transformations (`format`,
/// `condition`, `map`).
class BindingProcessor {
  final FcpState _state;

  /// Creates a binding processor that resolves values against the given state.
  BindingProcessor(this._state);

  /// Resolves all bindings for a given layout node against the main state.
  Map<String, Object?> process(LayoutNode node) {
    final itemDefJson = _state.catalog.items[node.type];
    if (itemDefJson == null) {
      // It's valid for a widget to not have a definition, in which case
      // it has no properties that can be bound.
      return const {};
    }
    final itemDef = WidgetDefinition(itemDefJson as Map<String, Object?>);
    return _processBindings(node.bindings, itemDef, null);
  }

  /// Resolves all bindings for a given layout node within a specific data
  /// scope.
  ///
  /// This is used for list item templates, where `item.` paths are resolved
  /// against the `scopedData` object.
  Map<String, Object?> processScoped(
    LayoutNode node,
    Map<String, Object?> scopedData,
  ) {
    final itemDefJson = _state.catalog.items[node.type];
    if (itemDefJson == null) {
      // It's valid for a widget to not have a definition, in which case
      // it has no properties that can be bound.
      return const {};
    }
    final itemDef = WidgetDefinition(itemDefJson as Map<String, Object?>);
    return _processBindings(node.bindings, itemDef, scopedData);
  }

  Map<String, Object?> _processBindings(
    Map<String, Binding>? bindings,
    WidgetDefinition itemDef,
    Map<String, Object?>? scopedData,
  ) {
    final resolvedProperties = <String, Object?>{};
    if (bindings == null) {
      return resolvedProperties;
    }

    for (final entry in bindings.entries) {
      final propertyName = entry.key;
      final binding = entry.value;
      resolvedProperties[propertyName] = _resolveBinding(
        binding,
        propertyName,
        itemDef,
        scopedData,
      );
    }

    return resolvedProperties;
  }

  Object? _resolveBinding(
    Binding binding,
    String propertyName,
    WidgetDefinition itemDef,
    Map<String, Object?>? scopedData,
  ) {
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
      final propDefMap = itemDef.properties[propertyName];
      if (propDefMap != null) {
        final propDef = PropertyDefinition(propDefMap as Map<String, Object?>);
        return _getDefaultValueForType(propDef.type);
      }
      return null;
    }

    return _applyTransformation(rawValue, binding);
  }

  Object? _getValueFromMap(String path, Map<String, Object?>? map) {
    if (map == null) return null;
    final parts = path.split('.');
    Object? currentValue = map;
    for (final part in parts) {
      if (currentValue is Map<String, Object?>) {
        currentValue = currentValue[part];
      } else {
        return null;
      }
    }
    return currentValue;
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

  Object? _getDefaultValueForType(String type) {
    switch (type) {
      case 'String':
        return '';
      case 'int':
        return 0;
      case 'double':
        return 0.0;
      case 'bool':
        return false;
      case 'List':
        return [];
      default:
        return null;
    }
  }
}
