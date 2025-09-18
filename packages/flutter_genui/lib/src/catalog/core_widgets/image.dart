// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'location': S.string(
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
  factory _ImageData({required String location, String? fit}) =>
      _ImageData.fromMap({'location': location, 'fit': fit});

  String get location => _json['location'] as String;
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

        final location = imageData.location;
        final fit = imageData.fit;

        if (location.startsWith('assets/')) {
          return Image.asset(location, fit: fit);
        } else {
          return Image.network(location, fit: fit);
        }
      },
);
