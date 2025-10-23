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

final heading = CatalogItem(
  name: 'Heading',
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
        final headingData = _HeadingData.fromMap(data as JsonMap);
        final notifier = dataContext.subscribeToString(headingData.text);

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, currentValue, child) {
            final textTheme = Theme.of(context).textTheme;
            final style = switch (headingData.level) {
              '1' => textTheme.headlineLarge,
              '2' => textTheme.headlineMedium,
              '3' => textTheme.headlineSmall,
              '4' => textTheme.titleLarge,
              '5' => textTheme.titleMedium,
              _ => textTheme.titleSmall,
            };
            return Text(currentValue ?? '', style: style);
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
