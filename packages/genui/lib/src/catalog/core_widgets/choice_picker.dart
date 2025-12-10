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
    'value': A2uiSchemas.stringArrayReference(),
    'options': A2uiSchemas.objectArrayReference(),
    'usageHint': S.string(
      description: 'Hint for how the choice picker should be displayed.',
      enumValues: ['multipleSelection', 'mutuallyExclusive'],
    ),
  },
  required: ['value', 'options'],
);

extension type _ChoicePickerData.fromMap(JsonMap _json) {
  factory _ChoicePickerData({
    required JsonMap value,
    required JsonMap options,
    String? usageHint,
  }) => _ChoicePickerData.fromMap({
    'value': value,
    'options': options,
    'usageHint': usageHint,
  });

  JsonMap get value => _json['value'] as JsonMap;
  JsonMap get options => _json['options'] as JsonMap;
  String? get usageHint => _json['usageHint'] as String?;
}

/// A catalog item representing a choice picker widget.
///
/// This widget displays a list of options, each with a checkbox or radio
/// button.
///
/// The `value` parameter, which should be a data model path, is updated to
/// reflect the list of *values* of the currently selected options.
///
/// ## Parameters:
///
/// - `value`: A list of the values of the selected options.
/// - `options`: A list of options to display, each with a `label` and a
///   `value`.
/// - `usageHint`: Hints at how the picker should behave. 'mutuallyExclusive'
///   implies single selection (radio buttons), while 'multipleSelection'
///   implies multiple selection (checkboxes). Defaults to 'multipleSelection'.
final choicePicker = CatalogItem(
  name: 'ChoicePicker',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final choicePickerData = _ChoicePickerData.fromMap(
      itemContext.data as JsonMap,
    );
    final ValueNotifier<List<Object?>?> selectionsNotifier = itemContext
        .dataContext
        .subscribeToObjectArray(choicePickerData.value);
    final ValueNotifier<List<Object?>?> optionsNotifier = itemContext
        .dataContext
        .subscribeToObjectArray(choicePickerData.options);

    return ValueListenableBuilder<List<Object?>?>(
      valueListenable: selectionsNotifier,
      builder: (context, selections, child) {
        return ValueListenableBuilder<List<Object?>?>(
          valueListenable: optionsNotifier,
          builder: (context, options, child) {
            if (options == null) {
              return const SizedBox.shrink();
            }
            return Column(
              children: options.map((optionObj) {
                final option = optionObj as JsonMap;
                final Object? labelObj = option['label'];
                final ValueNotifier<String?> labelNotifier;
                if (labelObj is String) {
                  labelNotifier = ValueNotifier<String?>(labelObj);
                } else {
                  labelNotifier = itemContext.dataContext.subscribeToString(
                    labelObj as JsonMap?,
                  );
                }
                final value = option['value'] as String;
                return ValueListenableBuilder<String?>(
                  valueListenable: labelNotifier,
                  builder: (context, label, child) {
                    if (choicePickerData.usageHint == 'mutuallyExclusive') {
                      final Object? groupValue = selections?.isNotEmpty == true
                          ? selections!.first
                          : null;
                      return RadioListTile<String>(
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        title: Text(
                          label ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: value,
                        // ignore: deprecated_member_use
                        groupValue: groupValue is String ? groupValue : null,
                        // ignore: deprecated_member_use
                        onChanged: (newValue) {
                          final path =
                              choicePickerData.value['path'] as String?;
                          if (path == null || newValue == null) {
                            return;
                          }
                          itemContext.dataContext.update(DataPath(path), [
                            newValue,
                          ]);
                        },
                      );
                    } else {
                      return CheckboxListTile(
                        title: Text(label ?? ''),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selections?.contains(value) ?? false,
                        onChanged: (newValue) {
                          final path =
                              choicePickerData.value['path'] as String?;
                          if (path == null) {
                            return;
                          }
                          final List<String> newSelections =
                              selections?.map((e) => e.toString()).toList() ??
                              <String>[];
                          if (newValue ?? false) {
                            if (!newSelections.contains(value)) {
                              newSelections.add(value);
                            }
                          } else {
                            newSelections.remove(value);
                          }
                          itemContext.dataContext.update(
                            DataPath(path),
                            newSelections,
                          );
                        },
                      );
                    }
                  },
                );
              }).toList(),
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
          "component": "Column",
          "children": {
            "explicitList": [
              "heading1",
              "singleChoice",
              "heading2",
              "multiChoice"
            ]
          }
        },
        {
          "id": "heading1",
          "component": "Text",
          "text": {
            "literalString": "Single Selection (mutuallyExclusive)"
          }
        },
        {
          "id": "singleChoice",
          "component": "ChoicePicker",
          "value": {
            "path": "/singleSelection"
          },
          "usageHint": "mutuallyExclusive",
          "options": {
            "literalArray": [
              {
                "label": {
                  "literalString": "Option A"
                },
                "value": "A"
              },
              {
                "label": {
                  "literalString": "Option B"
                },
                "value": "B"
              }
            ]
          }
        },
        {
          "id": "heading2",
          "component": "Text",
          "text": {
            "literalString": "Multiple Selections"
          }
        },
        {
          "id": "multiChoice",
          "component": "ChoicePicker",
          "value": {
            "path": "/multiSelection"
          },
          "options": {
            "literalArray": [
              {
                "label": {
                  "literalString": "Option X"
                },
                "value": "X"
              },
              {
                "label": {
                  "literalString": "Option Y"
                },
                "value": "Y"
              },
              {
                "label": {
                  "literalString": "Option Z"
                },
                "value": "Z"
              }
            ]
          }
        }
      ]
    ''',
  ],
);
