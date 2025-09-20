// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:intl/intl.dart';

final _schema = S.object(
  properties: {
    'value': S.string(
      description: 'The initial date of the date picker in yyyy-mm-dd format.',
    ),
    'label': S.string(description: 'Label for the date picker.'),
  },
);

extension type _DatePickerData.fromMap(JsonMap _json) {
  factory _DatePickerData({String? value, String? label}) =>
      _DatePickerData.fromMap({'value': value, 'label': label});

  String? get value => _json['value'] as String?;
  String? get label => _json['label'] as String?;
}

class _DatePicker extends StatefulWidget {
  const _DatePicker({this.initialValue, this.label, required this.onChanged});

  final String? initialValue;
  final String? label;
  final void Function(String) onChanged;

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
      firstDate: DateTime(1700),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      widget.onChanged(formattedDate);
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
        _selectDate(context);
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
              'value': '1871-07-22',
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
        required values,
      }) {
        final datePickerData = _DatePickerData.fromMap(data as JsonMap);
        return _DatePicker(
          initialValue: datePickerData.value,
          label: datePickerData.label,
          onChanged: (newValue) => values[id] = newValue,
        );
      },
);
