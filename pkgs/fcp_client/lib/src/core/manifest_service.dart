import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

/// A service responsible for loading and parsing the [WidgetLibraryManifest].
///
/// The manifest defines the client's capabilities. This service provides
/// methods to load it from the app's bundled assets.
class ManifestService {
  /// Parses a [WidgetLibraryManifest] from a raw JSON string.
  ///
  /// This can be used if the manifest is obtained from a source other than
  /// the asset bundle, such as over the network.
  ///
  /// Throws a [FormatException] if the JSON is invalid.
  WidgetLibraryManifest parse(String jsonString) {
    final jsonMap = json.decode(jsonString) as Map<String, Object?>;
    // TODO: Add validation against the JSON schema from the FCP document.
    return WidgetLibraryManifest(jsonMap);
  }

  /// Loads and parses the manifest from the specified asset path.
  ///
  /// The file at [assetPath] is expected to be a valid JSON file that conforms
  /// to the WidgetLibraryManifest schema.
  Future<WidgetLibraryManifest> loadFromAssets(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return parse(jsonString);
  }
}
