// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../json_type.dart';
import 'schema.dart';

/// A JSON Schema definition for a [bool].
///
/// See https://json-schema.org/understanding-json-schema/reference/boolean.html
///
/// ```dart
/// final schema = BooleanSchema(
///   title: 'My Boolean',
///   description: 'A boolean value.',
/// );
/// ```
extension type BooleanSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory BooleanSchema({String? title, String? description}) =>
      BooleanSchema.fromMap({
        'type': JsonType.boolean.typeName,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      });
}
