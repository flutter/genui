// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'validation_error.dart';

/// A set of annotations collected during validation.
///
/// This is used to track which properties and items have been evaluated by
/// applicator keywords.
class AnnotationSet {
  final Set<String> evaluatedKeys;
  final Set<int> evaluatedItems;

  /// Creates a new annotation set.
  AnnotationSet({Set<String>? evaluatedKeys, Set<int>? evaluatedItems})
    : evaluatedKeys = evaluatedKeys ?? {},
      evaluatedItems = evaluatedItems ?? {};

  /// Creates an empty annotation set.
  AnnotationSet.empty() : evaluatedKeys = {}, evaluatedItems = {};

  /// Merges this annotation set with another one.
  AnnotationSet merge(AnnotationSet other) {
    return AnnotationSet(
      evaluatedKeys: evaluatedKeys.union(other.evaluatedKeys),
      evaluatedItems: evaluatedItems.union(other.evaluatedItems),
    );
  }

  /// Merges this annotation set with multiple other sets.
  AnnotationSet mergeAll(Iterable<AnnotationSet> others) {
    final newKeys = Set<String>.from(evaluatedKeys);
    final newItems = Set<int>.from(evaluatedItems);
    for (final other in others) {
      newKeys.addAll(other.evaluatedKeys);
      newItems.addAll(other.evaluatedItems);
    }
    return AnnotationSet(evaluatedKeys: newKeys, evaluatedItems: newItems);
  }

  @override
  String toString() =>
      'Annotations(keys: ${evaluatedKeys.length}, '
      'items: ${evaluatedItems.length})';
}

/// The result of a validation pass.
class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final AnnotationSet annotations;

  /// Creates a new validation result.
  ValidationResult(this.isValid, List<ValidationError> errors, this.annotations)
    : errors = UnmodifiableListView(errors);

  /// Creates a successful validation result with the given [annotations].
  ValidationResult.success(this.annotations)
    : isValid = true,
      errors = const [];

  /// Creates a failed validation result with the given [errors] and
  /// [annotations].
  ValidationResult.failure(List<ValidationError> errors, this.annotations)
    : isValid = false,
      errors = UnmodifiableListView(errors);

  /// Creates a validation result from a list of [errors].
  ///
  /// The result is considered valid if the list of errors is empty.
  ValidationResult.fromErrors(List<ValidationError> errors, this.annotations)
    : isValid = errors.isEmpty,
      errors = UnmodifiableListView(errors);
}
