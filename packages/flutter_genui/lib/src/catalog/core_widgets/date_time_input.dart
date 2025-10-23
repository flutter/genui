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
    'value': A2uiSchemas.stringReference(
      description: 'The selected date and/or time.',
    ),
    'enableDate': S.boolean(),
    'enableTime': S.boolean(),
    'outputFormat': S.string(),
  },
  required: ['value'],
);

extension type _DateTimeInputData.fromMap(JsonMap _json) {
  factory _DateTimeInputData({
    required JsonMap value,
    bool? enableDate,
    bool? enableTime,
    String? outputFormat,
  }) => _DateTimeInputData.fromMap({
    'value': value,
    'enableDate': enableDate,
    'enableTime': enableTime,
    'outputFormat': outputFormat,
  });

  JsonMap get value => _json['value'] as JsonMap;
  bool get enableDate => (_json['enableDate'] as bool?) ?? true;
  bool get enableTime => (_json['enableTime'] as bool?) ?? true;
  String? get outputFormat => _json['outputFormat'] as String?;
}

final dateTimeInput = CatalogItem(
  name: 'DateTimeInput',
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
        final dateTimeInputData = _DateTimeInputData.fromMap(data as JsonMap);
        final valueNotifier = dataContext.subscribeToString(
          dateTimeInputData.value,
        );

        return ValueListenableBuilder<String?>(
          valueListenable: valueNotifier,
          builder: (context, value, child) {
            return ListTile(
              title: Text(value ?? 'Select a date/time'),
              onTap: () async {
                final path = dateTimeInputData.value['path'] as String?;
                if (path == null) {
                  return;
                }
                if (dateTimeInputData.enableDate) {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    dataContext.update(path, date.toIso8601String());
                  }
                }
                if (dateTimeInputData.enableTime) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    dataContext.update(path, time.format(context));
                  }
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
            "DateTimeInput": {
              "value": {
                "path": "/myDateTime"
              }
            }
          }
        }
      ]
    ''',
  ],
);
