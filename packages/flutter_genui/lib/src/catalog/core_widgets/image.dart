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

final _schema = S.object(
  properties: {
    'url': A2uiSchemas.stringReference(
      description:
          'Asset path (e.g. assets/...) or network URL (e.g. https://...)',
    ),
    'fit': S.string(
      description: 'How the image should be inscribed into the box.',
      enumValues: BoxFit.values.map((e) => e.name).toList(),
    ),
    'hint': S.string(
      description: 'A hint for the image size and style.',
      enumValues: [
        'icon',
        'avatar',
        'smallFeature',
        'mediumFeature',
        'largeFeature',
        'header',
      ],
    ),
  },
);

extension type _ImageData.fromMap(JsonMap _json) {
  factory _ImageData({required JsonMap url, String? fit, String? hint}) =>
      _ImageData.fromMap({'url': url, 'fit': fit, 'hint': hint});

  JsonMap get url => _json['url'] as JsonMap;
  BoxFit? get fit => _json['fit'] != null
      ? BoxFit.values.firstWhere((e) => e.name == _json['fit'] as String)
      : null;
  String? get hint => _json['hint'] as String?;
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
/// - `hint`: A hint for the image size and style. One of 'icon', 'avatar',
///   'smallFeature', 'mediumFeature', 'largeFeature', 'header'.
final image = CatalogItem(
  name: 'Image',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Image": {
              "url": {
                "literalString": "https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_horizontal.c823e53b3a1a7b0d36a9.png"
              },
              "hint": "mediumFeature"
            }
          }
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
        final String? hint = imageData.hint;

        late Widget child;

        if (location.startsWith('assets/')) {
          child = Image.asset(location, fit: fit);
        } else {
          child = Image.network(location, fit: fit);
        }

        if (hint == 'avatar') {
          child = CircleAvatar(child: child);
        }

        if (hint == 'header') {
          return SizedBox(width: double.infinity, child: child);
        }

        final double size = switch (hint) {
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
