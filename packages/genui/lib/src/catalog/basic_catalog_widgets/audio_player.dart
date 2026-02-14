// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';
import '../../widgets/widget_utilities.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['AudioPlayer']),
    'url': A2uiSchemas.stringReference(
      description: 'The URL of the audio to play.',
    ),
    'description': A2uiSchemas.stringReference(
      description: 'A description of the audio, such as a title or summary.',
    ),
  },
  required: ['component', 'url'],
);

/// A catalog item for an audio player.
///
/// This widget displays a placeholder for an audio player, used to represent
/// a component capable of playing audio from a given URL.
///
/// ## Parameters:
///
/// - `url`: The URL of the audio to play.
final audioPlayer = CatalogItem(
  name: 'AudioPlayer',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final Object? description = (itemContext.data as JsonMap)['description'];
    final ValueNotifier<String?> descriptionNotifier = itemContext.dataContext
        .subscribeToString(description);

    return ValueListenableBuilder<String?>(
      valueListenable: descriptionNotifier,
      builder: (context, description, child) {
        return Semantics(
          label: description,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 100),
            child: const Placeholder(child: Center(child: Text('AudioPlayer'))),
          ),
        );
      },
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "AudioPlayer",
          "url": "https://example.com/audio.mp3"
        }
      ]
    ''',
  ],
);
