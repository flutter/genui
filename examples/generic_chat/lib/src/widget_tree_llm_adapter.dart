import 'package:firebase_ai/firebase_ai.dart';

import 'catalog.dart';

class WidgetTreeLlmAdapter {
  WidgetTreeLlmAdapter(this.catalog);

  final Catalog catalog;

  /// A schema for defining a simple UI tree to be rendered by Flutter.
  ///
  /// This schema is a Dart conversion of a more complex JSON schema.
  /// Due to limitations in the Dart `Schema` builder API (specifically the lack
  /// of support for discriminated unions or `anyOf`), this conversion makes a
  /// practical compromise.
  ///
  /// It strictly enforces the structure of the `root` object, requiring `id`
  /// and `type` for every widget in the `widgets` list. The `props` field
  /// within each widget is defined as a `Schema.object` with all possible
  /// properties for all widget types. The application logic should validate the
  /// contents of `props` based on the widget's `type`.
  ///
  /// This approach ensures that the fundamental structure of the UI definition
  /// is always valid according to the schema.
  Schema get outputSchema => Schema.object(
        properties: {
          'responseText': Schema.string(
            description:
                'The text response to the user query. This should be used '
                'when the query is fully satisfied and no more information is '
                'needed.',
          ),
          'actions': Schema.array(
            description:
                'A list of actions to be performed on the UI surfaces.',
            items: Schema.object(
              properties: {
                'action': Schema.enumString(
                  description: 'The action to perform on the UI surface.',
                  enumValues: ['add', 'update', 'delete'],
                ),
                'surfaceId': Schema.string(
                  description:
                      'The ID of the surface to perform the action on. For the '
                      '`add` action, this will be a new surface ID. For `update` and '
                      '`delete`, this will be an existing surface ID.',
                ),
                'definition': Schema.object(
                  properties: {
                    'root': Schema.string(
                      description: 'The ID of the root widget.',
                    ),
                    'widgets': Schema.array(
                      items: catalog.schema,
                      description: 'A list of widget definitions.',
                    ),
                  },
                  description:
                      'A schema for defining a simple UI tree to be rendered by '
                      'Flutter.',
                ),
              },
              optionalProperties: ['surfaceId', 'definition'],
            ),
          ),
        },
        description: 'A schema for defining a simple UI tree to be rendered by '
            'Flutter.',
        optionalProperties: ['actions', 'responseText'],
      );
}
