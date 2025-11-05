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
    'text': A2uiSchemas.stringReference(),
    'level': S.string(enumValues: ['1', '2', '3', '4', '5']),
  },
  required: ['text'],
);

extension type _HeadingData.fromMap(JsonMap _json) {
  factory _HeadingData({required JsonMap text, String? level}) =>
      _HeadingData.fromMap({'text': text, 'level': level});

  JsonMap get text => _json['text'] as JsonMap;
  String? get level => _json['level'] as String?;
}

/// A catalog item representing a text heading.
///
/// Headings are used to title sections of content. The visual appearance is
/// determined by the `level` parameter, which maps to standard [TextTheme]
/// styles.
///
/// ## Parameters:
///
/// - `text`: The text to display.
/// - `level`: The heading level, from 1 to 5. This affects the text style.
final heading = CatalogItem(
  name: 'Heading',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final headingData = _HeadingData.fromMap(itemContext.data as JsonMap);
    final notifier = itemContext.dataContext.subscribeToString(
      headingData.text,
    );

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, currentValue, child) {
        final textTheme = Theme.of(context).textTheme;
        final level = int.tryParse(headingData.level ?? '5') ?? 5;
        final style = switch (level) {
          1 => textTheme.headlineLarge,
          2 => textTheme.headlineMedium,
          3 => textTheme.headlineSmall,
          4 => textTheme.titleLarge,
          5 => textTheme.titleMedium,
          _ => textTheme.titleSmall,
        };
        final verticalPadding = switch (level) {
          1 => 20.0,
          2 => 16.0,
          3 => 12.0,
          4 => 8.0,
          _ => 4.0,
        };
        return Padding(
          // Add some space below the heading to separate it from the content
          // above and below it, proportionally based on the heading level.
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Text(currentValue ?? '', style: style),
        );
      },
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Heading": {
              "text": {
                "literalString": "This is a heading"
              },
              "level": "1"
            }
          }
        }
      ]
    ''',
  ],
);
