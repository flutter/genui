// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import 'base.dart';

/// Prunes catalog component definitions down to an allowlist.
///
/// Pruning happens before the prompt is rendered, so components left out are
/// invisible to the model, and before validation, so a model that names one
/// anyway is rejected.
class ComponentPruningTransformer extends CatalogTransformer {
  /// The names of the components that survive the transformation.
  final Set<String> allowedComponents;

  ComponentPruningTransformer(Iterable<String> allowedComponents)
    : allowedComponents = Set<String>.unmodifiable(allowedComponents);

  @override
  Catalog<T> transform<T extends ComponentApi>(Catalog<T> catalog) {
    return Catalog<T>(
      id: catalog.id,
      components: [
        for (final component in catalog.components.values)
          if (allowedComponents.contains(component.name)) component,
      ],
      functions: catalog.functions.values.toList(),
      themeSchema: catalog.themeSchema,
    );
  }
}

/// Prunes catalog function definitions down to an allowlist.
///
/// Use this to restrict the client-side validation rules and logic functions a
/// model is allowed to reference.
class FunctionPruningTransformer extends CatalogTransformer {
  /// The names of the functions that survive the transformation.
  final Set<String> allowedFunctions;

  FunctionPruningTransformer(Iterable<String> allowedFunctions)
    : allowedFunctions = Set<String>.unmodifiable(allowedFunctions);

  @override
  Catalog<T> transform<T extends ComponentApi>(Catalog<T> catalog) {
    return Catalog<T>(
      id: catalog.id,
      components: catalog.components.values.toList(),
      functions: [
        for (final function in catalog.functions.values)
          if (allowedFunctions.contains(function.name)) function,
      ],
      themeSchema: catalog.themeSchema,
    );
  }
}
