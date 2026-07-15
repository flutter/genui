// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

/// The `REF:` description pointers from `CommonSchemas` that mark a property
/// as referencing child components. The same convention the capabilities
/// generator resolves into wire `$ref`s, reused here as the machine-readable
/// classification source.
const String _componentIdRef = r'REF:common_types.json#/$defs/ComponentId';
const String _childListRef = r'REF:common_types.json#/$defs/ChildList';

/// Which properties of a component's schema reference child components.
class RefFields {
  /// Properties holding a single child component id.
  final Set<String> single;

  /// Properties holding a `ChildList` (static id list or template).
  final Set<String> list;

  /// Properties holding a list of plain objects in which some keys are
  /// single child references (e.g. a tab strip's `items[].child`), mapped to
  /// those keys.
  final Map<String, Set<String>> nested;

  const RefFields({
    required this.single,
    required this.list,
    required this.nested,
  });

  static const RefFields empty = RefFields(single: {}, list: {}, nested: {});
}

/// Memoized per underlying schema map ([Schema] is an extension type over
/// that map, so the map is the only stable runtime identity). A component
/// whose `schema` getter builds a fresh [Schema] per read defeats the memo,
/// so callers should read the getter once and share the instance.
final Expando<RefFields> _cache = Expando<RefFields>();

/// Derives the [RefFields] of a component schema.
///
/// Detection is by the `REF:` description pointers above, plus the same
/// structural test the binder uses for `ChildList` unions (a combinator
/// member with both `componentId` and `path` properties), so catalogs that
/// build their own child-list schema need no pointer for list properties.
RefFields extractRefFields(Schema schema) {
  final RefFields? cached = _cache[schema.value];
  if (cached != null) {
    return cached;
  }

  final Map<String, Object?> properties = _mergedProperties(
    _collectSchemas(schema.value),
  );
  if (properties.isEmpty) {
    _cache[schema.value] = RefFields.empty;
    return RefFields.empty;
  }

  final single = <String>{};
  final list = <String>{};
  final nested = <String, Set<String>>{};

  for (final MapEntry<String, Object?> entry in properties.entries) {
    final Object? value = entry.value;
    if (value is! Map) {
      continue;
    }
    final List<Map<Object?, Object?>> propertySchemas = _collectSchemas(value);
    if (_hasMarker(propertySchemas, _childListRef) ||
        propertySchemas.any(_isChildListShape)) {
      list.add(entry.key);
      continue;
    }
    if (_hasMarker(propertySchemas, _componentIdRef)) {
      single.add(entry.key);
      continue;
    }
    final Object? items = value['items'];
    if (value['type'] == 'array' && items is Map) {
      final Map<String, Object?> itemProperties = _mergedProperties(
        _collectSchemas(items),
      );
      final subKeys = <String>{};
      for (final MapEntry<String, Object?> subEntry in itemProperties.entries) {
        final Object? subValue = subEntry.value;
        if (subValue is Map &&
            _hasMarker(_collectSchemas(subValue), _componentIdRef)) {
          subKeys.add(subEntry.key);
        }
      }
      if (subKeys.isNotEmpty) {
        nested[entry.key] = subKeys;
      }
    }
  }

  final result = RefFields(single: single, list: list, nested: nested);
  _cache[schema.value] = result;
  return result;
}

/// Flattens a schema and its `allOf`/`anyOf`/`oneOf` members, mirroring the
/// binder's behavior scrape so both see the same shape.
List<Map<Object?, Object?>> _collectSchemas(Map<Object?, Object?> schema) {
  final collected = <Map<Object?, Object?>>[];
  void collect(Map<Object?, Object?> current) {
    collected.add(current);
    for (final combinator in const ['allOf', 'anyOf', 'oneOf']) {
      final Object? members = current[combinator];
      if (members is List) {
        for (final Object? member in members) {
          if (member is Map) {
            collect(member);
          }
        }
      }
    }
  }

  collect(schema);
  return collected;
}

Map<String, Object?> _mergedProperties(List<Map<Object?, Object?>> schemas) {
  final merged = <String, Object?>{};
  for (final schema in schemas) {
    final Object? properties = schema['properties'];
    if (properties is Map) {
      for (final MapEntry<Object?, Object?> entry in properties.entries) {
        merged[entry.key as String] = entry.value;
      }
    }
  }
  return merged;
}

bool _hasMarker(List<Map<Object?, Object?>> schemas, String marker) {
  return schemas.any((schema) {
    final Object? description = schema['description'];
    return description is String && description.startsWith(marker);
  });
}

/// Matches the binder's structural detection for `ChildList`-shaped schemas:
/// an object with both `componentId` and `path` properties.
bool _isChildListShape(Map<Object?, Object?> schema) {
  final Object? properties = schema['properties'];
  return properties is Map &&
      properties['componentId'] != null &&
      properties['path'] != null;
}
