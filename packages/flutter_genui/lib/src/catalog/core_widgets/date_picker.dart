// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/catalog_item.dart';
import '../../model/ui_models.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'value': S.string(
      description: 'The initial date of the date picker in yyyy-mm-dd format.',
      format: 'date',
    ),
    'hintText': S.string(description: 'Hint text for the date picker.'),
  },
);

extension type _DatePickerData.fromMap(JsonMap _json) {
  factory _DatePickerData({String? value, String? hintText}) =>
      _DatePickerData.fromMap({'value': value, 'hintText': hintText});

  String? get value => _json['value'] as String?;
  String? get hintText => _json['hintText'] as String?;
}

class _DatePicker extends StatefulWidget {
  const _DatePicker({
    this.initialValue,
    this.hintText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String? initialValue;
  final String? hintText;
  final void Function(String) onChanged;
  final void Function(String) onSubmitted;

  @override
  State<_DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<_DatePicker> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _selectedDate = DateTime.tryParse(widget.initialValue!);
    }
  }

  @override
  void didUpdateWidget(_DatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null) {
        _selectedDate = DateTime.tryParse(widget.initialValue!);
      } else {
        _selectedDate = null;
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      widget.onChanged(formattedDate);
      widget.onSubmitted(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _selectDate(context),
      child: Text(
        _selectedDate == null
            ? widget.hintText ?? 'Select date'
            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
      ),
    );
  }
}

final datePicker = CatalogItem(
  name: 'DatePicker',
  dataSchema: _schema,
  exampleData: [
    () => {
      'root': 'date_picker',
      'widgets': [
        {
          'id': 'date_picker',
          'widget': {
            'DatePicker': {
              'value': '2025-07-22',
              'hintText': 'Select your birth date',
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
        required values,
      }) {
        final datePickerData = _DatePickerData.fromMap(data as JsonMap);
        return _DatePicker(
          initialValue: datePickerData.value,
          hintText: datePickerData.hintText,
          onChanged: (newValue) => values[id] = newValue,
          onSubmitted: (newValue) {
            dispatchEvent(
              UiActionEvent(
                widgetId: id,
                eventType: 'onSubmitted',
                value: newValue,
              ),
            );
          },
        );
      },
);
