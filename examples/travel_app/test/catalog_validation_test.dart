// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/test.dart';
import 'package:travel_app/src/catalog.dart';

void main() {
  group('Travel App Catalog Validation', () {
    final mergedCatalog = Catalog([
      ...travelAppCatalog.items,
      ...CoreCatalogItems.asCatalog().items,
    ]);

    for (final CatalogItem item in travelAppCatalog.items) {
      test('CatalogItem ${item.name} examples are valid', () async {
        final List<ExampleValidationError> errors =
            await validateCatalogItemExamples(item, mergedCatalog);
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  });
}
