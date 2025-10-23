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
      description: 'The URL of the audio to play.',
    ),
  },
  required: ['url'],
);

final audioPlayer = CatalogItem(
  name: 'AudioPlayer',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 100),
          child: const Placeholder(child: Center(child: Text('AudioPlayer'))),
        );
      },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AudioPlayer": {
              "url": {
                "literalString": "https://example.com/audio.mp3"
              }
            }
          }
        }
      ]
    ''',
  ],
);
