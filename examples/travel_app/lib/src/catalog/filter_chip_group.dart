// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  properties: {
    'submitLabel': S.string(description: 'The label for the submit button.'),
    'children': S.list(
      description: 'A list of widget IDs for the children.',
      items: S.string(),
    ),
  },
  required: ['submitLabel', 'children'],
);

extension type _FilterChipGroupData.fromMap(Map<String, Object?> _json) {
  factory _FilterChipGroupData({
    required String submitLabel,
    required List<String> children,
  }) => _FilterChipGroupData.fromMap({
    'submitLabel': submitLabel,
    'children': children,
  });

  String get submitLabel => _json['submitLabel'] as String;
  List<String> get children => (_json['children'] as List).cast<String>();
}

/// A container widget that visually groups a collection of filter chips.
///
/// This component is designed to present the user with multiple categories of
/// choices (e.g., "Budget", "Activity Type", "Duration"). Each choice is
/// managed by a child chip. The `filterChipGroup` provides a single "Submit"
/// button that, when pressed, dispatches a single event. This signals the AI
/// to process the current selections from all the child chips at once, which
/// is useful for refining a search or query with multiple parameters.
final filterChipGroup = CatalogItem(
  name: 'filterChipGroup',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final filterChipGroupData = _FilterChipGroupData.fromMap(
          data as Map<String, Object?>,
        );
        final submitLabel = filterChipGroupData.submitLabel;
        final children = filterChipGroupData.children;

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
                      value: null,
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
