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
    'component': S.string(enumValues: ['Column']),
    'justify': S.string(
      description: 'How children are aligned on the main axis. ',
      enumValues: [
        'start',
        'center',
        'end',
        'spaceBetween',
        'spaceAround',
        'spaceEvenly',
        'stretch', // Added stretch to match keys
      ],
    ),
    'align': S.string(
      description: 'How children are aligned on the cross axis. ',
      enumValues: ['start', 'center', 'end', 'stretch', 'baseline'],
    ),
    'children': A2uiSchemas.componentArrayReference(
      description:
          'Either an explicit list of widget IDs for the children, or a '
          'template with a data binding to the list of children.',
    ),
  },
  required: ['component', 'children'],
);

extension type _ColumnData.fromMap(JsonMap _json) {
  factory _ColumnData({Object? children, String? justify, String? align}) =>
      _ColumnData.fromMap({
        'children': children,
        'justify': justify,
        'align': align,
      });

  Object? get children => _json['children'];
  String? get justify =>
      _json['justify'] as String? ?? _json['distribution'] as String?;
  String? get align =>
      _json['align'] as String? ?? _json['alignment'] as String?;
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

/// A catalog item representing a layout widget that displays its children in a
/// vertical array.
///
/// This widget is analogous to Flutter's [Column] widget. It arranges a list of
/// child components from top to bottom.
///
/// ## Parameters:
///
/// - `distribution`: How the children should be placed along the main axis. Can
///   be `start`, `center`, `end`, `spaceBetween`, `spaceAround`, or
///   `spaceEvenly`. Defaults to `start`.
/// - `alignment`: How the children should be placed along the cross axis. Can
///   be `start`, `center`, `end`, `stretch`, or `baseline`. Defaults to
///   `start`.
/// - `children`: A list of child widget IDs to display in the column.
final column = CatalogItem(
  name: 'Column',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final columnData = _ColumnData.fromMap(itemContext.data as JsonMap);
    return ComponentChildrenBuilder(
      childrenData: columnData.children,
      dataContext: itemContext.dataContext,
      buildChild: itemContext.buildChild,
      getComponent: itemContext.getComponent,
      explicitListBuilder: (childIds, buildChild, getComponent, dataContext) {
        return Column(
          mainAxisAlignment: _parseMainAxisAlignment(columnData.justify),
          crossAxisAlignment: _parseCrossAxisAlignment(columnData.align),
          mainAxisSize: MainAxisSize.min,
          children: childIds
              .map(
                (componentId) => buildWeightedChild(
                  componentId: componentId,
                  dataContext: dataContext,
                  buildChild: buildChild,
                  weight:
                      getComponent(componentId)?.properties['weight'] as int?,
                ),
              )
              .toList(),
        );
      },
      templateListWidgetBuilder: (context, list, componentId, dataBinding) {
        return Column(
          mainAxisAlignment: _parseMainAxisAlignment(columnData.justify),
          crossAxisAlignment: _parseCrossAxisAlignment(columnData.align),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              buildWeightedChild(
                componentId: componentId,
                dataContext: itemContext.dataContext.nested(
                  DataPath('$dataBinding/$i'),
                ),
                buildChild: itemContext.buildChild,
                weight:
                    itemContext.getComponent(componentId)?.properties['weight']
                        as int?,
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
          "component": "Column",
          "children": [
            "advice_text",
            "advice_options",
            "submit_button"
          ]
        },
        {
          "id": "advice_text",
          "component": "Text",
          "text": "What kind of advice are you looking for?"
        },
        {
          "id": "advice_options",
          "component": "Text",
          "text": "Some advice options."
        },
        {
          "id": "submit_button",
          "component": "Button",
          "child": "submit_button_text",
          "action": {
            "event": {
              "name": "submit"
            }
          }
        },
        {
          "id": "submit_button_text",
          "component": "Text",
          "text": "Submit"
        }
      ]
    ''',
  ],
);
