// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'package:collection/collection.dart';
import 'schema/schema.dart';
import 'validation_error.dart';

/// Performs a deep equality check on two objects.
///
/// This function can handle nested maps and lists.
final bool Function(Object? e1, Object? e2) deepEquals =
    const DeepCollectionEquality().equals;

/// Computes a deep hash code for an object.
///
/// This function can handle nested maps and lists, and is order-independent
/// for maps.
final int Function(Object? o) deepHashCode =
    const DeepCollectionEquality().hash;

/// Creates a [HashSet] for [ValidationError]s that uses deep equality.
HashSet<ValidationError> createHashSet() {
  return HashSet<ValidationError>(
    equals: (ValidationError a, ValidationError b) {
      return const ListEquality<String>().equals(a.path, b.path) &&
          a.details == b.details &&
          a.error == b.error;
    },
    hashCode: (ValidationError error) {
      return Object.hashAll([...error.path, error.details, error.error]);
    },
  );
}

/// The subschemas that [schema] holds directly, under the keywords whose
/// values are schemas.
///
/// No other value is a schema, even when it is a map: the keys of
/// `properties` are property names, and keywords such as `const`, `enum`,
/// `default` and `examples` hold instance data.
Iterable<Schema> subschemasOf(Schema schema) sync* {
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
          yield Schema.fromMap(value);
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
      yield Schema.fromMap(map);
    }
  }

  // Keywords with list-of-schemas values
  const listOfSchemasKeywords = ['allOf', 'anyOf', 'oneOf', 'prefixItems'];
  for (final keyword in listOfSchemasKeywords) {
    if (schema.value[keyword] case final List<Object?> list) {
      for (final item in list) {
        if (item is Map<String, Object?>) {
          yield Schema.fromMap(item);
        }
      }
    }
  }
}
