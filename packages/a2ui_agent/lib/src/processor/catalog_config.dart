// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../catalog_transformers/base.dart';
import '../primitives/protocol_version.dart';
import 'catalog_providers.dart';

/// A catalog the agent supports, together with the rules that trim it.
///
/// The catalog itself stays pristine; [transformedCatalog] applies the
/// configured transformers, and that result is what the model is shown and
/// what its output is validated against.
class CatalogConfig {
  /// The catalog as loaded, before any transformation.
  final Catalog<ComponentApi> catalog;

  /// The transformations applied, in order, by [transformedCatalog].
  final List<CatalogTransformer> transformers;

  Catalog<ComponentApi>? _transformed;

  CatalogConfig(
    this.catalog, {
    List<CatalogTransformer> transformers = const [],
  }) : transformers = List<CatalogTransformer>.unmodifiable(transformers);

  /// Loads a catalog through [provider].
  factory CatalogConfig.fromProvider(
    CatalogProvider provider, {
    List<CatalogTransformer> transformers = const [],
  }) => CatalogConfig(provider.load(), transformers: transformers);

  /// Loads a catalog document from [catalogPath].
  factory CatalogConfig.fromPath(
    String catalogPath, {
    List<CatalogTransformer> transformers = const [],
    ProtocolVersion? protocolVersion,
    String? catalogId,
  }) => CatalogConfig(
    FileSystemCatalogProvider(
      catalogPath,
      protocolVersion: protocolVersion,
      catalogId: catalogId,
    ).load(),
    transformers: transformers,
  );

  /// The id of the underlying catalog.
  String get id => catalog.id;

  /// The catalog after every transformer has been applied, in order.
  ///
  /// Computed once and reused: transformers are pure, and the result is read
  /// on every prompt render and every validation pass.
  Catalog<ComponentApi> get transformedCatalog {
    if (_transformed != null) return _transformed!;
    Catalog<ComponentApi> current = catalog;
    for (final CatalogTransformer transformer in transformers) {
      current = transformer.transform(current);
    }
    return _transformed = current;
  }
}
