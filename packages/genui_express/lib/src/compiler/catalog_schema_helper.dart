// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

/// Helper class that inspects active in-memory catalog schemas to map
/// positional signatures.
class CatalogSchemaHelper {
  /// The wrapped component/functions [catalog].
  final Catalog catalog;

  /// Maps component names to their properties keys list in schema order.
  final Map<String, List<String>> componentProperties = {};

  /// Maps component names to their required property keys list.
  final Map<String, List<String>> componentRequired = {};

  /// Maps component names to whether they support checks validation rules.
  final Map<String, bool> componentIsCheckable = {};

  /// Maps function names to their argument properties list.
  final Map<String, List<String>> functionProperties = {};

  /// Maps function names to their required argument keys list.
  final Map<String, List<String>> functionRequired = {};

  /// Creates a [CatalogSchemaHelper] and triggers schema parsing for [catalog].
  CatalogSchemaHelper(this.catalog) {
    _loadMappings();
  }

  /// Iterates through catalog items and functions to establish property key
  /// ordering maps.
  void _loadMappings() {
    for (final CatalogItem item in catalog.items) {
      final String name = item.name;
      final Map<String, Object?> schema = item.dataSchema.value;

      final props = <String, dynamic>{};
      final reqs = <String>[];
      var isCheckable = false;

      final subSchemas = <Map<String, dynamic>>[schema];
      if (schema.containsKey('allOf')) {
        final Object? allOf = schema['allOf'];
        if (allOf is List) {
          for (final sub in allOf) {
            if (sub is Map<String, dynamic>) {
              subSchemas.add(sub);
            }
          }
        }
      }

      for (final sub in subSchemas) {
        if (sub.containsKey(r'$ref')) {
          final ref = sub[r'$ref'] as String;
          if (ref.contains('Checkable')) {
            isCheckable = true;
          }
        }
        if (sub.containsKey('properties')) {
          final Object? p = sub['properties'];
          if (p is Map<String, dynamic>) {
            props.addAll(p);
          }
        }
        if (sub.containsKey('required')) {
          final Object? r = sub['required'];
          if (r is List) {
            reqs.addAll(r.cast<String>());
          }
        }
      }

      final orderedKeys = <String>[];
      for (final String k in props.keys) {
        if (k != 'component' && k != 'id') {
          orderedKeys.add(k);
        }
      }

      if (isCheckable) {
        orderedKeys.add('checks');
      }

      componentProperties[name] = orderedKeys;
      componentRequired[name] = reqs;
      componentIsCheckable[name] = isCheckable;
    }

    for (final ClientFunction func in catalog.functions) {
      final String name = func.name;
      final Map<String, dynamic> schema =
          func.argumentSchema.value as Map<String, dynamic>? ?? const {};
      final Map<String, dynamic> props =
          schema['properties'] as Map<String, dynamic>? ?? const {};
      final List<Object?> reqs =
          schema['required'] as List<Object?>? ?? const [];

      final orderedKeys = <String>[];
      orderedKeys.addAll(props.keys);

      final requiredKeys = <String>[];
      requiredKeys.addAll(reqs.cast<String>());

      functionProperties[name] = orderedKeys;
      functionRequired[name] = requiredKeys;
    }
  }

  /// Returns the properties list in schema declaration order for [name].
  List<String> getComponentProperties(String name) =>
      componentProperties[name] ?? const [];

  /// Returns the required property keys list for component [name].
  List<String> getComponentRequired(String name) =>
      componentRequired[name] ?? const [];

  /// Returns whether component [name] supports check validation rules.
  bool isCheckable(String name) => componentIsCheckable[name] ?? false;

  /// Returns the argument properties list in schema order for function [name].
  List<String> getFunctionProperties(String name) =>
      functionProperties[name] ?? const [];

  /// Returns the required argument keys list for function [name].
  List<String> getFunctionRequired(String name) =>
      functionRequired[name] ?? const [];
}
