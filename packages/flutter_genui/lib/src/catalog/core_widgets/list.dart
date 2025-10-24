// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/logging.dart';
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
        final children = listData.children;
        final explicitList = (children['explicitList'] as List?)
            ?.cast<String>();
        final direction = listData.direction == 'horizontal'
            ? Axis.horizontal
            : Axis.vertical;
        if (explicitList != null) {
          return ListView(
            shrinkWrap: true,
            scrollDirection: direction,
            children: explicitList
                .map((childId) => buildChild(childId))
                .toList(),
          );
        }
        final template = children['template'] as JsonMap?;
        if (template != null) {
          final dataBinding = template['dataBinding'] as String;
          final componentId = template['componentId'] as String;
          final listNotifier = dataContext.subscribe<List<dynamic>>(
            DataPath(dataBinding),
          );
          return ValueListenableBuilder<List<dynamic>?>(
            valueListenable: listNotifier,
            builder: (context, list, child) {
              genUiLogger.info('ListView.builder: list=$list');
              if (list == null) {
                return const SizedBox.shrink();
              }
              return ListView.builder(
                shrinkWrap: true,
                scrollDirection: direction,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final itemDataContext = dataContext.nested(
                    DataPath('$dataBinding[$index]'),
                  );
                  return buildChild(componentId, itemDataContext);
                },
              );
            },
          );
        }
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
