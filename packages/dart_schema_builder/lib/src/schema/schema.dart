// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../constants.dart';
import '../json_type.dart';
import 'boolean_schema.dart';
import 'integer_schema.dart';
import 'list_schema.dart';
import 'null_schema.dart';
import 'number_schema.dart';
import 'object_schema.dart';
import 'string_schema.dart';

// A shortcut typedef so that we can use S.object, etc.
typedef S = Schema;

/// A JSON Schema object defining any kind of property.
///
/// See https://json-schema.org/draft/2020-12/json-schema-core.html for the full
/// specification.
///
/// **Note:** Only a subset of the json schema spec is supported by these types,
/// if you need something more complex you can create your own
/// `Map<String, Object?>` and cast it to [Schema] (or a subtype) directly.
extension type Schema.fromMap(Map<String, Object?> _value) {
  /// Creates a combined schema.
  ///
  /// This constructor is used for creating complex schemas that combine other
  /// schemas using composition keywords like `allOf`, `anyOf`, `oneOf`, and
  /// conditional subschemas. It also allows setting various core metadata
  /// keywords.
  ///
  /// See https://json-schema.org/understanding-json-schema/reference/combining#schema-composition
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

  /// Creates a JSON Schema definition for a [String].
  ///
  /// See also:
  ///
  /// * [StringSchema] for the class that this factory constructor delegates to.
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

  /// Creates a JSON Schema definition for a [bool].
  ///
  /// See also:
  ///
  /// * [BooleanSchema] for the class that this factory constructor delegates
  ///   to.
  factory Schema.boolean({String? title, String? description}) = BooleanSchema;

  /// Creates a JSON Schema definition for a [num].
  ///
  /// See also:
  ///
  /// * [NumberSchema] for the class that this factory constructor delegates to.
  factory Schema.number({
    String? title,
    String? description,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) = NumberSchema;

  /// Creates a JSON Schema definition for an [int].
  ///
  /// See also:
  ///
  /// * [IntegerSchema] for the class that this factory constructor delegates
  ///   to.
  factory Schema.integer({
    String? title,
    String? description,
    int? minimum,
    int? maximum,
    int? exclusiveMinimum,
    int? exclusiveMaximum,
    num? multipleOf,
  }) = IntegerSchema;

  /// Creates a JSON Schema definition for a [List].
  ///
  /// See also:
  ///
  /// * [ListSchema] for the class that this factory constructor delegates to.
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

  /// Creates a JSON Schema definition for an object with properties.
  ///
  /// See also:
  ///
  /// * [ObjectSchema] for the class that this factory constructor delegates to.
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

  /// Creates a JSON Schema definition for `null`.
  ///
  /// See also:
  ///
  ///  * [NullSchema] for the class that this factory constructor delegates to.
  factory Schema.nil({String? title, String? description}) = NullSchema;

  /// Creates a JSON schema definition for any value.
  factory Schema.any({String? title, String? description}) => Schema.fromMap({
    if (title != null) 'title': title,
    if (description != null) 'description': description,
  });

  /// Creates a schema from a boolean value.
  ///
  /// A `true` value creates a schema that allows any value, while a `false`
  /// value creates a schema that allows no values.
  factory Schema.fromBoolean(bool value, {List<String> jsonPath = const []}) {
    return Schema.fromMap(value ? {} : {'not': {}});
  }

  /// The underlying map representation of the schema.
  Map<String, Object?> get value => _value;

  /// Gets the value of a keyword from the schema map.
  Object? operator [](String key) => _value[key];

  /// Retrieves a subschema for a given keyword, handling boolean schemas.
  ///
  /// Some keywords in JSON Schema can be a schema object or a boolean. This
  /// method correctly interprets a boolean as a valid subschema.
  Schema? schemaOrBool(String key) {
    final v = _value[key];
    if (v == null) return null;
    if (v is bool) {
      return Schema.fromBoolean(v, jsonPath: [key]);
    }
    return Schema.fromMap(v as Map<String, Object?>);
  }

  /// Retrieves a map of property names to schemas, handling boolean schemas.
  ///
  /// This is used for keywords like `properties` where the value is a map of
  /// schemas, and those schemas themselves can be boolean values.
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

  /// The type of the data that this schema defines.
  ///
  /// The value can be a string representing a single [JsonType], or a list of
  /// strings if the data can be one of multiple types.
  Object? get type => _value['type'];

  /// A list of valid values for an instance.
  ///
  /// The instance is valid if its value is deeply equal to one of the values
  /// in this array.
  List<Object?>? get enumValues => (_value['enum'] as List?)?.cast<Object?>();

  /// A constant value that the instance must be equal to.
  Object? get constValue => _value['const'];

  /// A descriptive title for the schema.
  String? get title => _value['title'] as String?;

  /// A detailed description of the schema.
  String? get description => _value['description'] as String?;

  /// A comment for the schema.
  ///
  /// This keyword is intended for adding comments to a schema and has no
  /// validation effect.
  String? get $comment => _value['\$comment'] as String?;

  /// The default value for the instance.
  ///
  /// This keyword does not affect validation but can be used by applications
  /// to provide a default value.
  Object? get defaultValue => _value['default'];

  /// A list of example values.
  ///
  /// This keyword is for documentation purposes and does not affect
  /// validation.
  List<Object?>? get examples => (_value['examples'] as List?)?.cast<Object?>();

  /// Indicates whether the instance is deprecated.
  ///
  /// This keyword does not affect validation but can be used by tools to
  /// signal that a property is deprecated.
  bool? get deprecated => _value['deprecated'] as bool?;

  /// Indicates whether the instance is read-only.
  ///
  /// This keyword does not affect validation but can be used by applications
  /// to control write access to a property.
  bool? get readOnly => _value['readOnly'] as bool?;

  /// Indicates whether the instance is write-only.
  ///
  /// This keyword does not affect validation but can be used by applications
  /// to control read access to a property.
  bool? get writeOnly => _value['writeOnly'] as bool?;

  /// A map of re-usable schemas.
  ///
  /// This keyword provides a set of schema definitions that can be referenced
  /// from elsewhere in the same schema document.
  Map<String, Schema>? get $defs => mapToSchemaOrBool(kDefs);

  /// A reference to another schema.
  ///
  /// This allows for the re-use of schemas. The value is a URI-reference that
  /// resolves to a schema.
  String? get $ref => _value[kRef] as String?;

  /// A dynamic reference to another schema.
  ///
  /// This works with `$dynamicAnchor` to allow for dynamic resolution of
  /// references in extended schemas.
  String? get $dynamicRef => _value[kDynamicRef] as String?;

  /// An anchor for this schema.
  ///
  /// This allows a schema to be identified by a plain name fragment, which can
  /// then be used in a URI to reference this schema.
  String? get $anchor => _value[kAnchor] as String?;

  /// A dynamic anchor for this schema.
  ///
  /// This works with `$dynamicRef` to allow for dynamic extension of schemas.
  String? get $dynamicAnchor => _value[kDynamicAnchor] as String?;

  /// The ID of the schema.
  ///
  /// This sets a base URI for the schema, which affects how `$ref` references
  /// are resolved.
  String? get $id => _value['\$id'] as String?;

  /// The meta-schema for this schema.
  ///
  /// This specifies the URI of the dialect of JSON Schema that this schema is
  /// written in.
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
  ///
  /// If the instance is not valid against this schema, it must be valid
  /// against [elseSchema], if present.
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
