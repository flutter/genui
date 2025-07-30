// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'boolean_schema.dart';
import 'constants.dart';
import 'integer_schema.dart';
import 'json_type.dart';
import 'list_schema.dart';
import 'null_schema.dart';
import 'number_schema.dart';
import 'object_schema.dart';
import 'string_schema.dart';

/// A JSON Schema object defining any kind of property.
///
/// See https://json-schema.org/draft/2020-12/json-schema-core.html for the full
/// specification.
///
/// **Note:** Only a subset of the json schema spec is supported by these types,
/// if you need something more complex you can create your own
/// `Map<String, Object?>` and cast it to [Schema] (or a subtype) directly.
extension type Schema.fromMap(Map<String, Object?> _value) {
  /// A combined schema, see
  /// https://json-schema.org/understanding-json-schema/reference/combining#schema-composition
  ///
  /// ```dart
  /// final schema = Schema.combined(
  ///   allOf: [
  ///     Schema.string(),
  ///     Schema.string(minLength: 1),
  ///   ],
  /// );
  /// ```
  factory Schema.combined({
    // Core keywords
    Object? type,
    List<Object?>? enumValues,
    Object? constValue,
    String? title,
    String? description,
    String? $comment,
    Object? defaultValue,
    List<Object?>? examples,
    bool? deprecated,
    bool? readOnly,
    bool? writeOnly,
    Map<String, Schema>? $defs,
    String? $ref,
    String? $anchor,
    String? $dynamicAnchor,
    String? $id,
    String? $schema,

    // Schema composition
    List<Object?>? allOf,
    List<Object?>? anyOf,
    List<Object?>? oneOf,
    Object? not,

    // Conditional subschemas
    Object? ifSchema,
    Object? thenSchema,
    Object? elseSchema,
    Map<String, Schema>? dependentSchemas,
  }) {
    final typeValue = switch (type) {
      JsonType() => type.typeName,
      List<JsonType>() => type.map((t) => t.typeName).toList(),
      _ => null,
    };
    return Schema.fromMap({
      if (typeValue != null) 'type': typeValue,
      if (enumValues != null) 'enum': enumValues,
      if (constValue != null) 'const': constValue,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if ($comment != null) '\$comment': $comment,
      if (defaultValue != null) 'default': defaultValue,
      if (examples != null) 'examples': examples,
      if (deprecated != null) 'deprecated': deprecated,
      if (readOnly != null) 'readOnly': readOnly,
      if (writeOnly != null) 'writeOnly': writeOnly,
      if ($defs != null) kDefs: $defs,
      if ($ref != null) kRef: $ref,
      if ($dynamicAnchor != null) kDynamicAnchor: $dynamicAnchor,
      if ($id != null) '\$id': $id,
      if ($schema != null) '\$schema': $schema,
      if (allOf != null) 'allOf': allOf,
      if (anyOf != null) 'anyOf': anyOf,
      if (oneOf != null) 'oneOf': oneOf,
      if (not != null) 'not': not,
      if (ifSchema != null) 'if': ifSchema,
      if (thenSchema != null) 'then': thenSchema,
      if (elseSchema != null) 'else': elseSchema,
      if (dependentSchemas != null) 'dependentSchemas': dependentSchemas,
    });
  }

  factory Schema.string({
    String? title,
    String? description,
    List<Object?>? enumValues,
    Object? constValue,
    int? minLength,
    int? maxLength,
    String? pattern,
    String? format,
  }) = StringSchema;

  factory Schema.boolean({String? title, String? description}) = BooleanSchema;

  factory Schema.number({
    String? title,
    String? description,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) = NumberSchema;

  factory Schema.integer({
    String? title,
    String? description,
    int? minimum,
    int? maximum,
    int? exclusiveMinimum,
    int? exclusiveMaximum,
    num? multipleOf,
  }) = IntegerSchema;

  factory Schema.list({
    String? title,
    String? description,
    Schema? items,
    List<Schema>? prefixItems,
    Object? unevaluatedItems,
    Schema? contains,
    int? minContains,
    int? maxContains,
    int? minItems,
    int? maxItems,
    bool? uniqueItems,
  }) = ListSchema;

  factory Schema.object({
    String? title,
    String? description,
    Map<String, Schema>? properties,
    Map<String, Schema>? patternProperties,
    List<String>? required,
    Map<String, List<String>>? dependentRequired,
    Object? additionalProperties,
    Object? unevaluatedProperties,
    Schema? propertyNames,
    int? minProperties,
    int? maxProperties,
  }) = ObjectSchema;

  factory Schema.nil({String? title, String? description}) = NullSchema;

  factory Schema.fromBoolean(bool value, {List<String> jsonPath = const []}) {
    return Schema.fromMap(value ? {} : {'not': {}});
  }

  Map<String, Object?> get value => _value;

  Object? operator [](String key) => _value[key];

  Schema? schemaOrBool(String key) {
    final v = _value[key];
    if (v == null) return null;
    if (v is bool) {
      return Schema.fromBoolean(v, jsonPath: [key]);
    }
    return Schema.fromMap(v as Map<String, Object?>);
  }

  Map<String, Schema>? mapToSchemaOrBool(String key) {
    final v = _value[key];
    if (v is Map) {
      return v.map((key, value) {
        if (value is bool) {
          return MapEntry(key as String, Schema.fromBoolean(value));
        }
        return MapEntry(
          key as String,
          Schema.fromMap(value as Map<String, Object?>),
        );
      });
    }
    return null;
  }

  // Core Keywords

  /// The type of the schema.
  ///
  /// This can be a [JsonType] or a [List<JsonType>].
  Object? get type => _value['type'];

  /// A list of valid values.
  List<Object?>? get enumValues => (_value['enum'] as List?)?.cast<Object?>();

  /// A constant value that the instance must be equal to.
  Object? get constValue => _value['const'];

  /// A descriptive title for the schema.
  String? get title => _value['title'] as String?;

  /// A detailed description of the schema.
  String? get description => _value['description'] as String?;

  /// A comment for the schema.
  String? get $comment => _value['\$comment'] as String?;

  /// The default value for the instance.
  Object? get defaultValue => _value['default'];

  /// A list of example values.
  List<Object?>? get examples => (_value['examples'] as List?)?.cast<Object?>();

  /// Whether the instance is deprecated.
  bool? get deprecated => _value['deprecated'] as bool?;

  /// Whether the instance is read-only.
  bool? get readOnly => _value['readOnly'] as bool?;

  /// Whether the instance is write-only.
  bool? get writeOnly => _value['writeOnly'] as bool?;

  /// A map of re-usable schemas.
  Map<String, Schema>? get $defs => mapToSchemaOrBool(kDefs);

  /// A reference to another schema.
  String? get $ref => _value[kRef] as String?;

  /// A dynamic reference to another schema.
  String? get $dynamicRef => _value[kDynamicRef] as String?;

  /// An anchor for this schema.
  String? get $anchor => _value[kAnchor] as String?;

  /// A dynamic anchor for this schema.
  String? get $dynamicAnchor => _value[kDynamicAnchor] as String?;

  /// The ID of the schema.
  String? get $id => _value['\$id'] as String?;

  /// The meta-schema for this schema.
  String? get $schema => _value['\$schema'] as String?;

  // Schema Composition

  /// The instance must be valid against all of these schemas.
  List<Object?>? get allOf => (_value['allOf'] as List?)?.cast<Object?>();

  /// The instance must be valid against at least one of these schemas.
  List<Object?>? get anyOf => (_value['anyOf'] as List?)?.cast<Object?>();

  /// The instance must be valid against exactly one of these schemas.
  List<Object?>? get oneOf => (_value['oneOf'] as List?)?.cast<Object?>();

  /// The instance must not be valid against this schema.
  Object? get not => _value['not'];

  // Conditional Subschemas

  /// If the instance is valid against this schema, then it must also be valid
  /// against [thenSchema].
  Object? get ifSchema => _value['if'];

  /// The schema that the instance must be valid against if it is valid against
  /// [ifSchema].
  Object? get thenSchema => _value['then'];

  /// The schema that the instance must be valid against if it is not valid
  /// against [ifSchema].
  Object? get elseSchema => _value['else'];

  /// A map where the keys are property names, and the values are schemas that
  /// must be valid for the object if the key is present.
  Map<String, Schema>? get dependentSchemas =>
      mapToSchemaOrBool('dependentSchemas');
}
