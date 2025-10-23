// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../flutter_genui.dart' show CatalogItem;
import '../model/a2ui_message.dart';
import '../model/a2ui_schemas.dart';
import '../model/catalog.dart';
import '../model/catalog_item.dart' show CatalogItem;
import '../model/ui_models.dart';
import '../primitives/simple_items.dart';

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
  final schema = A2uiSchemas.surfaceUpdateSchema(catalog);
  final errors = <ExampleValidationError>[];

  for (var i = 0; i < item.exampleData.length; i++) {
    final exampleJsonString = item.exampleData[i]();
    final List<Object?> exampleData;
    try {
      exampleData = jsonDecode(exampleJsonString) as List<Object?>;
    } catch (e) {
      errors.add(
        ExampleValidationError(i, 'Failed to parse as a JSON list', cause: e),
      );
      continue;
    }

    final components = exampleData
        .map((e) => Component.fromJson(e as JsonMap))
        .toList();

    if (components.every((c) => c.id != 'root')) {
      errors.add(
        ExampleValidationError(
          i,
          'Example must have a component with id "root"',
        ),
      );
    }

    final surfaceUpdate = SurfaceUpdate(
      surfaceId: 'test-surface',
      components: components,
    );

    final validationErrors = await schema.validate(surfaceUpdate.toJson());
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
