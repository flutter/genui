// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

/// A service responsible for loading and parsing the [WidgetCatalog].
///
/// The catalog defines the client's capabilities. This service provides
/// methods to load it from the app's bundled assets. It is typically used
/// when the catalog is a static JSON file rather than being generated
/// dynamically at runtime by a `WidgetCatalogRegistry`.
class CatalogService {
  /// Parses a [WidgetCatalog] from a raw JSON string.
  ///
  /// This can be used if the catalog is obtained from a source other than
  /// the asset bundle, such as over the network.
  ///
  /// Throws a [FormatException] if the JSON is invalid.
  WidgetCatalog parse(String jsonString) {
    final jsonMap = json.decode(jsonString) as Map<String, Object?>;
    // Add validation against the JSON schema from the FCP document.
    if (jsonMap['catalogVersion'] is! String) {
      throw const FormatException(
        'Invalid catalog: "catalogVersion" is missing or not a string.',
      );
    }
    if (jsonMap['dataTypes'] is! Map) {
      throw const FormatException(
        'Invalid catalog: "dataTypes" is missing or not a map.',
      );
    }
    if (jsonMap['items'] is! Map) {
      throw const FormatException(
        'Invalid catalog: "items" is missing or not a map.',
      );
    }
    return WidgetCatalog.fromMap(jsonMap);
  }

  /// Loads and parses the catalog from the specified asset path.
  ///
  /// The file at [assetPath] is expected to be a valid JSON file that conforms
  /// to the WidgetCatalog schema.
  Future<WidgetCatalog> loadFromAssets(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return parse(jsonString);
  }
}
