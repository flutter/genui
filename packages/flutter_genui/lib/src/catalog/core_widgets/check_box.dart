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
    'label': A2uiSchemas.stringReference(),
    'value': A2uiSchemas.booleanReference(),
  },
  required: ['label', 'value'],
);

extension type _CheckBoxData.fromMap(JsonMap _json) {
  factory _CheckBoxData({required JsonMap label, required JsonMap value}) =>
      _CheckBoxData.fromMap({'label': label, 'value': value});

  JsonMap get label => _json['label'] as JsonMap;
  JsonMap get value => _json['value'] as JsonMap;
}

final checkBox = CatalogItem(
  name: 'CheckBox',
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
        final checkBoxData = _CheckBoxData.fromMap(data as JsonMap);
        final labelNotifier = dataContext.subscribeToString(checkBoxData.label);
        final valueNotifier = dataContext.subscribeToBool(checkBoxData.value);
        return ValueListenableBuilder<String?>(
          valueListenable: labelNotifier,
          builder: (context, label, child) {
            return ValueListenableBuilder<bool?>(
              valueListenable: valueNotifier,
              builder: (context, value, child) {
                return CheckboxListTile(
                  title: Text(label ?? ''),
                  value: value ?? false,
                  onChanged: (newValue) {
                    final path = checkBoxData.value['path'] as String?;
                    if (path != null) {
                      dataContext.update(path, newValue);
                    }
                  },
                );
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
            "CheckBox": {
              "label": {
                "literalString": "Check me"
              },
              "value": {
                "literalBoolean": true
              }
            }
          }
        }
      ]
    ''',
  ],
);
