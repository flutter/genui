// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'package:collection/collection.dart';
import 'validation_error.dart';

/// Performs a deep equality check on two objects.
///
/// This function can handle nested maps and lists.
final deepEquals = const DeepCollectionEquality().equals;

/// Computes a deep hash code for an object.
///
/// This function can handle nested maps and lists, and is order-independent
/// for maps.
final deepHashCode = const DeepCollectionEquality().hash;

/// Creates a [HashSet] for [ValidationError]s that uses deep equality.
HashSet<ValidationError> createHashSet() {
  return HashSet<ValidationError>(
    equals: (ValidationError a, ValidationError b) {
      return const ListEquality<String>().equals(a.path, b.path) &&
          a.details == b.details &&
          a.error == b.error;
    },
    hashCode: (ValidationError error) {
      return Object.hashAll([...error.path, error.details, error.error]);
    },
  );
}
