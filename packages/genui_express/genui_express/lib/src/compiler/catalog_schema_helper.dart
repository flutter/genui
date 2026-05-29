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

  /// Maps component names to their top-level description.
  final Map<String, String> componentDescription = {};

  /// Maps component names to their property descriptions.
  final Map<String, Map<String, String>> propertyDescriptions = {};

  /// Maps function names to their argument properties list.
  final Map<String, List<String>> functionProperties = {};

  /// Maps function names to their required argument keys list.
  final Map<String, List<String>> functionRequired = {};

  /// Maps function names to their description.
  final Map<String, String> functionDescription = {};

  /// Maps function names to their argument descriptions.
  final Map<String, Map<String, String>> functionArgumentDescriptions = {};

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

      final props = <String, Object?>{};
      final reqs = <String>[];
      var isCheckable = false;

      final String itemDesc = schema['description'] as String? ?? '';
      componentDescription[name] = itemDesc;

      final subSchemas = <Map<String, Object?>>[schema];
      if (schema.containsKey('allOf')) {
        final Object? allOf = schema['allOf'];
        if (allOf is List) {
          for (final Object? sub in allOf) {
            if (sub is Map<String, Object?>) {
              subSchemas.add(sub);
            }
          }
        }
      }

      final propDescs = <String, String>{};
      for (final sub in subSchemas) {
        if (sub.containsKey(r'$ref')) {
          final ref = sub[r'$ref'] as String;
          if (ref.contains('Checkable')) {
            isCheckable = true;
          }
        }
        if (sub.containsKey('properties')) {
          final Object? p = sub['properties'];
          if (p is Map<String, Object?>) {
            props.addAll(p);
            for (final MapEntry<String, Object?> entry in p.entries) {
              final Object? propVal = entry.value;
              if (propVal is Map<String, Object?>) {
                final String pDesc = propVal['description'] as String? ?? '';
                if (pDesc.isNotEmpty) {
                  propDescs[entry.key] = pDesc;
                }
              }
            }
          }
        }
        if (sub.containsKey('required')) {
          final Object? r = sub['required'];
          if (r is List) {
            reqs.addAll(r.cast<String>());
          }
        }
      }

      propertyDescriptions[name] = propDescs;

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
      final Map<String, Object?> schema =
          func.argumentSchema.value as Map<String, Object?>? ?? const {};
      final Map<String, Object?> props =
          schema['properties'] as Map<String, Object?>? ?? const {};
      final List<Object?> reqs =
          schema['required'] as List<Object?>? ?? const [];

      final String funcDesc = schema['description'] as String? ?? '';
      functionDescription[name] = funcDesc;

      final argDescs = <String, String>{};
      for (final MapEntry<String, Object?> entry in props.entries) {
        final Object? argVal = entry.value;
        if (argVal is Map<String, Object?>) {
          final String aDesc = argVal['description'] as String? ?? '';
          if (aDesc.isNotEmpty) {
            argDescs[entry.key] = aDesc;
          }
        }
      }
      functionArgumentDescriptions[name] = argDescs;

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

  /// Returns the top-level description for component [name].
  String getComponentDescription(String name) =>
      componentDescription[name] ?? '';

  /// Returns the property descriptions map for component [name].
  Map<String, String> getPropertyDescriptions(String name) =>
      propertyDescriptions[name] ?? const {};

  /// Returns the argument properties list in schema order for function [name].
  List<String> getFunctionProperties(String name) =>
      functionProperties[name] ?? const [];

  /// Returns the required argument keys list for function [name].
  List<String> getFunctionRequired(String name) =>
      functionRequired[name] ?? const [];

  /// Returns the top-level description for function [name].
  String getFunctionDescription(String name) => functionDescription[name] ?? '';

  /// Returns the argument descriptions map for function [name].
  Map<String, String> getFunctionArgumentDescriptions(String name) =>
      functionArgumentDescriptions[name] ?? const {};
}
