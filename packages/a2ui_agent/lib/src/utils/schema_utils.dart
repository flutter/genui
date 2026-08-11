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
/// keys, because a prefix of the final string is still a legitimate value that
/// simply grows as more of the stream arrives.
///
/// Three kinds of string-valued property are excluded, because a prefix of
/// their value is not a weaker version of it but a wrong one:
///
/// - component references, where a truncated id points at nothing;
/// - enumerated values, where a prefix is not a member of the enum;
/// - pattern-constrained values, where a prefix need not match the pattern.
///
/// Properties holding numbers, objects or lists are excluded too: healing
/// those would fabricate structure the model never emitted.
Set<String> progressiveStringKeys(Iterable<Catalog<ComponentApi>> catalogs) {
  final keys = <String>{};
  final excluded = <String>{};
  for (final catalog in catalogs) {
    for (final ComponentApi component in catalog.components.values) {
      final ({Map<String, Schema> properties, Set<String> required}) flat =
          flattenSchemaProperties(component.schema);
      for (final MapEntry<String, Schema> entry in flat.properties.entries) {
        if (_isHealableString(entry.value)) {
          keys.add(entry.key);
        } else {
          excluded.add(entry.key);
        }
      }
    }
  }
  // A key that is unsafe in any catalog is unsafe everywhere: the streaming
  // parser heals by key name, before it knows which component it belongs to.
  return Set<String>.unmodifiable(keys.difference(excluded));
}

bool _isHealableString(Schema schema) {
  if (!schemaAcceptsString(schema)) return false;

  final String? ref = schemaRefName(schema);
  if (ref == 'ComponentId' || ref == 'ChildList') return false;

  return !_hasConstrainedString(schema);
}

/// Whether [schema] restricts strings to an enum or a pattern, in any branch.
bool _hasConstrainedString(Schema schema) {
  if (schema['enum'] != null || schema['pattern'] != null) return true;
  if (schema['const'] != null) return true;

  for (final key in const ['anyOf', 'oneOf', 'allOf']) {
    final Object? branches = schema[key];
    if (branches is! List) continue;
    for (final Object? branch in branches) {
      if (branch is Map &&
          _hasConstrainedString(
            Schema.fromMap(branch.cast<String, Object?>()),
          )) {
        return true;
      }
    }
  }
  return false;
}

String _lastPointerSegment(String pointer) {
  final int index = pointer.lastIndexOf('/');
  return index < 0 ? pointer : pointer.substring(index + 1);
}
