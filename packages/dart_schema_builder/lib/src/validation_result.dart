// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'validation_error.dart';

class AnnotationSet {
  final Set<String> evaluatedKeys;
  final Set<int> evaluatedItems;

  AnnotationSet({Set<String>? evaluatedKeys, Set<int>? evaluatedItems})
    : evaluatedKeys = evaluatedKeys ?? {},
      evaluatedItems = evaluatedItems ?? {};

  AnnotationSet.empty() : evaluatedKeys = {}, evaluatedItems = {};

  AnnotationSet merge(AnnotationSet other) {
    return AnnotationSet(
      evaluatedKeys: evaluatedKeys.union(other.evaluatedKeys),
      evaluatedItems: evaluatedItems.union(other.evaluatedItems),
    );
  }

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

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final AnnotationSet annotations;

  ValidationResult(this.isValid, List<ValidationError> errors, this.annotations)
    : errors = UnmodifiableListView(errors);

  ValidationResult.success(this.annotations)
    : isValid = true,
      errors = const [];

  ValidationResult.failure(List<ValidationError> errors, this.annotations)
    : isValid = false,
      errors = UnmodifiableListView(errors);

  ValidationResult.fromErrors(List<ValidationError> errors, this.annotations)
    : isValid = errors.isEmpty,
      errors = UnmodifiableListView(errors);
}
