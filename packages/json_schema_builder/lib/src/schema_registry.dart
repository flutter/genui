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

  /// Fetches the schema resources that [schema] refers to, and that this
  /// registry does not already hold, adding them to it.
  ///
  /// References in [schema] are resolved against [baseUri], the URI it is
  /// registered under. Whatever a fetched schema refers to in turn is fetched
  /// as well, and the resources discovered at each step are fetched in
  /// parallel. Once this completes, [resolveSync] can answer for every
  /// reference in [schema] that resolves at all, which is what
  /// `Schema.validateSync` requires.
  ///
  /// Returns the resources that could not be brought in, keyed by URI: the
  /// value is the [SchemaFetchException] the fetch failed with, or `null` if
  /// the fetch produced no schema. Such an entry is not by itself an error,
  /// because a reference that validation never reaches never has to resolve.
  Future<Map<Uri, SchemaFetchException?>> prefetchDependencies(
    Schema schema, {
    required Uri baseUri,
  }) async {
    final unresolved = <Uri, SchemaFetchException?>{};
    final seen = <Uri>{baseUri.removeFragment()};
    // The resources whose own references have not been collected yet.
    var pending = <Uri, Schema>{baseUri.removeFragment(): schema};
    while (pending.isNotEmpty) {
      final references = <Uri>{};
      for (final MapEntry<Uri, Schema> resource in pending.entries) {
        for (final Uri reference in _referencedResources(
          resource.value,
          resource.key,
        )) {
          if (seen.add(reference)) references.add(reference);
        }
      }
      // This round of references, fetched in parallel. One that the registry
      // already holds comes back without any I/O, and whatever comes back is
      // walked in the next round.
      pending = {};
      await Future.wait(
        references.map((Uri uri) async {
          try {
            final Schema? resource = await fetch(uri);
            if (resource == null) {
              unresolved[uri] = null;
            } else {
              pending[uri] = resource;
            }
          } on SchemaFetchException catch (e) {
            unresolved[uri] = e;
          }
        }),
      );
    }
    return unresolved;
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
    _walkSchema(schema, baseUri, (Schema subschema, Uri subschemaBaseUri) {
      if (subschema.$id != null) {
        _schemas[subschemaBaseUri.removeFragment()] = subschema;
      }
    });
  }

  /// The URIs of the schema resources that [schema] refers to, other than the
  /// resource it is itself part of.
  ///
  /// References are resolved against [baseUri], and against the base URI of
  /// any `$id` within [schema], exactly as validation resolves them.
  Set<Uri> _referencedResources(Schema schema, Uri baseUri) {
    final references = <Uri>{};
    _walkSchema(schema, baseUri, (Schema subschema, Uri subschemaBaseUri) {
      final Uri ownResource = subschemaBaseUri.removeFragment();
      for (final String? reference in [
        subschema.$ref,
        subschema.$dynamicRef,
        subschema.$schema,
      ]) {
        if (reference == null) continue;
        final Uri target = subschemaBaseUri.resolve(reference).removeFragment();
        if (target != ownResource) references.add(target);
      }
    });
    return references;
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

/// Calls [visit] with [schema] and every subschema of it, along with the base
/// URI that the references in that subschema resolve against.
///
/// The base URI starts as [baseUri] and changes as the walk enters a subschema
/// declaring an `$id`, exactly as it does during validation.
void _walkSchema(
  Schema schema,
  Uri baseUri,
  void Function(Schema schema, Uri baseUri) visit,
) {
  final String? id = schema.$id;
  var currentBaseUri = baseUri;
  if (id != null) {
    // This is a heuristic to avoid re-resolving a relative path that has
    // already been applied to the base URI.
    if (!(id.endsWith('/') && baseUri.path.endsWith('/$id'))) {
      currentBaseUri = baseUri.resolve(id);
    }
  }
  visit(schema, currentBaseUri);

  void recurseOnMap(Map<String, Object?> map) {
    _walkSchema(Schema.fromMap(map), currentBaseUri, visit);
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
