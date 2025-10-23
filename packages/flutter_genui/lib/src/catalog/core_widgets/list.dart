// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'children': A2uiSchemas.componentArrayReference(),
    'direction': S.string(enumValues: ['vertical', 'horizontal']),
    'alignment': S.string(enumValues: ['start', 'center', 'end', 'stretch']),
  },
  required: ['children'],
);

extension type _ListData.fromMap(JsonMap _json) {
  factory _ListData({
    required JsonMap children,
    String? direction,
    String? alignment,
  }) => _ListData.fromMap({
    'children': children,
    'direction': direction,
    'alignment': alignment,
  });

  JsonMap get children => _json['children'] as JsonMap;
  String? get direction => _json['direction'] as String?;
  String? get alignment => _json['alignment'] as String?;
}

final list = CatalogItem(
  name: 'List',
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
        final listData = _ListData.fromMap(data as JsonMap);
        final children = listData.children;
        final explicitList = (children['explicitList'] as List?)
            ?.cast<String>();
        if (explicitList != null) {
          return ListView(
            scrollDirection: listData.direction == 'horizontal'
                ? Axis.horizontal
                : Axis.vertical,
            children: explicitList.map(buildChild).toList(),
          );
        }
        // TODO(gspencer): Implement template lists.
        return const SizedBox.shrink();
      },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "List": {
              "children": {
                "explicitList": [
                  "text1",
                  "text2"
                ]
              }
            }
          }
        },
        {
          "id": "text1",
          "component": {
            "Text": {
              "text": {
                "literalString": "First"
              }
            }
          }
        },
        {
          "id": "text2",
          "component": {
            "Text": {
              "text": {
                "literalString": "Second"
              }
            }
          }
        }
      ]
    ''',
  ],
);
