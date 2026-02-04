// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';
import '../../widgets/widget_utilities.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['ChoicePicker']),
    'label': A2uiSchemas.stringReference(
      description: 'The label for the group of options.',
    ),
    'variant': S.string(
      description:
          'A hint for how the choice picker should be displayed and behave.',
      enumValues: ['multipleSelection', 'mutuallyExclusive'],
    ),
    'options': S.list(
      description: 'The list of available options to choose from.',
      items: S.object(
        properties: {
          'label': A2uiSchemas.stringReference(
            description: 'The text to display for this option.',
          ),
          'value': S.string(
            description: 'The stable value associated with this option.',
          ),
        },
        required: ['label', 'value'],
      ),
    ),
    'value': A2uiSchemas.stringArrayReference(
      description: 'The list of currently selected values.',
    ),
  },
  required: ['component', 'options', 'value'],
);

extension type _ChoicePickerData.fromMap(JsonMap _json) {
  Object? get label => _json['label'];
  String? get variant => _json['variant'] as String?;
  List<JsonMap> get options => (_json['options'] as List).cast<JsonMap>();
  Object get value => _json['value'] as Object;
}

/// A component that allows selecting one or more options from a list.
final choicePicker = CatalogItem(
  name: 'ChoicePicker',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final data = _ChoicePickerData.fromMap(itemContext.data as JsonMap);

    final Object valueRef = data.value;
    final path = (valueRef is Map && valueRef.containsKey('path'))
        ? valueRef['path'] as String
        : '${itemContext.id}.value';

    final ValueNotifier<List<Object?>?> selectionsNotifier = itemContext
        .dataContext
        .subscribeToObjectArray({'path': path});

    final isMutuallyExclusive = data.variant == 'mutuallyExclusive';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
            child: ValueListenableBuilder<String?>(
              valueListenable: itemContext.dataContext.subscribeToString(
                data.label!,
              ),
              builder: (context, label, child) {
                if (label == null || label.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
          ),
        ValueListenableBuilder<List<Object?>?>(
          valueListenable: selectionsNotifier,
          builder: (context, currentSelections, child) {
            var effectiveSelections = currentSelections;
            if (effectiveSelections == null) {
              if (valueRef is List) {
                effectiveSelections = valueRef;
              } else if (valueRef is String) {
                effectiveSelections = [valueRef];
              }
            }
            final List<String> currentStrings =
                effectiveSelections?.map((e) => e.toString()).toList() ?? [];

            return Column(
              children: data.options.map((option) {
                final ValueNotifier<String?> labelNotifier = itemContext
                    .dataContext
                    .subscribeToString(option['label']);
                final optionValue = option['value'] as String;

                return ValueListenableBuilder<String?>(
                  valueListenable: labelNotifier,
                  builder: (context, label, child) {
                    if (isMutuallyExclusive) {
                      final Object? groupValue = currentStrings.isNotEmpty
                          ? currentStrings.first
                          : null;

                      return RadioListTile<String>(
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        title: Text(
                          label ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: optionValue,
                        // ignore: deprecated_member_use
                        groupValue: groupValue is String ? groupValue : null,
                        // ignore: deprecated_member_use
                        onChanged: (newValue) {
                          if (newValue == null) {
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
                        value: currentStrings.contains(optionValue),
                        onChanged: (newValue) {
                          final newSelections = List<String>.from(
                            currentStrings,
                          );

                          if (newValue == true) {
                            if (!newSelections.contains(optionValue)) {
                              newSelections.add(optionValue);
                            }
                          } else {
                            newSelections.remove(optionValue);
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
        ),
      ],
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Column",
          "children": ["heading1", "radio", "heading2", "check"]
        },
        { "id": "heading1", "component": "Text", "text": "Mutually Exclusive", "variant": "h4" },
        { "id": "radio", "component": "ChoicePicker", "variant": "mutuallyExclusive", "label": "Choose one", "value": ["A"], "options": [ { "label": "A", "value": "A" }, { "label": "B", "value": "B" } ] },
        { "id": "heading2", "component": "Text", "text": "Multiple Selection", "variant": "h4" },
        { "id": "check", "component": "ChoicePicker", "variant": "multipleSelection", "label": "Choose many", "value": { "path": "/multi" }, "options": [ { "label": "X", "value": "X" }, { "label": "Y", "value": "Y" } ] }
      ]
    ''',
  ],
);
