// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  properties: {
    'submitLabel': S.string(description: 'The label for the submit button.'),
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
    required String submitLabel,
    required List<String> children,
  }) => _InputGroupData.fromMap({
    'submitLabel': submitLabel,
    'children': children,
  });

  String get submitLabel => _json['submitLabel'] as String;
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
  name: 'InputGroup',
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
        final inputGroupData = _InputGroupData.fromMap(
          data as Map<String, Object?>,
        );
        final submitLabel = inputGroupData.submitLabel;
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
                ElevatedButton(
                  onPressed: () => dispatchEvent(
                    UiActionEvent(
                      widgetId: id,
                      eventType: 'submit',
                      value: values,
                    ),
                  ),
                  child: Text(submitLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
);
