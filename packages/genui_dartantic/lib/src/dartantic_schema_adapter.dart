// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema/json_schema.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

/// Converts a [jsb.Schema] from the `json_schema_builder` package to a
/// [JsonSchema] from the `json_schema` package.
///
/// This is a simple pass-through conversion since both packages represent
/// JSON Schema - the dartantic provider handles any provider-specific
/// limitations.
JsonSchema? adaptSchema(jsb.Schema? schema) {
  if (schema == null) return null;
  return JsonSchema.create(schema.value);
}
