// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Structural keys that describe a component's envelope rather than its API.
const Set<String> envelopeKeys = {'id', 'component'};

/// One positional parameter of a component or function signature.
class SignatureParameter {
  /// The property name this parameter fills in.
  final String name;

  /// The schema of the property.
  final Schema schema;

  /// Whether the property is required by the component or function.
  final bool isRequired;

  const SignatureParameter({
    required this.name,
    required this.schema,
    required this.isRequired,
  });

  /// The parameter rendered for a prompt signature, e.g. `variant?`.
  String get label => isRequired ? name : '$name?';

  @override
  String toString() => label;
}

/// The properties and required-property names declared by [schema].
///
/// `allOf` branches are flattened in declaration order so that a component
/// composed from shared fragments (for example the common `checks` fragment)
/// exposes one flat property list. The structural [envelopeKeys] are removed:
/// they describe the message envelope, not the component API.
({Map<String, Schema> properties, Set<String> required})
flattenSchemaProperties(Schema schema) {
  final properties = <String, Schema>{};
  final required = <String>{};

  void visit(Schema current) {
    final Object? declared = current['properties'];
    if (declared is Map) {
      for (final MapEntry<Object?, Object?> entry in declared.entries) {
        final Object? key = entry.key;
        final Object? value = entry.value;
        if (key is! String || envelopeKeys.contains(key)) continue;
        if (value is! Map) continue;
        properties.putIfAbsent(
          key,
          () => Schema.fromMap(value.cast<String, Object?>()),
        );
      }
    }

    final Object? declaredRequired = current['required'];
    if (declaredRequired is List) {
      for (final Object? name in declaredRequired) {
        if (name is String && !envelopeKeys.contains(name)) required.add(name);
      }
    }

    final Object? allOf = current['allOf'];
    if (allOf is List) {
      for (final Object? branch in allOf) {
        if (branch is Map) {
          visit(Schema.fromMap(branch.cast<String, Object?>()));
        }
      }
    }
  }

  visit(schema);
  return (properties: properties, required: required);
}

/// The positional signature of an object [schema].
///
/// Required properties come first in declaration order, followed by the
/// optional ones, also in declaration order. Keeping required parameters at
/// the front lets a compact format omit every trailing optional argument,
/// which is the whole point of a positional syntax.
///
/// Prompt generation and compilation both go through this function, so the
/// signature a model is shown is exactly the one its output is mapped against.
List<SignatureParameter> signatureOf(Schema schema) {
  final ({Map<String, Schema> properties, Set<String> required}) flat =
      flattenSchemaProperties(schema);
  return [
    for (final MapEntry<String, Schema> entry in flat.properties.entries)
      if (flat.required.contains(entry.key))
        SignatureParameter(
          name: entry.key,
          schema: entry.value,
          isRequired: true,
        ),
    for (final MapEntry<String, Schema> entry in flat.properties.entries)
      if (!flat.required.contains(entry.key))
        SignatureParameter(
          name: entry.key,
          schema: entry.value,
          isRequired: false,
        ),
  ];
}

/// The name of the A2UI common type [schema] refers to, e.g. `ComponentId`,
/// `ChildList`, `Action` or `DynamicString`.
///
/// References appear either as a JSON Schema `$ref` or, in schemas built with
/// `package:a2ui_core`, as a `REF:<pointer>|<description>` marker. Returns
/// `null` when the schema refers to no common type.
String? schemaRefName(Schema schema) {
  final Object? ref = schema[r'$ref'];
  if (ref is String) return _lastPointerSegment(ref);

  final Object? description = schema['description'];
  if (description is String && description.startsWith('REF:')) {
    return _lastPointerSegment(description.substring(4).split('|').first);
  }
  return null;
}

/// Whether [schema] accepts a plain JSON string.
///
/// Composition branches are searched, so the A2UI `DynamicString` type — a
/// string, a data binding or a function call — counts as accepting a string.
bool schemaAcceptsString(Schema schema) {
  final Object? type = schema['type'];
  if (type == 'string') return true;
  if (type is List && type.contains('string')) return true;

  for (final key in const ['anyOf', 'oneOf', 'allOf']) {
    final Object? branches = schema[key];
    if (branches is! List) continue;
    for (final Object? branch in branches) {
      if (branch is Map &&
          schemaAcceptsString(Schema.fromMap(branch.cast<String, Object?>()))) {
        return true;
      }
    }
  }
  return false;
}

/// The property names across [catalogs] whose values may be plain strings.
///
/// A streaming parser can safely auto-close a truncated string value for these
/// keys, because a partially received string is still a valid value for the
/// property. Keys whose values are numbers, objects or lists are excluded:
/// healing those would fabricate structure the model never emitted.
Set<String> progressiveStringKeys(Iterable<Catalog<ComponentApi>> catalogs) {
  final keys = <String>{};
  for (final catalog in catalogs) {
    for (final ComponentApi component in catalog.components.values) {
      final ({Map<String, Schema> properties, Set<String> required}) flat =
          flattenSchemaProperties(component.schema);
      for (final MapEntry<String, Schema> entry in flat.properties.entries) {
        if (schemaAcceptsString(entry.value)) keys.add(entry.key);
      }
    }
  }
  return Set<String>.unmodifiable(keys);
}

String _lastPointerSegment(String pointer) {
  final int index = pointer.lastIndexOf('/');
  return index < 0 ? pointer : pointer.substring(index + 1);
}
