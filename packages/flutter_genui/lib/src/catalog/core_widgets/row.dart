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
    'distribution': S.string(
      enumValues: [
        'start',
        'center',
        'end',
        'spaceBetween',
        'spaceAround',
        'spaceEvenly',
      ],
    ),
    'alignment': S.string(
      enumValues: ['start', 'center', 'end', 'stretch', 'baseline'],
    ),
  },
  required: ['children'],
);

extension type _RowData.fromMap(JsonMap _json) {
  factory _RowData({
    required JsonMap children,
    String? distribution,
    String? alignment,
  }) => _RowData.fromMap({
    'children': children,
    'distribution': distribution,
    'alignment': alignment,
  });

  JsonMap get children => _json['children'] as JsonMap;
  String? get distribution => _json['distribution'] as String?;
  String? get alignment => _json['alignment'] as String?;
}

MainAxisAlignment _parseMainAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return MainAxisAlignment.start;
    case 'center':
      return MainAxisAlignment.center;
    case 'end':
      return MainAxisAlignment.end;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start;
  }
}

CrossAxisAlignment _parseCrossAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return CrossAxisAlignment.start;
    case 'center':
      return CrossAxisAlignment.center;
    case 'end':
      return CrossAxisAlignment.end;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    case 'baseline':
      return CrossAxisAlignment.baseline;
    default:
      return CrossAxisAlignment.start;
  }
}

final row = CatalogItem(
  name: 'Row',
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
        final rowData = _RowData.fromMap(data as JsonMap);
        final children = rowData.children;
        final explicitList = (children['explicitList'] as List?)
            ?.cast<String>();
        if (explicitList != null) {
          return Row(
            mainAxisAlignment: _parseMainAxisAlignment(rowData.distribution),
            crossAxisAlignment: _parseCrossAxisAlignment(rowData.alignment),
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
            "Row": {
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
