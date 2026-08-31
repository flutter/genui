// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'exceptions.dart';
import 'logging_context.dart';
import 'schema/schema.dart';
import 'schema_cache.dart';

import 'utils.dart';

/// A registry for managing and resolving JSON schemas.
///
/// This class is responsible for storing schemas, resolving `$ref` and
/// `$dynamicRef` references, and handling schema identifiers (`$id`).
class SchemaRegistry {
  final SchemaCache _schemaCache;
  final Map<Uri, Schema> _schemas = {};

  /// Creates a new schema registry.
  ///
  /// An optional [schemaCache] can be provided for fetching remote schemas.
  SchemaRegistry({SchemaCache? schemaCache, LoggingContext? loggingContext})
    : _schemaCache = schemaCache ?? SchemaCache(loggingContext: loggingContext);

  /// Adds a schema to the registry with a given [uri].
  ///
  /// The schema is stored in the registry and can be resolved later using its
  /// URI. This method also registers any `$id`s found within the schema.
  void addSchema(Uri uri, Schema schema) {
    final Uri uriWithoutFragment = uri.removeFragment();
    _schemas[uriWithoutFragment] = schema;
    _registerIds(schema, uriWithoutFragment);
  }

  /// Resolves a schema from the given [uri].
  ///
  /// If the schema is already in the registry, it is returned directly.
  /// Otherwise, it is fetched using the [SchemaCache], stored in the registry,
  /// and then returned.
  ///
  /// This method can also resolve fragments and JSON pointers within a schema.
  Future<Schema?> resolve(Uri uri) async {
    final Schema? schema = await fetch(uri);
    if (schema == null) return null;
    return _getSchemaFromFragment(uri, schema);
  }

  /// Resolves a schema from the given [uri] without performing any I/O.
  ///
  /// This behaves like [resolve], except that it only looks at the schemas this
  /// registry already holds: those added with [addSchema], and those a previous
  /// [resolve] or [fetch] call brought in.
  ///
  /// Throws a [SchemaResolutionRequiredException] if resolving [uri] would
  /// require fetching a schema that this registry does not hold.
  Schema? resolveSync(Uri uri) {
    final Uri uriWithoutFragment = uri.removeFragment();
    final Schema? schema = _schemas[uriWithoutFragment];
    if (schema == null) {
      throw SchemaResolutionRequiredException(uriWithoutFragment);
    }
    return _getSchemaFromFragment(uri, schema);
  }

  /// Fetches the schema resource that [uri] points into, ignoring any fragment,
  /// and adds it to this registry.
  ///
  /// Returns the schema, or `null` if there is none. If the registry already
  /// holds it, it is returned without any I/O. Throws a [SchemaFetchException]
  /// if the fetch fails.
  ///
  /// This is the asynchronous counterpart to [resolveSync]: it performs the
  /// I/O that [resolveSync] refuses to perform, so that a subsequent
  /// [resolveSync] of the same URI can answer from memory.
  Future<Schema?> fetch(Uri uri) async {
    final Uri uriWithoutFragment = uri.removeFragment();
    final Schema? registered = _schemas[uriWithoutFragment];
    if (registered != null) return registered;

    final Schema? schema = await _schemaCache.get(uriWithoutFragment);
    if (schema == null) return null;
    _schemas[uriWithoutFragment] = schema;
    _registerIds(schema, uriWithoutFragment);
    return schema;
  }

  /// Gets the URI for a given schema, if it has been registered.
  ///
  /// This method performs a deep comparison to find a matching schema in the
  /// registry.
  Uri? getUriForSchema(Schema schema) {
    for (final MapEntry<Uri, Schema> entry in _schemas.entries) {
      if (deepEquals(entry.value.value, schema.value)) {
        return entry.key;
      }
    }
    return null;
  }

  void dispose() {
    _schemaCache.close();
  }

  void _registerIds(Schema schema, Uri baseUri) {
    final String? id = schema.$id;
    if (id != null) {
      // This is a heuristic to avoid re-resolving a relative path that has
      // already been applied to the base URI.
      if (id.endsWith('/') && baseUri.path.endsWith('/$id')) {
        _schemas[baseUri.removeFragment()] = schema;
      } else {
        final Uri newUri = baseUri.resolve(id);
        _schemas[newUri.removeFragment()] = schema;
        baseUri = newUri;
      }
    }

    void recurseOnMap(Map<String, Object?> map) {
      _registerIds(Schema.fromMap(map), baseUri);
    }

    void recurseOnList(List<Object?> list) {
      for (final item in list) {
        if (item is Map<String, Object?>) {
          recurseOnMap(item);
        }
      }
    }

    // Keywords with map-of-schemas values
    const mapOfSchemasKeywords = <String>[
      'properties',
      'patternProperties',
      'dependentSchemas',
      '\$defs',
    ];
    for (final keyword in mapOfSchemasKeywords) {
      if (schema.value[keyword] case final Map<String, Object?> map?) {
        for (final Object? value in map.values) {
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
      if (schema.value[keyword] case final List<Object?> list) {
        recurseOnList(list);
      }
    }
  }

  Schema? _getSchemaFromFragment(Uri uri, Schema schema) {
    if (!uri.hasFragment || uri.fragment.isEmpty) {
      return schema;
    }

    final String fragment = uri.fragment;
    if (fragment.startsWith('/')) {
      return _resolveJsonPointer(schema, fragment);
    } else {
      return _findAnchor(fragment, schema);
    }
  }

  Schema? _resolveJsonPointer(Schema schema, String pointer) {
    final List<String> parts = pointer.substring(1).split('/');
    Object? current = schema;
    for (final part in parts) {
      final String decodedPart = Uri.decodeComponent(
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
        final int index = int.parse(decodedPart);
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

    void visit(Object? current, {required bool isRootOfResource}) {
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

        for (final Object? value in current.values) {
          visit(value, isRootOfResource: false);
        }
      } else if (current is List) {
        for (final Object? item in current) {
          visit(item, isRootOfResource: false);
        }
      }
    }

    visit(schema.value, isRootOfResource: true);
    return result;
  }
}
