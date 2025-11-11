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

/// A catalog item representing a block of styled text.
///
/// This widget displays a string of text, analogous to Flutter's [Text] widget.
/// The content is taken from the `text` parameter, which can be a literal
/// string or a data model binding.
///
/// ## Parameters:
///
/// - `text`: The text to display. This does *not* support markdown.
final text = CatalogItem(
  name: 'Text',
  dataSchema: S.object(
    properties: {
      'text': A2uiSchemas.stringReference(
        description: 'This does *not* support markdown.',
      ),
    },
    required: ['text'],
  ),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Text": {
              "text": {
                "literalString": "Hello World"
              }
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final textData = _TextData.fromMap(itemContext.data as JsonMap);
    final ValueNotifier<String?> notifier = itemContext.dataContext
        .subscribeToString(textData.text);

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, currentValue, child) {
        return Text(currentValue ?? '');
      },
    );
  },
);
