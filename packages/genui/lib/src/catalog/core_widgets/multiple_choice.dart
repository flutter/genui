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
    'selections': A2uiSchemas.stringArrayReference(),
    'options': S.list(
      items: S.object(
        properties: {
          'label': A2uiSchemas.stringReference(),
          'value': S.string(),
        },
        required: ['label', 'value'],
      ),
    ),
    'maxAllowedSelections': S.integer(),
  },
  required: ['selections', 'options'],
);

extension type _MultipleChoiceData.fromMap(JsonMap _json) {
  factory _MultipleChoiceData({
    required JsonMap selections,
    required List<JsonMap> options,
    int? maxAllowedSelections,
  }) => _MultipleChoiceData.fromMap({
    'selections': selections,
    'options': options,
    'maxAllowedSelections': maxAllowedSelections,
  });

  JsonMap get selections => _json['selections'] as JsonMap;
  List<JsonMap> get options => (_json['options'] as List).cast<JsonMap>();
  int? get maxAllowedSelections =>
      (_json['maxAllowedSelections'] as num?)?.toInt();
}

/// A catalog item representing a multiple choice selection widget.
///
/// This widget displays a list of options, each with a checkbox. The
/// `selections` parameter, which should be a data model path, is updated to
/// reflect the list of *values* of the currently selected options.
///
/// ## Parameters:
///
/// - `selections`: A list of the values of the selected options.
/// - `options`: A list of options to display, each with a `label` and a
///   `value`.
/// - `maxAllowedSelections`: The maximum number of options that can be
///   selected.
final multipleChoice = CatalogItem(
  name: 'MultipleChoice',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final multipleChoiceData = _MultipleChoiceData.fromMap(
      itemContext.data as JsonMap,
    );
    final ValueNotifier<List<Object?>?> selectionsNotifier = itemContext
        .dataContext
        .subscribeToObjectArray(multipleChoiceData.selections);

    return ValueListenableBuilder<List<Object?>?>(
      valueListenable: selectionsNotifier,
      builder: (context, selections, child) {
        return Column(
          children: multipleChoiceData.options.map((option) {
            final ValueNotifier<String?> labelNotifier = itemContext.dataContext
                .subscribeToString(option['label'] as JsonMap);
            final value = option['value'] as String;
            return ValueListenableBuilder<String?>(
              valueListenable: labelNotifier,
              builder: (context, label, child) {
                if (multipleChoiceData.maxAllowedSelections == 1) {
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
                          multipleChoiceData.selections['path'] as String?;
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
                          multipleChoiceData.selections['path'] as String?;
                      if (path == null) {
                        return;
                      }
                      final List<String> newSelections =
                          selections?.map((e) => e.toString()).toList() ??
                          <String>[];
                      if (newValue ?? false) {
                        if (multipleChoiceData.maxAllowedSelections == null ||
                            newSelections.length <
                                multipleChoiceData.maxAllowedSelections!) {
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
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Column": {
              "children": {
                "explicitList": [
                  "heading1",
                  "singleChoice",
                  "heading2",
                  "multiChoice"
                ]
              }
            }
          }
        },
        {
          "id": "heading1",
          "component": {
            "Text": {
              "text": {
                "literalString": "Single Selection (maxAllowedSelections: 1)"
              }
            }
          }
        },
        {
          "id": "singleChoice",
          "component": {
            "MultipleChoice": {
              "selections": {
                "path": "/singleSelection"
              },
              "maxAllowedSelections": 1,
              "options": [
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
          }
        },
        {
          "id": "heading2",
          "component": {
            "Text": {
              "text": {
                "literalString": "Multiple Selections (unlimited)"
              }
            }
          }
        },
        {
          "id": "multiChoice",
          "component": {
            "MultipleChoice": {
              "selections": {
                "path": "/multiSelection"
              },
              "options": [
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
        }
      ]
    ''',
  ],
);
