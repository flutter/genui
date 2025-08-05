// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of a source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:characters/characters.dart';
import 'constants.dart';
import 'json_type.dart';
import 'schema.dart';
import 'validation_error.dart';

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

  void validateString(
    String data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures, {
    bool strictFormat = false,
  }) {
    if (minLength case final minLen? when data.characters.length < minLen) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minLengthNotMet,
          path: currentPath,
          details: 'String "$data" is not at least $minLen characters long',
        ),
      );
    }
    if (maxLength case final maxLen? when data.characters.length > maxLen) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maxLengthExceeded,
          path: currentPath,
          details: 'String "$data" is more than $maxLen characters long',
        ),
      );
    }
    if (pattern case final p? when !RegExp(p).hasMatch(data)) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.patternMismatch,
          path: currentPath,
          details: 'String "$data" doesn\'t match the pattern "$p"',
        ),
      );
    }
    if (strictFormat) {
      if (format case final f?) {
        final regex = _getFormatRegex(f);
        if (regex != null && !regex.hasMatch(data)) {
          accumulatedFailures.add(
            ValidationError(
              ValidationErrorType.formatInvalid,
              path: currentPath,
              details: 'String does not match format "$f"',
            ),
          );
        }
      }
    }
  }

  RegExp? _getFormatRegex(String format) {
    return switch (format) {
      'date-time' => RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
      ),
      'email' => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$'),
      'ipv4' => RegExp(
        r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.){3}(25[0-5]|(2[0-4]|1\d|[1-9]|)\d)$',
      ),
      _ => null,
    };
  }
}
