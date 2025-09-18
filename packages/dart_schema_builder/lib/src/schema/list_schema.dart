// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../constants.dart';
import '../json_type.dart';
import 'schema.dart';

/// A JSON Schema definition for a [List].
///
/// See https://json-schema.org/understanding-json-schema/reference/array.html
///
/// ```dart
/// final schema = ListSchema(
///   items: Schema.string(),
///   minItems: 1,
///   maxItems: 5,
/// );
/// ```
extension type ListSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory ListSchema({
    // Core keywords
    String? title,
    String? description,
    // List-specific keywords
    Schema? items,
    List<Schema>? prefixItems,
    Object? unevaluatedItems,
    Schema? contains,
    int? minContains,
    int? maxContains,
    int? minItems,
    int? maxItems,
    bool? uniqueItems,
  }) => ListSchema.fromMap({
    'type': JsonType.list.typeName,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (items != null) 'items': items,
    if (prefixItems != null) 'prefixItems': prefixItems,
    if (unevaluatedItems != null) 'unevaluatedItems': unevaluatedItems,
    if (contains != null) 'contains': contains,
    if (minContains != null) 'minContains': minContains,
    if (maxContains != null) 'maxContains': maxContains,
    if (minItems != null) 'minItems': minItems,
    if (maxItems != null) 'maxItems': maxItems,
    if (uniqueItems != null) 'uniqueItems': uniqueItems,
  });

  /// The schema that all items in the list must match.
  ///
  /// If [prefixItems] is also present, this schema will only apply to items
  /// after the ones matched by [prefixItems].
  Schema? get items => schemaOrBool(kItems);

  /// A list of schemas that must match the items in the list at the same
  /// index.
  List<Object?>? get prefixItems {
    final items = _value[kPrefixItems] as List?;
    if (items == null) return null;
    return items.map((item) {
      if (item is bool) return item;
      return Schema.fromMap(item as Map<String, Object?>);
    }).toList();
  }

  /// A schema that will be applied to all items that are not matched by
  /// [items], [prefixItems], or [contains].
  Schema? get unevaluatedItems => schemaOrBool(kUnevaluatedItems);

  /// The schema that at least one item in the list must match.
  Schema? get contains => schemaOrBool(kContains);

  /// The minimum number of items that must match the [contains] schema.
  ///
  /// Defaults to 1.
  int? get minContains => (_value[kMinContains] as num?)?.toInt();

  /// The maximum number of items that can match the [contains] schema.
  int? get maxContains => (_value[kMaxContains] as num?)?.toInt();

  /// The minimum number of items that the list must have.
  int? get minItems => (_value[kMinItems] as num?)?.toInt();

  /// The maximum number of items that the list can have.
  int? get maxItems => (_value[kMaxItems] as num?)?.toInt();

  /// Whether all items in the list must be unique.
  bool? get uniqueItems => _value[kUniqueItems] as bool?;
}
