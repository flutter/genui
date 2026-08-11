// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:a2ui_core/a2ui_core.dart';

import '../primitives/protocol_version.dart';
import '../utils/catalog_document.dart';

/// Loads a catalog definition for the agent to negotiate and validate against.
abstract class CatalogProvider {
  const CatalogProvider();

  /// Loads the catalog.
  Catalog<ComponentApi> load();
}

/// Loads a catalog bundled with the SDK for a protocol version.
///
/// `package:a2ui_core` bundles the minimal catalog for `v0.9`. Other versions
/// have no bundled catalog in Dart yet, so asking for one is an error rather
/// than a silent fallback to a catalog the renderer never agreed to.
class BundledCatalogProvider extends CatalogProvider {
  /// The protocol version to load the bundled catalog for.
  final ProtocolVersion protocolVersion;

  const BundledCatalogProvider({
    this.protocolVersion = ProtocolVersion.current,
  });

  @override
  Catalog<ComponentApi> load() {
    if (protocolVersion == ProtocolVersion.v09) return MinimalCatalog();
    throw A2uiValidationError(
      'No catalog is bundled for protocol version '
      '${protocolVersion.wireValue}. package:a2ui_core bundles the minimal '
      'catalog for ${ProtocolVersion.v09.wireValue}; load other catalogs with '
      'FileSystemCatalogProvider or InMemoryCatalogProvider.',
    );
  }
}

/// Loads a catalog document from a JSON file.
///
/// This provider reads from the local filesystem and therefore only runs on
/// native platforms.
class FileSystemCatalogProvider extends CatalogProvider {
  /// The path to the catalog JSON file.
  final String path;

  /// The protocol version the document must declare, when it declares one.
  ///
  /// Catalog documents only carry `protocolVersion` from `v1.0` onwards.
  final ProtocolVersion? protocolVersion;

  /// The catalog id the document must declare, when it declares one.
  ///
  /// Catalog documents only carry `catalogId` from `v0.9` onwards; for an
  /// older document this value supplies the id instead of checking it.
  final String? catalogId;

  const FileSystemCatalogProvider(
    this.path, {
    this.protocolVersion,
    this.catalogId,
  });

  @override
  Catalog<ComponentApi> load() {
    final file = File(path);
    if (!file.existsSync()) {
      throw A2uiValidationError('Catalog file not found: $path');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (error) {
      throw A2uiValidationError(
        'Catalog file $path is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw A2uiValidationError(
        'Catalog file $path must contain a JSON object.',
      );
    }

    return catalogFromDocument(
      decoded.cast<String, dynamic>(),
      protocolVersion: protocolVersion,
      catalogId: catalogId,
      source: path,
    );
  }
}

/// Loads a catalog from an in-memory catalog document.
///
/// This is how a renderer's inline catalogs enter the agent, and the easiest
/// way to test against a catalog without touching the filesystem.
class InMemoryCatalogProvider extends CatalogProvider {
  /// The raw catalog document.
  final Map<String, dynamic> catalog;

  /// The protocol version the document must declare, when it declares one.
  final ProtocolVersion? protocolVersion;

  /// The catalog id the document must declare, when it declares one.
  final String? catalogId;

  const InMemoryCatalogProvider(
    this.catalog, {
    this.protocolVersion,
    this.catalogId,
  });

  @override
  Catalog<ComponentApi> load() => catalogFromDocument(
    catalog,
    protocolVersion: protocolVersion,
    catalogId: catalogId,
  );
}

/// Wraps an already-built [Catalog] as a provider.
///
/// Dart catalogs are usually written as code rather than loaded from JSON, so
/// this is the common case: pass `MinimalCatalog()` or your own catalog class
/// straight into a [CatalogConfig](catalog_config.dart).
class StaticCatalogProvider extends CatalogProvider {
  /// The catalog to provide.
  final Catalog<ComponentApi> catalog;

  const StaticCatalogProvider(this.catalog);

  @override
  Catalog<ComponentApi> load() => catalog;
}
