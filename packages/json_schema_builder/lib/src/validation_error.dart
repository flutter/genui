// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Enum representing the types of validation failures when checking data
/// against a schema.
enum ValidationErrorType {
  // For custom validation.
  custom,

  // General
  typeMismatch,
  constMismatch,
  enumValueNotAllowed,
  formatInvalid,
  refResolutionError,

  // Schema combinators
  allOfNotMet,
  anyOfNotMet,
  oneOfNotMet,
  notConditionViolated,
  ifThenElseInvalid,

  // Object specific
  requiredPropertyMissing,
  dependentRequiredMissing,
  additionalPropertyNotAllowed,
  minPropertiesNotMet,
  maxPropertiesExceeded,
  propertyNamesInvalid,
  patternPropertyValueInvalid,
  unevaluatedPropertyNotAllowed,

  // Array/List specific
  minItemsNotMet,
  maxItemsExceeded,
  uniqueItemsViolated,
  containsInvalid,
  minContainsNotMet,
  maxContainsExceeded,
  itemInvalid,
  prefixItemInvalid,
  unevaluatedItemNotAllowed,

  // String specific
  minLengthNotMet,
  maxLengthExceeded,
  patternMismatch,

  // Number/Integer specific
  minimumNotMet,
  maximumExceeded,
  exclusiveMinimumNotMet,
  exclusiveMaximumExceeded,
  multipleOfInvalid,
}

/// A validation error with detailed information about the location of the
/// error.
extension type ValidationError.fromMap(Map<String, Object?> _value) {
  factory ValidationError(
    ValidationErrorType error, {
    required List<String> path,
    String? details,
  }) => ValidationError.fromMap({
    'error': error.name,
    'path': path.toList(),
    if (details != null) 'details': details,
  });

  factory ValidationError.typeMismatch({
    required List<String> path,
    required Object expectedType, // Can be String or List<String>
    required Object? actualValue,
  }) => ValidationError(
    ValidationErrorType.typeMismatch,
    path: path,
    details: 'Value `$actualValue` is not of type `$expectedType`',
  );

  /// The type of validation error that occurred.
  ValidationErrorType get error =>
      ValidationErrorType.values.firstWhere((t) => t.name == _value['error']);

  /// The path to the object that had the error.
  List<String> get path => (_value['path'] as List).cast<String>();

  /// Additional details about the error (optional).
  String? get details => _value['details'] as String?;

  String toErrorString() {
    return '${details != null ? '$details' : error.name} at path '
        '#root${path.map((p) => '["$p"]').join('')}'
        '';
  }
}
