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
    'children': A2uiSchemas.componentArrayReference(),
    'direction': S.string(enumValues: ['vertical', 'horizontal']),
    'alignment': S.string(enumValues: ['start', 'center', 'end', 'stretch']),
  },
  required: ['children'],
);

extension type _ListData.fromMap(JsonMap _json) {
  factory _ListData({
    required Object? children,
    String? direction,
    String? alignment,
  }) => _ListData.fromMap({
    'children': children,
    'direction': direction,
    'alignment': alignment,
  });

  Object? get children => _json['children'];
  String? get direction => _json['direction'] as String?;
  String? get alignment => _json['alignment'] as String?;
}

/// A catalog item for a list of widgets.
///
/// ### Parameters:
///
/// - `children`: A list of child widget IDs to display in the list.
/// - `direction`: The direction of the list. Can be `vertical` or
///   `horizontal`. Defaults to `vertical`.
/// - `alignment`: How the children should be placed along the cross axis.
///   Can be `start`, `center`, `end`, or `stretch`. Defaults to `start`.
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
        final direction = listData.direction == 'horizontal'
            ? Axis.horizontal
            : Axis.vertical;
        return ComponentChildrenBuilder(
          childrenData: listData.children,
          dataContext: dataContext,
          buildChild: buildChild,
          explicitListBuilder: (children) {
            return ListView(
              shrinkWrap: true,
              scrollDirection: direction,
              children: children,
            );
          },
          templateListWidgetBuilder:
              (context, Map<String, Object?> data, componentId, dataBinding) {
                final values = data.values.toList();
                final keys = data.keys.toList();
                return ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: direction,
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    final itemDataContext = dataContext.nested(
                      DataPath('$dataBinding/${keys[index]}'),
                    );
                    return buildChild(componentId, itemDataContext);
                  },
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
