// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

extension type _TextData.fromMap(JsonMap _json) {
  factory _TextData({required JsonMap text}) =>
      _TextData.fromMap({'text': text});

  JsonMap get text => _json['text'] as JsonMap;
}

final text = CatalogItem(
  name: 'Text',
  dataSchema: S.object(
    properties: {
      'text': A2uiSchemas.stringReference(
        description: 'The text to display. This does *not* support markdown.',
      ),
    },
    required: ['text'],
  ),
  exampleData: [
    () => {
      'root': 'text',
      'widgets': [
        {
          'id': 'text',
          'widget': {
            'Text': {
              'text': {'literalString': 'Hello World'},
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
        final textData = _TextData.fromMap(data as JsonMap);
        final notifier = dataContext.subscribeToString(textData.text);

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, currentValue, child) {
            return Text(
              currentValue ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          },
        );
      },
);
