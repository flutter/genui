// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'url': S.string(
      description:
          'The URL of the image to display. Only one '
          'of url or assetName may be specified.',
    ),
    'assetName': S.string(
      description:
          'The name of the asset to display. Only '
          'one of assetName or url may be specified.',
    ),
    'fit': S.string(
      description: 'How the image should be inscribed into the box.',
      enumValues: BoxFit.values.map((e) => e.name).toList(),
    ),
  },
);

extension type _ImageData.fromMap(JsonMap _json) {
  factory _ImageData({String? url, String? assetName, String? fit}) =>
      _ImageData.fromMap({'url': url, 'assetName': assetName, 'fit': fit});

  String? get url => _json['url'] as String?;
  String? get assetName => _json['assetName'] as String?;
  BoxFit? get fit => _json['fit'] != null
      ? BoxFit.values.firstWhere((e) => e.name == _json['fit'] as String)
      : null;
}

final image = CatalogItem(
  name: 'Image',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final imageData = _ImageData.fromMap(data as JsonMap);

        final url = imageData.url;
        final assetName = imageData.assetName;

        if ((url == null) == (assetName == null)) {
          throw Exception(
            'Image widget must have either a url or an assetName, '
            'but not both. '
            'Details: $imageData',
          );
        }

        if (url != null) {
          return Image.network(url, fit: imageData.fit);
        }

        if (assetName != null) {
          return Image.asset(assetName, fit: imageData.fit);
        }

        return const SizedBox();
      },
);
