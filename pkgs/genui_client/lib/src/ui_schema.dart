import 'package:firebase_ai/firebase_ai.dart';

/// A schema for defining a simple UI tree to be rendered by Flutter.
///
/// This schema is a Dart conversion of a more complex JSON schema.
/// Due to limitations in the Dart `Schema` builder API (specifically the lack
/// of support for discriminated unions or `anyOf`), this conversion makes a

/// practical compromise.
///
/// It strictly enforces the structure of the `root` object, requiring `id`
/// and `type` for every widget in the `widgets` list. However, the `props`
/// field within each widget is defined as a generic `Schema.object({})`.
/// This means that while the presence of `props` is optional, its internal
/// fields are not strictly typed at the schema level. The application logic
/// should validate the contents of `props` based on the widget's `type`.
///
/// This approach ensures that the fundamental structure of the UI definition
/// is always valid according to the schema.
final flutterUiDefinition = Schema.object(
  properties: {
    'root': Schema.string(
      description: 'The ID of the root widget.',
    ),
    'widgets': Schema.array(
      items: Schema.object(
        properties: {
          'id': Schema.string(
            description: 'A unique identifier for the widget instance.',
          ),
          'type': Schema.enumString(
            description: 'The type of the widget.',
            enumValues: [
              'Align',
              'Column',
              'Row',
              'Text',
              'TextField',
              'Checkbox',
              'Radio',
              'Slider',
              'ElevatedButton',
              'Padding',
            ],
          ),
          'props': Schema.object(
            properties: {},
            description: 'A map of properties specific to this widget type. '
                'Its structure depends on the value of the "type" field.',
          ),
        },
        optionalProperties: ['props'],
      ),
      description: 'A list of widget definitions.',
    ),
  },
  description: 'A schema for defining a simple UI tree to be rendered by '
      'Flutter.',
);
