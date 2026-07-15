// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  group('Basic Catalog Validation', () {
    final Catalog mergedCatalog = BasicCatalogItems.asCatalog();

    for (final CatalogItem item in mergedCatalog.items) {
      test('CatalogItem ${item.name} examples are valid', () async {
        final List<ExampleValidationError> errors =
            await validateCatalogItemExamples(item, mergedCatalog);
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  });

  group('Catalog Validation Error Paths', () {
    test('ExampleValidationError toString', () {
      final err1 = ExampleValidationError(1, 'some error');
      expect(err1.toString(), 'Validation error in example 1: some error');

      final err2 = ExampleValidationError(2, 'some error', cause: 'some cause');
      expect(
        err2.toString(),
        'Validation error in example 2: some error\nCause: some cause',
      );
    });

    test('validateCatalogItemExamples invalid JSON', () async {
      final item = CatalogItem(
        name: 'TestItem',
        dataSchema: ObjectSchema.fromMap(const {}),
        exampleData: [() => '{invalid json'],
        widgetBuilder: (_) => const SizedBox(),
      );
      final catalog = const Catalog([]);
      final List<ExampleValidationError> errors =
          await validateCatalogItemExamples(item, catalog);
      expect(errors, hasLength(1));
      expect(errors[0].message, 'Failed to parse as a JSON list');
      expect(errors[0].cause, isA<FormatException>());
    });

    test('validateCatalogItemExamples missing root component', () async {
      final item = CatalogItem(
        name: 'TestItem',
        dataSchema: ObjectSchema.fromMap(const {}),
        exampleData: [
          () =>
              '[{"id": "not-root", "component": {"Text": {"text": "hello"}}}]',
        ],
        widgetBuilder: (_) => const SizedBox(),
      );
      final catalog = const Catalog([]);
      final List<ExampleValidationError> errors =
          await validateCatalogItemExamples(item, catalog);
      expect(errors, hasLength(1));
      expect(errors[0].message, 'Example must have a component with id "root"');
    });

    test('validateCatalogItemExamples schema validation failure', () async {
      final item = CatalogItem(
        name: 'Text',
        dataSchema: ObjectSchema.fromMap(const {}),
        // Text widget missing the text property (which is required by the
        // schema)
        exampleData: [() => '[{"id": "root", "component": {"Text": {}}}]'],
        widgetBuilder: (_) => const SizedBox(),
      );
      final Catalog catalog = BasicCatalogItems.asCatalog();
      final List<ExampleValidationError> errors =
          await validateCatalogItemExamples(item, catalog);
      expect(errors, hasLength(1));
      expect(errors[0].message, 'Schema validation failed');
      expect(errors[0].cause, isNotEmpty);
    });
  });
}
