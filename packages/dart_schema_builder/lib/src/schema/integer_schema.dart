// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import '../json_type.dart';
import '../validation_error.dart';
import 'schema.dart';

/// A JSON Schema definition for an [int].
///
/// See https://json-schema.org/understanding-json-schema/reference/numeric.html#integer
///
/// ```dart
/// final schema = IntegerSchema(
///   minimum: 0,
///   maximum: 100,
/// );
/// ```
extension type IntegerSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory IntegerSchema({
    // Core keywords
    String? title,
    String? description,
    // Number-specific keywords
    int? minimum,
    int? maximum,
    int? exclusiveMinimum,
    int? exclusiveMaximum,
    num? multipleOf,
  }) => IntegerSchema.fromMap({
    'type': JsonType.int.typeName,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
    if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
    if (multipleOf != null) 'multipleOf': multipleOf,
  });

  /// The inclusive lower bound of the integer.
  int? get minimum => _value['minimum'] as int?;

  /// The inclusive upper bound of the integer.
  int? get maximum => _value['maximum'] as int?;

  /// The exclusive lower bound of the integer.
  int? get exclusiveMinimum => _value['exclusiveMinimum'] as int?;

  /// The exclusive upper bound of the integer.
  int? get exclusiveMaximum => _value['exclusiveMaximum'] as int?;

  /// The integer must be a multiple of this number.
  num? get multipleOf => _value['multipleOf'] as num?;

  void validateInteger(
    int data,
    List<String> currentPath,
    HashSet<ValidationError> accumulatedFailures,
  ) {
    if (minimum case final min? when data < min) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.minimumNotMet,
          path: currentPath,
          details: 'Value $data is less than the minimum of $min',
        ),
      );
    }
    if (maximum case final max? when data > max) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.maximumExceeded,
          path: currentPath,
          details: 'Value $data is more than the maximum of $max',
        ),
      );
    }
    if (exclusiveMinimum case final exclusiveMin? when data <= exclusiveMin) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.exclusiveMinimumNotMet,
          path: currentPath,
          details: 'Value $data is not greater than $exclusiveMin',
        ),
      );
    }
    if (exclusiveMaximum case final exclusiveMax? when data >= exclusiveMax) {
      accumulatedFailures.add(
        ValidationError(
          ValidationErrorType.exclusiveMaximumExceeded,
          path: currentPath,
          details: 'Value $data is not less than $exclusiveMax',
        ),
      );
    }
    if (multipleOf case final multOf? when multOf != 0) {
      final remainder = data / multOf;
      if (remainder.isInfinite || remainder.isNaN) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.multipleOfInvalid,
            path: currentPath,
            details: 'Value $data is not a multiple of $multOf',
          ),
        );
      } else if ((remainder - remainder.truncate()).abs() > 1e-9) {
        accumulatedFailures.add(
          ValidationError(
            ValidationErrorType.multipleOfInvalid,
            path: currentPath,
            details: 'Value $data is not a multiple of $multOf',
          ),
        );
      }
    }
  }
}
