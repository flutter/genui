// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';
import 'widget_helpers.dart';

final _schema = S.object(
  properties: {
    'children': A2uiSchemas.componentArrayReference(
      description:
          'Either an explicit list of widget IDs for the children, or a '
          'template with a data binding to the list of children.',
    ),
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
    Object? children,
    String? distribution,
    String? alignment,
  }) => _RowData.fromMap({
    'children': children,
    'distribution': distribution,
    'alignment': alignment,
  });

  Object? get children => _json['children'];
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

/// A catalog item representing a layout widget that displays its children in a
/// horizontal array.
///
/// This widget is analogous to Flutter's [Row] widget. It arranges a list of
/// child components from left to right.
///
/// ## Parameters:
///
/// - `children`: A list of child widget IDs to display in the row.
/// - `distribution`: How the children should be placed along the main axis. Can
///   be `start`, `center`, `end`, `spaceBetween`, `spaceAround`, or
///   `spaceEvenly`. Defaults to `start`.
/// - `alignment`: How the children should be placed along the cross axis. Can
///   be `start`, `center`, `end`, `stretch`, or `baseline`. Defaults to
///   `start`.
final row = CatalogItem(
  name: 'Row',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final rowData = _RowData.fromMap(itemContext.data as JsonMap);
    return ComponentChildrenBuilder(
      childrenData: rowData.children,
      dataContext: itemContext.dataContext,
      buildChild: itemContext.buildChild,
      getComponent: itemContext.getComponent,
      explicitListBuilder: (childIds, buildChild, getComponent, dataContext) {
        return Row(
          mainAxisAlignment: _parseMainAxisAlignment(rowData.distribution),
          crossAxisAlignment: _parseCrossAxisAlignment(rowData.alignment),
          mainAxisSize: MainAxisSize.min,
          children: childIds
              .map(
                (componentId) => buildWeightedChild(
                  componentId: componentId,
                  dataContext: dataContext,
                  buildChild: buildChild,
                  component: getComponent(componentId),
                ),
              )
              .toList(),
        );
      },
      templateListWidgetBuilder: (context, list, componentId, dataBinding) {
        return Row(
          mainAxisAlignment: _parseMainAxisAlignment(rowData.distribution),
          crossAxisAlignment: _parseCrossAxisAlignment(rowData.alignment),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              buildWeightedChild(
                componentId: componentId,
                dataContext: itemContext.dataContext.nested(
                  DataPath('$dataBinding/$i'),
                ),
                buildChild: itemContext.buildChild,
                component: itemContext.getComponent(componentId),
              ),
            ],
          ],
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
