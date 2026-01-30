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
    'component': S.string(enumValues: ['Slider']),
    'value': A2uiSchemas.numberReference(),
    'min': S.number(description: 'The minimum value. Defaults to 0.0.'),
    'max': S.number(description: 'The maximum value. Defaults to 1.0.'),
  },
  required: ['component', 'value'],
);

extension type _SliderData.fromMap(JsonMap _json) {
  factory _SliderData({required JsonMap value, double? min, double? max}) =>
      _SliderData.fromMap({'value': value, 'min': min, 'max': max});

  Object get value => _json['value'] as Object;
  double get min =>
      ((_json['min'] ?? _json['minValue']) as num?)?.toDouble() ?? 0.0;
  double get max =>
      ((_json['max'] ?? _json['maxValue']) as num?)?.toDouble() ?? 1.0;
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
/// - `min`: The minimum value of the slider. Defaults to 0.0.
/// - `max`: The maximum value of the slider. Defaults to 1.0.
final slider = CatalogItem(
  name: 'Slider',
  dataSchema: _schema,
  widgetBuilder: (CatalogItemContext itemContext) {
    final sliderData = _SliderData.fromMap(itemContext.data as JsonMap);
    final Object valueRef = sliderData.value;
    final path = (valueRef is Map && valueRef.containsKey('path'))
        ? valueRef['path'] as String
        : '${itemContext.id}.value';

    final ValueNotifier<num?> valueNotifier = itemContext.dataContext
        .subscribeToValue<num>({'path': path});

    return ValueListenableBuilder<num?>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        // If value is null (nothing in DataContext yet), fall back to
        // literal value if provided.
        var effectiveValue = value;
        if (effectiveValue == null) {
          if (valueRef is num) {
            effectiveValue = valueRef;
          }
        }

        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Slider(
                  value: (effectiveValue ?? sliderData.min).toDouble(),
                  min: sliderData.min,
                  max: sliderData.max,
                  divisions: (sliderData.max - sliderData.min).toInt(),
                  onChanged: (newValue) {
                    itemContext.dataContext.update(DataPath(path), newValue);
                  },
                ),
              ),
              Text(
                value?.toStringAsFixed(0) ?? sliderData.min.toStringAsFixed(0),
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
          "component": "Slider",
          "minValue": 0,
          "maxValue": 10,
          "value": {
            "path": "/myValue"
          }
        }
      ]
    ''',
  ],
);
