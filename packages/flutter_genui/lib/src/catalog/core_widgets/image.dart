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
  },
);

extension type _ImageData.fromMap(JsonMap _json) {
  factory _ImageData({required JsonMap url, String? fit}) =>
      _ImageData.fromMap({'url': url, 'fit': fit});

  JsonMap get url => _json['url'] as JsonMap;
  BoxFit? get fit => _json['fit'] != null
      ? BoxFit.values.firstWhere((e) => e.name == _json['fit'] as String)
      : null;
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
                "literalString": "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png"
              }
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final imageData = _ImageData.fromMap(itemContext.data as JsonMap);
    final notifier = itemContext.dataContext.subscribeToString(imageData.url);

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
        final fit = imageData.fit;

        late Widget bchild;

        if (location.startsWith('assets/')) {
          bchild = Image.asset(location, fit: fit);
        } else {
          bchild = Image.network(location, fit: fit);
        }
        return SizedBox(width: 150, height: 150, child: bchild);
      },
    );
  },
);
