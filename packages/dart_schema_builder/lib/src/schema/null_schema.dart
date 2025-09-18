// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../json_type.dart';
import 'schema.dart';

/// A JSON Schema definition for `null`.
///
/// See https://json-schema.org/understanding-json-schema/reference/null.html
///
/// ```dart
/// final schema = NullSchema();
/// ```
extension type NullSchema.fromMap(Map<String, Object?> _value)
    implements Schema {
  factory NullSchema({String? title, String? description}) =>
      NullSchema.fromMap({
        'type': JsonType.nil.typeName,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      });
}
