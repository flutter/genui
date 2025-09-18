// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../constants.dart';
import '../json_type.dart';
import 'schema.dart';

/// A JSON Schema definition for a String.
///
/// See https://json-schema.org/understanding-json-schema/reference/string.html
extension type const StringSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory StringSchema({
    // Core keywords
    String? title,
    String? description,
    List<Object?>? enumValues,
    Object? constValue,
    // String-specific keywords
    int? minLength,
    int? maxLength,
    String? pattern,
    String? format,
  }) => StringSchema.fromMap({
    'type': JsonType.string.typeName,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (enumValues != null) 'enum': enumValues,
    if (constValue != null) 'const': constValue,
    if (minLength != null) 'minLength': minLength,
    if (maxLength != null) 'maxLength': maxLength,
    if (pattern != null) 'pattern': pattern,
    if (format != null) 'format': format,
  });

  /// The minimum length of the string.
  int? get minLength => (_value[kMinLength] as num?)?.toInt();

  /// The maximum length of the string.
  int? get maxLength => (_value[kMaxLength] as num?)?.toInt();

  /// A regular expression that the string must match.
  String? get pattern => _value['pattern'] as String?;

  /// A pre-defined format that the string must match.
  ///
  /// See https://json-schema.org/understanding-json-schema/reference/string.html#format
  /// for a list of supported formats.
  String? get format => _value['format'] as String?;
}
