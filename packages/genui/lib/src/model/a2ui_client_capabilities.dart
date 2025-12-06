// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../primitives/simple_items.dart';

/// Describes the client's UI rendering capabilities to the server.
///
/// This class represents the `a2uiClientCapabilities` object that is sent
/// from the client to the server with each message to inform the server about
/// the component catalogs the client supports.
class A2UiClientCapabilities {
  /// Creates a new [A2UiClientCapabilities] instance.
  const A2UiClientCapabilities({
    required this.supportedCatalogIds,
    this.inlineCatalogs,
  });

  /// A list of identifiers for all pre-defined catalogs the client supports.
  ///
  /// The client MUST always include the standard catalog ID here if it
  /// supports it.
  final List<String> supportedCatalogIds;

  /// An array of full Catalog Definition Documents.
  ///
  /// This allows a client to provide custom, on-the-fly catalogs. This should
  /// only be provided if the server has advertised
  /// `acceptsInlineCatalogs: true`. This is not yet implemented.
  final List<JsonMap>? inlineCatalogs;

  /// Serializes this object to a JSON-compatible map.
  JsonMap toJson() {
    final JsonMap json = {'supportedCatalogIds': supportedCatalogIds};
    if (inlineCatalogs != null) {
      json['inlineCatalogs'] = inlineCatalogs;
    }
    return json;
  }
}
