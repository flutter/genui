import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'submitLabel': Schema.string(
      description: 'The label for the submit button.',
    ),
    'children': Schema.array(
      description: 'A list of widget IDs for the children.',
      items: Schema.string(),
    ),
  },
);

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
        final submitLabel = (data as Map)['submitLabel'] as String;
        final children = (data['children'] as List).cast<String>();

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
                    widgetId: id,
                    eventType: 'submit',
                    value: null,
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
