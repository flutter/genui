// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';

final _schema = S.object(
  properties: {
    'url': A2uiSchemas.stringReference(
      description: 'The URL of the video to play.',
    ),
  },
  required: ['url'],
);

/// A catalog item representing a video player.
///
/// This widget currently displays a placeholder for a video player. It is
/// intended to play video content from the given `url`.
///
/// ## Parameters:
///
/// - `url`: The URL of the video to play.
final video = CatalogItem(
  name: 'Video',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 100),
      child: const Placeholder(child: Center(child: Text('Video'))),
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Video": {
              "url": {
                "literalString": "https://example.com/video.mp4"
              }
            }
          }
        }
      ]
    ''',
  ],
);
