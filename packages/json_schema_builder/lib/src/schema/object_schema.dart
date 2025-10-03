// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../constants.dart';
import '../json_type.dart';
import 'schema.dart';

/// A JSON Schema definition for an object with properties.
///
/// See https://json-schema.org/understanding-json-schema/reference/object.html
///
/// ```dart
/// final schema = ObjectSchema(
///   properties: {
///     'name': Schema.string(),
///     'email': Schema.string(format: 'email'),
///   },
///   required: ['name', 'email'],
/// );
/// ```
extension type ObjectSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory ObjectSchema({
    // Core keywords
    String? title,
    String? description,
    // Object-specific keywords
    Map<String, Schema>? properties,
    Map<String, Schema>? patternProperties,
    List<String>? required,
    Map<String, List<String>>? dependentRequired,
    Object? additionalProperties,
    Object? unevaluatedProperties,
    Schema? propertyNames,
    int? minProperties,
    int? maxProperties,
  }) => ObjectSchema.fromMap({
    'type': JsonType.object.typeName,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (properties != null) 'properties': properties,
    if (patternProperties != null) 'patternProperties': patternProperties,
    if (required != null) 'required': required,
    if (dependentRequired != null) 'dependentRequired': dependentRequired,
    if (additionalProperties != null)
      'additionalProperties': additionalProperties,
    if (unevaluatedProperties != null)
      'unevaluatedProperties': unevaluatedProperties,
    if (propertyNames != null) 'propertyNames': propertyNames,
    if (minProperties != null) 'minProperties': minProperties,
    if (maxProperties != null) 'maxProperties': maxProperties,
  });

  /// A map of property names to schemas.
  Map<String, Schema>? get properties => mapToSchemaOrBool(kProperties);

  /// A map of regular expression patterns to schemas.
  ///
  /// If a property name in the instance matches a regular expression in this
  /// map, the corresponding schema will be applied to the property value.
  Map<String, Schema>? get patternProperties =>
      mapToSchemaOrBool(kPatternProperties);

  /// A list of property names that must be present in the object.
  List<String>? get required => (_value[kRequired] as List?)?.cast<String>();

  /// A map where the keys are property names, and the values are a list of
  /// property names that must be present in the object if the key is present.
  Map<String, List<String>>? get dependentRequired {
    final value = _value[kDependentRequired];
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key as String, (value as List).cast<String>()),
      );
    }
    return null;
  }

  /// A map where the keys are property names, and the values are schemas that
  /// must be valid for the object if the key is present.
  Map<String, Schema>? get dependentSchemas =>
      mapToSchemaOrBool(kDependentSchemas);

  /// A schema that will be applied to all properties that are not matched by
  /// [properties] or [patternProperties].
  Schema? get additionalProperties => schemaOrBool(kAdditionalProperties);

  /// A schema that will be applied to all properties that are not matched by
  /// [properties], [patternProperties], or [additionalProperties].
  Schema? get unevaluatedProperties => schemaOrBool(kUnevaluatedProperties);

  /// A schema that all property names in the object must match.
  Schema? get propertyNames => schemaOrBool(kPropertyNames);

  /// The minimum number of properties that the object must have.
  int? get minProperties => (_value[kMinProperties] as num?)?.toInt();

  /// The maximum number of properties that the object can have.
  int? get maxProperties => (_value[kMaxProperties] as num?)?.toInt();
}
