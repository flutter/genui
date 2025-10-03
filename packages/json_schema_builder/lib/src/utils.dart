// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'package:collection/collection.dart';
import 'validation_error.dart';

bool deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  } else if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

int deepHashCode(Object? o) {
  if (o == null) return 0;
  if (o is Map) {
    // Order-independent hash for maps
    if (o.isEmpty) return 0;
    return o.entries
        .map((e) => Object.hash(deepHashCode(e.key), deepHashCode(e.value)))
        .fold(0, (value, element) => value ^ element);
  }
  if (o is List) {
    return Object.hashAll(o.map(deepHashCode));
  }
  return o.hashCode;
}

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
