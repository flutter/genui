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
  int? get maxAllowedSelections => _json['maxAllowedSelections'] as int?;
}

final multipleChoice = CatalogItem(
  name: 'MultipleChoice',
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
        final multipleChoiceData = _MultipleChoiceData.fromMap(data as JsonMap);
        final selectionsNotifier = dataContext.subscribeToStringArray(
          multipleChoiceData.selections,
        );

        return ValueListenableBuilder<List<dynamic>?>(
          valueListenable: selectionsNotifier,
          builder: (context, selections, child) {
            return Column(
              children: multipleChoiceData.options.map((option) {
                final labelNotifier = dataContext.subscribeToString(
                  option['label'] as JsonMap,
                );
                final value = option['value'] as String;
                return ValueListenableBuilder<String?>(
                  valueListenable: labelNotifier,
                  builder: (context, label, child) {
                    return CheckboxListTile(
                      title: Text(label ?? ''),
                      value: selections?.contains(value) ?? false,
                      onChanged: (newValue) {
                        final path =
                            multipleChoiceData.selections['path'] as String?;
                        if (path == null) {
                          return;
                        }
                        final newSelections = List<String>.from(
                          selections ?? [],
                        );
                        if (newValue ?? false) {
                          newSelections.add(value);
                        } else {
                          newSelections.remove(value);
                        }
                        dataContext.update(path, newSelections);
                      },
                    );
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
            "MultipleChoice": {
              "selections": {
                "path": "/mySelections"
              },
              "options": [
                {
                  "label": {
                    "literalString": "Option 1"
                  },
                  "value": "1"
                },
                {
                  "label": {
                    "literalString": "Option 2"
                  },
                  "value": "2"
                }
              ]
            }
          }
        }
      ]
    ''',
  ],
);
