// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:intl/intl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  properties: {
    'value': A2uiSchemas.stringReference(
      description: 'The initial date of the date picker in yyyy-mm-dd format.',
    ),
    'label': S.string(description: 'Label for the date picker.'),
  },
);

extension type _DatePickerData.fromMap(JsonMap _json) {
  factory _DatePickerData({JsonMap? value, String? label}) =>
      _DatePickerData.fromMap({'value': value, 'label': label});

  JsonMap? get value => _json['value'] as JsonMap?;
  String? get label => _json['label'] as String?;
}

class _DateInputChip extends StatefulWidget {
  const _DateInputChip({
    this.initialValue,
    this.label,
    required this.onChanged,
  });

  final String? initialValue;
  final String? label;
  final void Function(String) onChanged;

  @override
  State<_DateInputChip> createState() => _DateInputChipState();
}

class _DateInputChipState extends State<_DateInputChip> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _selectedDate = DateTime.tryParse(widget.initialValue!);
    }
  }

  @override
  void didUpdateWidget(_DateInputChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null) {
        _selectedDate = DateTime.tryParse(widget.initialValue!);
      } else {
        _selectedDate = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _selectedDate == null
        ? widget.label ?? 'Date'
        : '${widget.label}: ${DateFormat.yMMMd().format(_selectedDate!)}';
    return FilterChip(
      label: Text(text),
      selected: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onSelected: (bool selected) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    child: CalendarDatePicker(
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1700),
                      lastDate: DateTime(2101),
                      onDateChanged: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                        final formattedDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(newDate);
                        widget.onChanged(formattedDate);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

final dateInputChip = CatalogItem(
  name: 'DateInputChip',
  dataSchema: _schema,
  exampleData: [
    () => {
      'root': 'date_picker',
      'widgets': [
        {
          'id': 'date_picker',
          'widget': {
            'DateInputChip': {
              'value': {'literalString': '1871-07-22'},
              'label': 'Your birth date',
            },
          },
        },
      ],
    },
  ],
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final datePickerData = _DatePickerData.fromMap(data as JsonMap);
        final notifier = dataContext.subscribeToString(datePickerData.value);
        final path = datePickerData.value?['path'] as String?;

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, currentValue, child) {
            return _DateInputChip(
              initialValue: currentValue,
              label: datePickerData.label,
              onChanged: (newValue) {
                if (path != null) {
                  dataContext.update(path, newValue);
                }
              },
            );
          },
        );
      },
);
