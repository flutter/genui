// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
// ignore_for_file: avoid_dynamic_calls
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'distribution': S.string(
      description: 'How children are aligned on the main axis. ',
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
      description: 'How children are aligned on the cross axis. ',
      enumValues: ['start', 'center', 'end', 'stretch', 'baseline'],
    ),
    'children': A2uiSchemas.componentArrayReference(
      description: 'A list of widget IDs for the children.',
    ),
  },
);

extension type _ColumnData.fromMap(JsonMap _json) {
  factory _ColumnData({
    JsonMap? children,
    String? distribution,
    String? alignment,
  }) => _ColumnData.fromMap({
    'children': children,
    'distribution': distribution,
    'alignment': alignment,
  });

  JsonMap? get children => _json['children'] as JsonMap?;
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
    default:
      return CrossAxisAlignment.start;
  }
}

final column = CatalogItem(
  name: 'Column',
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
        final columnData = _ColumnData.fromMap(data as JsonMap);
        final children = columnData.children;
        final explicitList = (children?['explicitList'] as List?)
            ?.cast<String>();
        if (explicitList != null) {
          return Column(
            mainAxisAlignment: _parseMainAxisAlignment(columnData.distribution),
            crossAxisAlignment: _parseCrossAxisAlignment(columnData.alignment),
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
            "Column": {
              "children": {
                "explicitList": [
                  "advice_text",
                  "advice_options",
                  "submit_button"
                ]
              }
            }
          }
        },
        {
          "id": "advice_text",
          "component": {
            "Text": {
              "text": {
                "literalString": "What kind of advice are you looking for?"
              }
            }
          }
        },
        {
          "id": "advice_options",
          "component": {
            "Text": {
              "text": {
                "literalString": "Some advice options."
              }
            }
          }
        },
        {
          "id": "submit_button",
          "component": {
            "Button": {
              "child": "submit_button_text",
              "action": {
                "name": "submit"
              }
            }
          }
        },
        {
          "id": "submit_button_text",
          "component": {
            "Text": {
              "text": {
                "literalString": "Submit"
              }
            }
          }
        }
      ]
    ''',
  ],
);
