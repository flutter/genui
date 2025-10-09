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
    'selectedValues': A2uiSchemas.stringArrayReference(
      description: 'The values of the checkboxes.',
    ),
    'labels': S.list(
      items: S.string(),
      description: 'A list of all available labels for the checkboxes.',
    ),
  },
  required: ['selectedValues', 'labels'],
);

extension type _CheckboxGroupData.fromMap(JsonMap _json) {
  factory _CheckboxGroupData({
    required JsonMap selectedValues,
    required List<String> labels,
  }) => _CheckboxGroupData.fromMap({
    'selectedValues': selectedValues,
    'labels': labels,
  });

  JsonMap get selectedValues => _json['selectedValues'] as JsonMap;
  List<String> get labels => (_json['labels'] as List).cast<String>();
}

class _CheckboxGroup extends StatefulWidget {
  const _CheckboxGroup({
    required this.selectedValues,
    required this.allLabels,
    required this.onChanged,
  });

  final Set<String> selectedValues;
  final List<String> allLabels;
  final void Function(Set<String>) onChanged;

  @override
  State<_CheckboxGroup> createState() => _CheckboxGroupState();
}

class _CheckboxGroupState extends State<_CheckboxGroup> {
  late Set<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = Set.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(_CheckboxGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValues != oldWidget.selectedValues) {
      _selectedValues = Set.from(widget.selectedValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final label in widget.allLabels)
          CheckboxListTile(
            title: Text(label),
            value: _selectedValues.contains(label),
            onChanged: (bool? newValue) {
              if (newValue == null) return;
              final newSelectedValues = Set<String>.from(_selectedValues);
              if (newValue) {
                newSelectedValues.add(label);
              } else {
                newSelectedValues.remove(label);
              }
              setState(() {
                _selectedValues = newSelectedValues;
              });
              widget.onChanged(newSelectedValues);
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
  exampleData: [
    () => {
      'root': 'checkbox_group',
      'widgets': [
        {
          'id': 'checkbox_group',
          'widget': {
            'CheckboxGroup': {
              'selectedValues': {'path': 'selected'},
              'labels': ['Option 1', 'Option 2', 'Option 3'],
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
        final checkboxData = _CheckboxGroupData.fromMap(data as JsonMap);
        final valuesRef = checkboxData.selectedValues;
        final path = valuesRef['path'] as String?;
        final notifier = dataContext.subscribeToStringArray(valuesRef);

        return ValueListenableBuilder<List<dynamic>?>(
          valueListenable: notifier,
          builder: (context, currentSelectedValues, child) {
            final selectedValuesSet = (currentSelectedValues ?? [])
                .cast<String>()
                .toSet();
            return _CheckboxGroup(
              selectedValues: selectedValuesSet,
              allLabels: checkboxData.labels,
              onChanged: (newSelectedValues) {
                if (path != null) {
                  dataContext.update(path, newSelectedValues.toList());
                }
              },
            );
          },
        );
      },
);
