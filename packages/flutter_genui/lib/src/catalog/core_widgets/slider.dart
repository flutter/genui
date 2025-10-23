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
    'value': A2uiSchemas.numberReference(),
    'minValue': S.number(),
    'maxValue': S.number(),
  },
  required: ['value'],
);

extension type _SliderData.fromMap(JsonMap _json) {
  factory _SliderData({
    required JsonMap value,
    double? minValue,
    double? maxValue,
  }) => _SliderData.fromMap({
    'value': value,
    'minValue': minValue,
    'maxValue': maxValue,
  });

  JsonMap get value => _json['value'] as JsonMap;
  double get minValue => (_json['minValue'] as num?)?.toDouble() ?? 0.0;
  double get maxValue => (_json['maxValue'] as num?)?.toDouble() ?? 1.0;
}

final slider = CatalogItem(
  name: 'Slider',
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
        final sliderData = _SliderData.fromMap(data as JsonMap);
        final valueNotifier = dataContext.subscribeToValue<num>(
          sliderData.value,
          'literalNumber',
        );

        return ValueListenableBuilder<num?>(
          valueListenable: valueNotifier,
          builder: (context, value, child) {
            return Slider(
              value: (value ?? 0.0).toDouble(),
              min: sliderData.minValue,
              max: sliderData.maxValue,
              onChanged: (newValue) {
                final path = sliderData.value['path'] as String?;
                if (path != null) {
                  dataContext.update(path, newValue);
                }
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
            "Slider": {
              "value": {
                "path": "/myValue"
              }
            }
          }
        }
      ]
    ''',
  ],
);
