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
    'minValue': A2uiSchemas.numberReference(),
    'maxValue': A2uiSchemas.numberReference(),
  },
  required: ['value'],
);

extension type _SliderData.fromMap(JsonMap _json) {
  factory _SliderData({
    required JsonMap value,
    JsonMap? minValue,
    JsonMap? maxValue,
  }) => _SliderData.fromMap({
    'value': value,
    'minValue': minValue,
    'maxValue': maxValue,
  });

  JsonMap get value => _json['value'] as JsonMap;
  JsonMap? get minValue => _json['minValue'] as JsonMap?;
  JsonMap? get maxValue => _json['maxValue'] as JsonMap?;
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
    final ValueNotifier<num?> minNotifier = itemContext.dataContext
        .subscribeToValue<num>(
          sliderData.minValue ?? {'literalNumber': 0.0},
          'literalNumber',
        );
    final ValueNotifier<num?> maxNotifier = itemContext.dataContext
        .subscribeToValue<num>(
          sliderData.maxValue ?? {'literalNumber': 1.0},
          'literalNumber',
        );

    return ListenableBuilder(
      listenable: Listenable.merge([valueNotifier, minNotifier, maxNotifier]),
      builder: (context, child) {
        final double min = (minNotifier.value ?? 0.0).toDouble();
        final double max = (maxNotifier.value ?? 1.0).toDouble();
        // Ensure min < max to avoid errors
        final effectiveMin = min;
        final double effectiveMax = max > min ? max : min + 1.0;

        final double val = (valueNotifier.value ?? effectiveMin).toDouble();
        final double effectiveVal = val.clamp(effectiveMin, effectiveMax);

        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Slider(
                  value: effectiveVal,
                  min: effectiveMin,
                  max: effectiveMax,
                  divisions: (effectiveMax - effectiveMin) > 0
                      ? (effectiveMax - effectiveMin).toInt()
                      : 1,
                  onChanged: (newValue) {
                    final path = sliderData.value['path'] as String?;
                    if (path != null) {
                      itemContext.dataContext.update(DataPath(path), newValue);
                    }
                  },
                ),
              ),
              Text(effectiveVal.toStringAsFixed(0)),
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
          "props": {
            "component": "Slider",
            "minValue": {"literalNumber": 0},
            "maxValue": {"literalNumber": 10},
            "value": {
              "path": "/myValue",
              "literalNumber": 5
            }
          }
        }
      ]
    ''',
  ],
);
