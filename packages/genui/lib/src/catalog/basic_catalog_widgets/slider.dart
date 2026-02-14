// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';
import '../../widgets/widget_utilities.dart';
import 'widget_helpers.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['Slider']),
    'value': A2uiSchemas.numberReference(),
    'min': S.number(description: 'The minimum value. Defaults to 0.0.'),
    'max': S.number(description: 'The maximum value. Defaults to 1.0.'),
    'label': A2uiSchemas.stringReference(
      description: 'The label for the slider.',
    ),
    'checks': A2uiSchemas.checkable(),
  },
  required: ['component', 'value'],
);

extension type _SliderData.fromMap(JsonMap _json) {
  factory _SliderData({
    required JsonMap value,
    double? min,
    double? max,
    List<JsonMap>? checks,
  }) => _SliderData.fromMap({
    'value': value,
    'min': min,
    'max': max,
    'checks': checks,
  });

  Object get value => _json['value'] as Object;
  double get min => (_json['min'] as num?)?.toDouble() ?? 0.0;
  double get max => (_json['max'] as num?)?.toDouble() ?? 1.0;
  List<JsonMap>? get checks => (_json['checks'] as List?)?.cast<JsonMap>();

  String? get label {
    final Object? val = _json['label'];
    if (val is String) return val;
    if (val is Map && val.containsKey('value')) {
      return val['value'] as String?;
    }
    return null;
  }
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
/// - `label`: The label for the slider.
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
        .subscribe<num>(path);

    final ValueNotifier<String?> labelNotifier = sliderData.label != null
        ? itemContext.dataContext.subscribeToString(sliderData.label!)
        : ValueNotifier(null);

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

        final Widget sliderWidget = Padding(
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
                    itemContext.dataContext.update(path, newValue);
                  },
                ),
              ),
              Text(
                value?.toStringAsFixed(0) ?? sliderData.min.toStringAsFixed(0),
              ),
            ],
          ),
        );

        return ValueListenableBuilder<Object?>(
          valueListenable: itemContext.dataContext.createComputedNotifier(
            checksToExpression(sliderData.checks),
          ),
          builder: (context, isValid, _) {
            final isError = isValid == false;

            return ValueListenableBuilder<String?>(
              valueListenable: labelNotifier,
              builder: (context, label, child) {
                final List<Widget> children = [];
                if (label != null && label.isNotEmpty) {
                  children.add(
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  );
                }
                children.add(sliderWidget);
                if (isError) {
                  children.add(
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                      child: Text(
                        'Invalid value',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                if (children.length == 1) {
                  return children.first;
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                );
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
          "component": "Slider",
          "min": 0,
          "max": 10,
          "value": {
            "path": "/myValue"
          }
        }
      ]
    ''',
  ],
);
