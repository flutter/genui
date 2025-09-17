// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'schema/schema.dart';
import 'schema_cache.dart';
import 'utils.dart';

class SchemaRegistry {
  final SchemaCache _schemaCache;
  final Map<Uri, Schema> _schemas = {};

  SchemaRegistry({SchemaCache? schemaCache})
    : _schemaCache = schemaCache ?? SchemaCache();

  void addSchema(Uri uri, Schema schema) {
    final uriWithoutFragment = uri.removeFragment();
    _schemas[uriWithoutFragment] = schema;
    _registerIds(schema, uriWithoutFragment);
  }

  Future<Schema?> resolve(Uri uri) async {
    final uriWithoutFragment = uri.removeFragment();
    if (_schemas.containsKey(uriWithoutFragment)) {
      return _getSchemaFromFragment(uri, _schemas[uriWithoutFragment]!);
    }

    final schema = await _schemaCache.get(uriWithoutFragment);
    if (schema == null) {
      return null;
    }
    _schemas[uriWithoutFragment] = schema;
    _registerIds(schema, uriWithoutFragment);

    return _getSchemaFromFragment(uri, schema);
  }

  Uri? getUriForSchema(Schema schema) {
    for (final entry in _schemas.entries) {
      if (deepEquals(entry.value.value, schema.value)) {
        return entry.key;
      }
    }
    return null;
  }

  void _registerIds(Schema schema, Uri baseUri) {
    final id = schema.$id;
    if (id != null) {
      // This is a heuristic to avoid re-resolving a relative path that has
      // already been applied to the base URI.
      if (id.endsWith('/') && baseUri.path.endsWith('/$id')) {
        _schemas[baseUri.removeFragment()] = schema;
      } else {
        final newUri = baseUri.resolve(id);
        _schemas[newUri.removeFragment()] = schema;
        baseUri = newUri;
      }
    }

    void recurseOnMap(Map<String, Object?> map) {
      _registerIds(Schema.fromMap(map), baseUri);
    }

    void recurseOnList(List list) {
      for (final item in list) {
        if (item is Map<String, Object?>) {
          recurseOnMap(item);
        }
      }
    }

    // Keywords with map-of-schemas values
    const mapOfSchemasKeywords = [
      'properties',
      'patternProperties',
      'dependentSchemas',
      '\$defs',
    ];
    for (final keyword in mapOfSchemasKeywords) {
      if (schema.value[keyword] case final Map map?) {
        for (final value in map.values) {
          if (value is Map<String, Object?>) {
            recurseOnMap(value);
          }
        }
      }
    }

    // Keywords with schema values
    const schemaKeywords = [
      'additionalProperties',
      'unevaluatedProperties',
      'items',
      'unevaluatedItems',
      'contains',
      'propertyNames',
      'not',
      'if',
      'then',
      'else',
    ];
    for (final keyword in schemaKeywords) {
      if (schema.value[keyword] case final Map<String, Object?> map) {
        recurseOnMap(map);
      }
    }

    // Keywords with list-of-schemas values
    const listOfSchemasKeywords = ['allOf', 'anyOf', 'oneOf', 'prefixItems'];
    for (final keyword in listOfSchemasKeywords) {
      if (schema.value[keyword] case final List list) {
        recurseOnList(list);
      }
    }
  }

  Schema? _getSchemaFromFragment(Uri uri, Schema schema) {
    if (!uri.hasFragment || uri.fragment.isEmpty) {
      return schema;
    }

    final fragment = uri.fragment;
    if (fragment.startsWith('/')) {
      return _resolveJsonPointer(schema, fragment);
    } else {
      return _findAnchor(fragment, schema);
    }
  }

  Schema? _resolveJsonPointer(Schema schema, String pointer) {
    final parts = pointer.substring(1).split('/');
    dynamic current = schema;
    for (final part in parts) {
      final decodedPart = Uri.decodeComponent(
        part,
      ).replaceAll('~1', '/').replaceAll('~0', '~');
      if (current is Schema) {
        if (!current.value.containsKey(decodedPart)) {
          return null;
        }
        current = current.value[decodedPart];
      } else if (current is Map && current.containsKey(decodedPart)) {
        current = current[decodedPart];
      } else if (current is List && int.tryParse(decodedPart) != null) {
        final index = int.parse(decodedPart);
        if (index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    if (current is Schema) {
      return current;
    } else if (current is Map) {
      return Schema.fromMap(current as Map<String, Object?>);
    } else if (current is bool) {
      return Schema.fromBoolean(current);
    }
    return null;
  }

  Schema? _findAnchor(String anchorName, Schema schema) {
    Schema? result;
    final visited = <Map<String, Object?>>{};

    void visit(dynamic current, {required bool isRootOfResource}) {
      if (result != null) return;
      if (current is Map<String, Object?>) {
        if (visited.contains(current)) return;
        visited.add(current);

        final currentSchema = Schema.fromMap(current);

        if (!isRootOfResource && currentSchema.$id != null) {
          // This is a new schema resource, so we don't look for anchors for
          // the parent resource inside it.
          return;
        }

        if (currentSchema.$anchor == anchorName ||
            currentSchema.$dynamicAnchor == anchorName) {
          result = currentSchema;
          return;
        }

        for (final value in current.values) {
          visit(value, isRootOfResource: false);
        }
      } else if (current is List) {
        for (final item in current) {
          visit(item, isRootOfResource: false);
        }
      }
    }

    visit(schema.value, isRootOfResource: true);
    return result;
  }
}
