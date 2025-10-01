// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/model/gulf_schemas.dart';

final _schema = S.object(
  properties: {
    'submitLabel': GulfSchemas.stringReference,
    'children': S.list(
      description:
          'A list of widget IDs for the input children, which must '
          'be input types such as OptionsFilterChipInput.',
      items: S.string(),
    ),
  },
  required: ['submitLabel', 'children'],
);

extension type _InputGroupData.fromMap(Map<String, Object?> _json) {
  factory _InputGroupData({
    required JsonMap submitLabel,
    required List<String> children,
  }) => _InputGroupData.fromMap({
    'submitLabel': submitLabel,
    'children': children,
  });

  JsonMap get submitLabel => _json['submitLabel'] as JsonMap;
  List<String> get children => (_json['children'] as List).cast<String>();
}

/// A container widget that visually groups a collection of input chips.
///
/// This component is designed to present the user with multiple categories of
/// choices (e.g., "Budget", "Activity Type", "Duration"). Each choice is
/// managed by a child chip. The [inputGroup] provides a single "Submit"
/// button that, when pressed, dispatches a single event. This signals the AI
/// to process the current selections from all the child chips at once, which
/// is useful for refining a search or query with multiple parameters.
final inputGroup = CatalogItem(
  exampleData: [
    () => {
      'root': 'input_group',
      'widgets': [
        {
          'id': 'input_group',
          'widget': {
            'Column': {
              'children': [
                'check_in',
                'check_out',
                'text_input1',
                'text_input2',
              ],
            },
          },
        },
        {
          'id': 'check_in',
          'widget': {
            'DateInputChip': {'value': '2026-07-22', 'label': 'Check-in date'},
          },
        },
        {
          'id': 'check_out',
          'widget': {
            'DateInputChip': {'label': 'Check-out date'},
          },
        },
        {
          'id': 'text_input1',
          'widget': {
            'TextInputChip': {
              'initialValue': 'John Doe',
              'label': 'Enter your name',
            },
          },
        },
        {
          'id': 'text_input2',
          'widget': {
            'TextInputChip': {'label': 'Enter your friend\'s name'},
          },
        },
      ],
    },
  ],
  name: 'InputGroup',
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
        final inputGroupData = _InputGroupData.fromMap(
          data as Map<String, Object?>,
        );
        
        final submitLabelRef = inputGroupData.submitLabel;
        final path = submitLabelRef['path'] as String?;
        final literal = submitLabelRef['literalString'] as String?;
        final notifier = path != null
            ? dataContext.subscribe<String>(path)
            : ValueNotifier<String?>(literal);

        final children = inputGroupData.children;

        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  runSpacing: 16.0,
                  spacing: 8.0,
                  children: children.map(buildChild).toList(),
                ),
                const SizedBox(height: 16.0),
                ValueListenableBuilder<String?>(
                  valueListenable: notifier,
                  builder: (context, submitLabel, child) {
                    return ElevatedButton(
                      onPressed: () => dispatchEvent(
                        UiActionEvent(
                          widgetId: id,
                          eventType: 'submit',
                          value: {},
                        ),
                      ),
                      child: Text(submitLabel ?? ''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        );
      },
);
