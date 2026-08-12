// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../primitives/protocol_version.dart';

/// What a renderer told the agent it can render.
///
/// This is the `a2uiClientCapabilities` object a client sends with each
/// message. The agent negotiates against it to decide which catalogs are
/// active for the session.
class A2uiRendererCapabilities {
  /// The ids of the pre-defined catalogs the renderer supports.
  final List<String> supportedCatalogIds;

  /// Full catalog documents the renderer supplied inline.
  ///
  /// A renderer may only send these when the agent advertised that it accepts
  /// inline catalogs.
  final List<Map<String, dynamic>> inlineCatalogs;

  /// The protocol version the renderer declared.
  final ProtocolVersion protocolVersion;

  const A2uiRendererCapabilities({
    required this.supportedCatalogIds,
    this.inlineCatalogs = const [],
    this.protocolVersion = ProtocolVersion.current,
  });

  /// Parses capabilities from their wire form.
  ///
  /// Accepts both the version-keyed envelope a client sends —
  /// `{"v0.9": {"supportedCatalogIds": [...]}}` — and a bare capabilities
  /// object.
  factory A2uiRendererCapabilities.fromJson(Map<String, dynamic> json) {
    var body = json;
    ProtocolVersion version = ProtocolVersion.current;

    for (final MapEntry<String, dynamic> entry in json.entries) {
      final ProtocolVersion? parsed = ProtocolVersion.tryParse(entry.key);
      if (parsed != null && entry.value is Map) {
        version = parsed;
        body = (entry.value as Map).cast<String, dynamic>();
        break;
      }
    }

    final Object? ids = body['supportedCatalogIds'];
    final Object? inline = body['inlineCatalogs'];
    return A2uiRendererCapabilities(
      supportedCatalogIds: [
        if (ids is List)
          for (final Object? id in ids)
            if (id is String) id,
      ],
      inlineCatalogs: [
        if (inline is List)
          for (final Object? catalog in inline)
            if (catalog is Map) catalog.cast<String, dynamic>(),
      ],
      protocolVersion: version,
    );
  }

  /// Serializes back to the version-keyed wire form.
  Map<String, dynamic> toJson() => {
    protocolVersion.wireValue: {
      'supportedCatalogIds': supportedCatalogIds,
      if (inlineCatalogs.isNotEmpty) 'inlineCatalogs': inlineCatalogs,
    },
  };

  @override
  String toString() =>
      'A2uiRendererCapabilities(${protocolVersion.wireValue}, '
      'supported: ${supportedCatalogIds.join(', ')}, '
      'inline: ${inlineCatalogs.length})';
}
