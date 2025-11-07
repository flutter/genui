// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Catalog Validation', () {
    final Catalog mergedCatalog = CoreCatalogItems.asCatalog();

    for (final CatalogItem item in mergedCatalog.items) {
      test('CatalogItem ${item.name} examples are valid', () async {
        final List<ExampleValidationError> errors =
            await validateCatalogItemExamples(item, mergedCatalog);
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  });
}
