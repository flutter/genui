// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
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

/// A catalog item representing a Material Design slider.
///
/// This widget allows the user to select a value from a range by sliding a
/// thumb along a track. The `value` is bidirectionally bound to the data model.
/// This is analogous to Flutter's [Slider] widget.
///
/// ## Parameters:
///
/// - `value`: The current value of the slider.
/// - `minValue`: The minimum value of the slider. Defaults to 0.0.
/// - `maxValue`: The maximum value of the slider. Defaults to 1.0.
final slider = CatalogItem(
  name: 'Slider',
  dataSchema: _schema,
  widgetBuilder: (CatalogItemContext itemContext) {
    final sliderData = _SliderData.fromMap(itemContext.data as JsonMap);
    final ValueNotifier<num?> valueNotifier = itemContext.dataContext
        .subscribeToValue<num>(sliderData.value, 'literalNumber');

    return ValueListenableBuilder<num?>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Slider(
                  value: (value ?? sliderData.minValue).toDouble(),
                  min: sliderData.minValue,
                  max: sliderData.maxValue,
                  divisions: (sliderData.maxValue - sliderData.minValue)
                      .toInt(),
                  onChanged: (newValue) {
                    final path = sliderData.value['path'] as String?;
                    if (path != null) {
                      itemContext.dataContext.update(DataPath(path), newValue);
                    }
                  },
                ),
              ),
              Text(
                value?.toStringAsFixed(0) ??
                    sliderData.minValue.toStringAsFixed(0),
              ),
            ],
          ),
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
