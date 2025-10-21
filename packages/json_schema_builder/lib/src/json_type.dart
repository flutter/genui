// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The valid types for properties in a JSON schema.
enum JsonType {
  object('object'),
  list('array'),
  string('string'),
  num('number'),
  int('integer'),
  boolean('boolean'),
  nil('null');

  const JsonType(this.typeName);

  /// The name of the type as it appears in a JSON schema.
  final String typeName;
}
