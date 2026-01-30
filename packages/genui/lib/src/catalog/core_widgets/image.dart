// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';

Schema _schema({required bool enableUsageHint}) {
  final Map<String, Schema> properties = {
    'component': S.string(enumValues: ['Image']),
    'url': A2uiSchemas.stringReference(
      description:
          'Asset path (e.g. assets/...) or network URL (e.g. https://...)',
    ),
    'fit': S.string(
      description: 'How the image should be inscribed into the box.',
      enumValues: BoxFit.values.map((e) => e.name).toList(),
    ),
  };
  if (enableUsageHint) {
    properties['usageHint'] = S.string(
      description: '''A hint for the image size and style. One of:
      - icon: Small square icon.
      - avatar: Circular avatar image.
      - smallFeature: Small feature image.
      - mediumFeature: Medium feature image.
      - largeFeature: Large feature image.
      - header: Full-width, full bleed, header image.''',
      enumValues: [
        'icon',
        'avatar',
        'smallFeature',
        'mediumFeature',
        'largeFeature',
        'header',
      ],
    );
  }
  return S.object(properties: properties);
}

extension type _ImageData.fromMap(JsonMap _json) {
  factory _ImageData({required JsonMap url, String? fit, String? usageHint}) =>
      _ImageData.fromMap({'url': url, 'fit': fit, 'usageHint': usageHint});

  Object get url => _json['url'] as Object;
  BoxFit? get fit => _json['fit'] != null
      ? BoxFit.values.firstWhere((e) => e.name == _json['fit'] as String)
      : null;
  String? get usageHint => _json['usageHint'] as String?;
}

/// Returns a catalog item representing a widget that displays an image.
CatalogItem _imageCatalogItem({
  /// When set to `true`, the `usageHint` parameter will be included in the
  /// schema for the image widget. This allows the AI model to provide hints
  /// for the image's size and style, such as 'icon', 'avatar', or 'header'.
  /// When set to `false`, the `usageHint` parameter is omitted from the schema,
  /// preventing the model from using it.
  required bool enableUsageHint,
}) {
  return CatalogItem(
    name: 'Image',
    dataSchema: _schema(enableUsageHint: enableUsageHint),
    exampleData: [
      () => '''
      [
        {
          "id": "root",
          "component": "Image",
          "url": "https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_horizontal.c823e53b3a1a7b0d36a9.png",
          "usageHint": "mediumFeature"
        }
      ]
    ''',
    ],
    widgetBuilder: (itemContext) {
      final imageData = _ImageData.fromMap(itemContext.data as JsonMap);
      final ValueNotifier<String?> notifier = itemContext.dataContext
          .subscribeToString(imageData.url);

      return ValueListenableBuilder<String?>(
        valueListenable: notifier,
        builder: (context, currentLocation, child) {
          final location = currentLocation;
          if (location == null || location.isEmpty) {
            genUiLogger.warning(
              'Image widget created with no URL at path: '
              '${itemContext.dataContext.path}',
            );
            return const SizedBox.shrink();
          }
          final BoxFit? fit = imageData.fit;
          final String? usageHint = imageData.usageHint;

          late Widget child;

          if (location.startsWith('assets/')) {
            child = Image.asset(location, fit: fit);
          } else {
            child = Image.network(location, fit: fit);
          }

          if (usageHint == 'avatar') {
            child = CircleAvatar(child: child);
          }

          if (usageHint == 'header') {
            return SizedBox(width: double.infinity, child: child);
          }

          final double size = switch (usageHint) {
            'icon' || 'avatar' => 32.0,
            'smallFeature' => 50.0,
            'mediumFeature' => 150.0,
            'largeFeature' => 400.0,
            _ => 150.0,
          };

          return SizedBox(width: size, height: size, child: child);
        },
      );
    },
  );
}

/// A catalog item representing a widget that displays an image.
///
/// The image source is specified by the `url` parameter, which can be a network
/// URL (e.g., `https://...`) or a local asset path (e.g., `assets/...`).
///
/// ## Parameters:
///
/// - `url`: The URL of the image to display. Can be a network URL or a local
///   asset path.
/// - `fit`: How the image should be inscribed into the box. See [BoxFit] for
///   possible values.
/// - `usageHint`: A usage hint for the image size and style. One of 'icon',
///   'avatar', 'smallFeature', 'mediumFeature', 'largeFeature', 'header'.
final CatalogItem image = _imageCatalogItem(enableUsageHint: true);

/// A variant of the image catalog item which does not expose a usageHint to let
/// the LLM determine the size. Instead, it is always medium sized.
///
/// See [image] for full documentation.
final CatalogItem imageFixedSize = _imageCatalogItem(enableUsageHint: false);
