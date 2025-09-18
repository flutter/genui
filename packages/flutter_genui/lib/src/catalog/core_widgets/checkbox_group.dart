// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'values': S.list(
      items: S.boolean(),
      description: 'The values of the checkboxes.',
    ),
    'labels': S.list(
      items: S.string(),
      description: 'A list of labels for the checkboxes.',
    ),
  },
  required: ['values', 'labels'],
);

extension type _CheckboxGroupData.fromMap(JsonMap _json) {
  factory _CheckboxGroupData({
    required List<bool> values,
    required List<String> labels,
  }) => _CheckboxGroupData.fromMap({'values': values, 'labels': labels});

  List<bool> get values => (_json['values'] as List).cast<bool>();
  List<String> get labels => (_json['labels'] as List).cast<String>();
}

class _CheckboxGroup extends StatefulWidget {
  const _CheckboxGroup({
    required this.initialValues,
    required this.labels,
    required this.onChanged,
  });

  final List<bool> initialValues;
  final List<String> labels;
  final void Function(List<bool>) onChanged;

  @override
  State<_CheckboxGroup> createState() => _CheckboxGroupState();
}

class _CheckboxGroupState extends State<_CheckboxGroup> {
  late List<bool> _values;

  @override
  void initState() {
    super.initState();
    _values = List.from(widget.initialValues);
  }

  @override
  void didUpdateWidget(_CheckboxGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValues != oldWidget.initialValues) {
      _values = List.from(widget.initialValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < widget.labels.length; i++)
          CheckboxListTile(
            title: Text(widget.labels[i]),
            value: _values[i],
            onChanged: (bool? newValue) {
              if (newValue == null) return;
              setState(() {
                _values[i] = newValue;
              });
              widget.onChanged(_values);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }
}

final checkboxGroup = CatalogItem(
  name: 'CheckboxGroup',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final checkboxData = _CheckboxGroupData.fromMap(data as JsonMap);
        return _CheckboxGroup(
          initialValues: checkboxData.values,
          labels: checkboxData.labels,
          onChanged: (newValues) {
            values[id] = {
              for (var i = 0; i < newValues.length; i++)
                checkboxData.labels[i]: newValues[i],
            };
          },
        );
      },
);
