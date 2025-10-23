// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {'child': A2uiSchemas.componentReference()},
  required: ['child'],
);

extension type _CardData.fromMap(JsonMap _json) {
  factory _CardData({required String child}) =>
      _CardData.fromMap({'child': child});

  String get child => _json['child'] as String;
}

final card = CatalogItem(
  name: 'Card',
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
        final cardData = _CardData.fromMap(data as JsonMap);
        return Card(child: buildChild(cardData.child));
      },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Card": {
              "child": "text"
            }
          }
        },
        {
          "id": "text",
          "component": {
            "Text": {
              "text": {
                "literalString": "This is a card."
              }
            }
          }
        }
      ]
    ''',
  ],
);
