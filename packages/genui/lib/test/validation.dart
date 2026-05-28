// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../src/model/a2ui_schemas.dart';
import '../src/model/catalog.dart';
import '../src/model/catalog_item.dart' show CatalogItem;
import '../src/primitives/simple_items.dart';

/// A class to represent a validation error in a catalog item example.
class ExampleValidationError {
  /// The index of the example in the `exampleData` list.
  final int exampleIndex;

  /// The error message.
  final String message;

  /// The underlying cause of the error, if any.
  final Object? cause;

  /// Creates a new [ExampleValidationError].
  ExampleValidationError(this.exampleIndex, this.message, {this.cause});

  @override
  String toString() {
    var result = 'Validation error in example $exampleIndex: $message';
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }
}

/// Validates the examples for a single catalog item.
///
/// The [item] is the [CatalogItem] to validate.
/// The [catalog] is the full catalog used for context, including any
/// additional catalogs.
///
/// Returns a list of validation errors. An empty list means success.
Future<List<ExampleValidationError>> validateCatalogItemExamples(
  CatalogItem item,
  Catalog catalog,
) async {
  final Schema schema = A2uiSchemas.updateComponentsSchema(catalog);
  final errors = <ExampleValidationError>[];

  for (var i = 0; i < item.exampleData.length; i++) {
    final String exampleJsonString = item.exampleData[i]();
    final List<Object?> exampleData;
    try {
      exampleData = jsonDecode(exampleJsonString) as List<Object?>;
    } catch (e) {
      errors.add(
        ExampleValidationError(i, 'Failed to parse as a JSON list', cause: e),
      );
      continue;
    }

    final List<Map<String, Object?>> components = exampleData
        .cast<JsonMap>()
        .map(Map<String, Object?>.from)
        .toList();

    if (components.every((c) => c['id'] != 'root')) {
      errors.add(
        ExampleValidationError(
          i,
          'Example must have a component with id "root"',
        ),
      );
    }

    final surfaceUpdate = core.UpdateComponentsMessage(
      surfaceId: 'test-surface',
      components: components,
    );

    // `a2ui_core.UpdateComponentsMessage.toJson()` produces
    // `{'version': ..., 'updateComponents': {...}}`; the schema here
    // validates the body shape only.
    final List<ValidationError> validationErrors = await schema.validate(
      surfaceUpdate.toJson()['updateComponents'],
    );
    if (validationErrors.isNotEmpty) {
      errors.add(
        ExampleValidationError(
          i,
          'Schema validation failed',
          cause: validationErrors,
        ),
      );
    }
  }
  return errors;
}
