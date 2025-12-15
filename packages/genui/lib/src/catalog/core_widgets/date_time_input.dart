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

/// A catalog item representing a Material Design date and/or time input field.
///
/// This widget displays a field that, when tapped, opens the native date and/or
/// time pickers. The selected value is stored as a string in the data model
/// path specified by the `value` parameter.
///
/// ## Parameters:
///
/// - `value`: The selected date and/or time, as a string.
/// - `enableDate`: Whether to allow the user to select a date. Defaults to
///   `true`.
/// - `enableTime`: Whether to allow the user to select a time. Defaults to
///   `true`.
/// - `outputFormat`: The format to use for the output string.
final dateTimeInput = CatalogItem(
  name: 'DateTimeInput',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final dateTimeInputData = _DateTimeInputData.fromMap(
      itemContext.data as JsonMap,
    );
    final ValueNotifier<String?> valueNotifier = itemContext.dataContext
        .subscribeToString(dateTimeInputData.value);

    return ValueListenableBuilder<String?>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        final MaterialLocalizations localizations = MaterialLocalizations.of(
          context,
        );
        final String displayText = _getDisplayText(
          value,
          dateTimeInputData,
          localizations,
        );

        return ListTile(
          key: Key(itemContext.id),
          title: Text(displayText, key: Key('${itemContext.id}_text')),
          onTap: () => _handleTap(
            context: itemContext.buildContext,
            dataContext: itemContext.dataContext,
            data: dateTimeInputData,
            value: value,
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
            "DateTimeInput": {
              "value": {
                "path": "/myDateTime"
              }
            }
          }
        }
      ]
    ''',
    () => '''
       [
        {
          "id": "root",
          "component": {
            "DateTimeInput": {
              "value": {
                "path": "/myDate"
              },
              "enableTime": false,
              "outputFormat": "date_only"
            }
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": {
            "DateTimeInput": {
              "value": {
                "path": "/myTime"
              },
              "enableDate": false,
              "outputFormat": "time_only"
            }
          }
        }
      ]
    ''',
  ],
);

Future<void> _handleTap({
  required BuildContext context,
  required DataContext dataContext,
  required _DateTimeInputData data,
  required String? value,
}) async {
  final path = data.value['path'] as String?;
  if (path == null) {
    return;
  }

  final DateTime initialDate =
      DateTime.tryParse(value ?? '') ??
      DateTime.tryParse('1970-01-01T$value') ??
      DateTime.now();

  DateTime? newDate;
  if (data.enableDate) {
    newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (newDate == null) return; // User cancelled.
  } else {
    newDate = initialDate;
  }

  TimeOfDay? newTime;
  if (data.enableTime) {
    newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (newTime == null) {
      // User cancelled.
      return;
    }
  } else {
    newTime = TimeOfDay.fromDateTime(initialDate);
  }

  final finalDateTime = DateTime(
    newDate.year,
    newDate.month,
    newDate.day,
    data.enableTime ? newTime.hour : 0,
    data.enableTime ? newTime.minute : 0,
  );

  String formattedValue;
  final String? format = data.outputFormat;

  if (format == 'date_only' || (!data.enableTime && format == null)) {
    formattedValue = finalDateTime.toIso8601String().split('T').first;
  } else if (format == 'time_only' || (!data.enableDate && format == null)) {
    final String hour = finalDateTime.hour.toString().padLeft(2, '0');
    final String minute = finalDateTime.minute.toString().padLeft(2, '0');
    formattedValue = '$hour:$minute:00';
  } else {
    formattedValue = finalDateTime.toIso8601String();
  }

  dataContext.update(DataPath(path), formattedValue);
}

String _getDisplayText(
  String? value,
  _DateTimeInputData data,
  MaterialLocalizations localizations,
) {
  String getPlaceholderText() {
    if (data.enableDate && data.enableTime) {
      return 'Select a date and time';
    } else if (data.enableDate) {
      return 'Select a date';
    } else if (data.enableTime) {
      return 'Select a time';
    }
    return 'Select a date/time';
  }

  DateTime? tryParseDateOrTime(String value) {
    return DateTime.tryParse(value) ?? DateTime.tryParse('1970-01-01T$value');
  }

  String formatDateTime(DateTime date) {
    var datePart = '';
    var timePart = '';

    if (data.enableDate) {
      datePart = localizations.formatMediumDate(date);
    }

    if (data.enableTime) {
      timePart = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date));
    }

    if (data.enableDate && data.enableTime) {
      return '$datePart $timePart';
    } else if (data.enableDate) {
      return datePart;
    } else if (data.enableTime) {
      return timePart;
    }

    // Fallback if neither is enabled (shouldn't happen with defaults).
    return '$datePart $timePart'.trim();
  }

  if (value == null) {
    return getPlaceholderText();
  }

  final DateTime? date = tryParseDateOrTime(value);
  if (date == null) {
    return value;
  }

  return formatDateTime(date);
}
