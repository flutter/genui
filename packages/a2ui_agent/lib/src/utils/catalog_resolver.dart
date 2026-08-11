// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../primitives/errors.dart';
import '../processor/catalog_config.dart';
import '../processor/catalog_providers.dart';
import '../processor/renderer_capabilities.dart';

/// Negotiates [catalogs] against what the renderer says it supports.
///
/// Returns the transformed catalogs that are active for the session, in the
/// order they were registered. A catalog the renderer cannot render is left
/// out, so it never reaches the prompt and a model can never name a component
/// the client would fail on.
///
/// When [acceptsInlineCatalogs] is true, catalog documents the renderer sent
/// inline are loaded and appended. Leave it false unless the agent has
/// advertised that it accepts them.
///
/// Throws [A2uiCapabilityError] when nothing matches: an agent with no active
/// catalog cannot produce any UI, and failing here is far cheaper than
/// discovering it after an inference call.
List<Catalog<ComponentApi>> resolveCatalogs(
  List<CatalogConfig> catalogs,
  A2uiRendererCapabilities rendererCapabilities, {
  bool acceptsInlineCatalogs = false,
}) {
  final Set<String> supported = rendererCapabilities.supportedCatalogIds
      .toSet();
  final active = <Catalog<ComponentApi>>[
    for (final config in catalogs)
      if (supported.contains(config.id)) config.transformedCatalog,
  ];

  if (acceptsInlineCatalogs) {
    for (final Map<String, dynamic> document
        in rendererCapabilities.inlineCatalogs) {
      final Catalog<ComponentApi> catalog = InMemoryCatalogProvider(
        document,
      ).load();
      if (active.any((existing) => existing.id == catalog.id)) continue;
      active.add(catalog);
    }
  }

  if (active.isEmpty) {
    throw A2uiCapabilityError(
      'No catalog is shared between the agent and the renderer. The agent '
      'supports: ${catalogs.map((config) => config.id).join(', ')}. The '
      'renderer supports: ${supported.join(', ')}'
      '${rendererCapabilities.inlineCatalogs.isEmpty || acceptsInlineCatalogs
          ? ''
          : ' (it also sent inline catalogs, which this agent does not '
                'accept)'}'
      '.',
    );
  }
  return active;
}
