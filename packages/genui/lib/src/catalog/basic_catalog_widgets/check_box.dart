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
    'component': S.string(enumValues: ['CheckBox']),
    'label': A2uiSchemas.stringReference(),
    'value': A2uiSchemas.booleanReference(),
    'checks': A2uiSchemas.checkable(),
  },
  required: ['component', 'label', 'value'],
);

extension type _CheckBoxData.fromMap(JsonMap _json) {
  factory _CheckBoxData({
    required JsonMap label,
    required JsonMap value,
    List<JsonMap>? checks,
  }) =>
      _CheckBoxData.fromMap({'label': label, 'value': value, 'checks': checks});

  Object get label => _json['label'] as Object;
  Object get value => _json['value'] as Object;
  List<JsonMap>? get checks => (_json['checks'] as List?)?.cast<JsonMap>();
}

/// A catalog item representing a Material Design checkbox with a label.
///
/// This widget displays a checkbox a [Text] label. The checkbox's state
/// is bidirectionally bound to the data model path specified in the `value`
/// parameter.
///
/// ## Parameters:
///
/// - `label`: The text to display next to the checkbox.
/// - `value`: The boolean value of the checkbox.
final checkBox = CatalogItem(
  name: 'CheckBox',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final checkBoxData = _CheckBoxData.fromMap(itemContext.data as JsonMap);
    final ValueNotifier<String?> labelNotifier = itemContext.dataContext
        .subscribeToString(checkBoxData.label);

    final Object valueRef = checkBoxData.value;
    final path = (valueRef is Map && valueRef.containsKey('path'))
        ? valueRef['path'] as String
        : '${itemContext.id}.value';

    final ValueNotifier<bool?> valueNotifier = itemContext.dataContext
        .subscribeToBool({'path': path});

    return ValueListenableBuilder<String?>(
      valueListenable: labelNotifier,
      builder: (context, label, child) {
        return ValueListenableBuilder<bool?>(
          valueListenable: valueNotifier,
          builder: (context, value, child) {
            final bool effectiveValue =
                value ?? (valueRef is bool ? valueRef : false);

            // Wrap the checkbox in validation
            return ValueListenableBuilder<Object?>(
              valueListenable: itemContext.dataContext.createComputedNotifier(
                checksToExpression(checkBoxData.checks),
              ),
              builder: (context, isValid, _) {
                final isError = isValid == false;

                final Widget checkboxWidget = ListTileTheme.merge(
                  child: CheckboxListTile(
                    title: Text(label ?? ''),
                    value: effectiveValue,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        itemContext.dataContext.update(path, newValue);
                      }
                    },
                    subtitle: isError
                        ? Text(
                            'Invalid value',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    isError: isError,
                  ),
                );

                return checkboxWidget;
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
          "component": "CheckBox",
          "label": "Check me",
          "value": {
            "path": "/myValue"
          }
        }
      ]
    ''',
  ],
  isImplicitlyFlexible: true,
);
