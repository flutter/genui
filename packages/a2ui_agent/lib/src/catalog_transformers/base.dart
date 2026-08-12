// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

/// A transformation rule applied to a catalog before prompt engineering and
/// payload validation.
///
/// Transformers are pure: they take a pristine catalog and return a modified
/// copy of the same component type, leaving the original untouched.
abstract class CatalogTransformer {
  const CatalogTransformer();

  /// Transforms [catalog] into a modified catalog of the same component type.
  Catalog<T> transform<T extends ComponentApi>(Catalog<T> catalog);
}
