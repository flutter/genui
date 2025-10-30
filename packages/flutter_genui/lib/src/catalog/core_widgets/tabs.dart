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
    'tabItems': S.list(
      items: S.object(
        properties: {
          'title': A2uiSchemas.stringReference(),
          'child': A2uiSchemas.componentReference(),
        },
        required: ['title', 'child'],
      ),
    ),
  },
  required: ['tabItems'],
);

extension type _TabsData.fromMap(JsonMap _json) {
  factory _TabsData({required List<JsonMap> tabItems}) =>
      _TabsData.fromMap({'tabItems': tabItems});

  List<JsonMap> get tabItems => (_json['tabItems'] as List).cast<JsonMap>();
}

/// A catalog item representing a Material Design tab layout.
///
/// This widget displays a [TabBar] and a [TabBarView] to allow navigation
/// between different child components. Each tab in `tabItems` has a title and
/// a corresponding child component ID to display when selected.
///
/// ## Parameters:
///
/// - `tabItems`: A list of tabs to display, each with a `title` and a `child`
///   widget ID.
final tabs = CatalogItem(
  name: 'Tabs',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
        required getComponent,
      }) {
        final tabsData = _TabsData.fromMap(data as JsonMap);
        return DefaultTabController(
          length: tabsData.tabItems.length,
          child: Column(
            children: [
              TabBar(
                tabs: tabsData.tabItems.map((tabItem) {
                  final titleNotifier = dataContext.subscribeToString(
                    tabItem['title'] as JsonMap,
                  );
                  return ValueListenableBuilder<String?>(
                    valueListenable: titleNotifier,
                    builder: (context, title, child) {
                      return Tab(text: title ?? '');
                    },
                  );
                }).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: tabsData.tabItems.map((tabItem) {
                    return buildChild(tabItem['child'] as String);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Tabs": {
              "tabItems": [
                {
                  "title": {
                    "literalString": "Tab 1"
                  },
                  "child": "text1"
                },
                {
                  "title": {
                    "literalString": "Tab 2"
                  },
                  "child": "text2"
                }
              ]
            }
          }
        },
        {
          "id": "text1",
          "component": {
            "Text": {
              "text": {
                "literalString": "This is the first tab."
              }
            }
          }
        },
        {
          "id": "text2",
          "component": {
            "Text": {
              "text": {
                "literalString": "This is the second tab."
              }
            }
          }
        }
      ]
    ''',
  ],
);
