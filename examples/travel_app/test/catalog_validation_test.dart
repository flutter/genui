// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/src/catalog/core_catalog.dart';
import 'package:travel_app/src/catalog.dart';

import '../../../packages/flutter_genui/test/validation_test_utils.dart';

void main() {
  validateCatalogExamples(travelAppCatalog, [CoreCatalogItems.asCatalog()]);
}
