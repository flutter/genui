// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'location': A2uiSchemas.stringReference(
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
  factory _ImageData({required JsonMap location, String? fit}) =>
      _ImageData.fromMap({'location': location, 'fit': fit});

  JsonMap get location => _json['location'] as JsonMap;
  BoxFit? get fit => _json['fit'] != null
      ? BoxFit.values.firstWhere((e) => e.name == _json['fit'] as String)
      : null;
}

final image = CatalogItem(
  name: 'Image',
  dataSchema: _schema,
  exampleData: [
    () => {
      'root': 'image',
      'widgets': [
        {
          'id': 'image',
          'widget': {
            'Image': {
              'location': {
                'literalString':
                    'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png',
              },
            },
          },
        },
      ],
    },
  ],
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final imageData = _ImageData.fromMap(data as JsonMap);
        final notifier = dataContext.subscribeToString(imageData.location);

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, currentLocation, child) {
            final location = currentLocation;
            if (location == null) {
              return const SizedBox.shrink();
            }
            final fit = imageData.fit;

            if (location.startsWith('assets/')) {
              return Image.asset(location, fit: fit);
            } else {
              return Image.network(location, fit: fit);
            }
          },
        );
      },
);
