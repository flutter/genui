// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../models/models.dart';

/// A service to validate data objects against JSON schemas defined in the
/// [WidgetCatalog].
class DataTypeValidator {
  /// Validates the given [data] against the schema defined for the [dataType].
  ///
  /// Returns `true` if the data is valid, `false` otherwise.
  Future<bool> validate({
    required String dataType,
    required Map<String, Object?> data,
    required WidgetCatalog catalog,
  }) async {
    final schemaMap = catalog.dataTypes[dataType] as Map<String, Object?>?;
    if (schemaMap == null) {
      // If the data type is not defined in the catalog, we consider it valid.
      // A stricter implementation might throw an error here.
      return true;
    }

    final schema = Schema.fromMap(schemaMap);
    final errors = await schema.validate(data, strictFormat: true);

    return errors.isEmpty;
  }
}
