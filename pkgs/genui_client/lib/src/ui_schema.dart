import 'package:firebase_ai/firebase_ai.dart';

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
final flutterUiDefinition = Schema.object(
  properties: {
    'responseText': Schema.string(
      description: 'The text response to the user query. This should be used '
          'when the query is fully satisfied and no more information is '
          'needed.',
    ),
    'actions': Schema.array(
      description: 'A list of actions to be performed on the UI surfaces.',
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
                items: Schema.object(
                  properties: {
                    'id': Schema.string(
                      description:
                          'A unique identifier for the widget instance.',
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
                      properties: {
                        'alignment': Schema.string(
                          description: 'The alignment of the child. See '
                              'Flutter\'s Alignment for possible values. '
                              'Required for Align widgets.',
                        ),
                        'child': Schema.string(
                          description:
                              'The ID of a child widget. Required for Align, '
                              'ElevatedButton, and Padding widgets.',
                        ),
                        'children': Schema.array(
                          items: Schema.string(),
                          description: 'A list of widget IDs for the '
                              'children. Required for Column and Row widgets.',
                        ),
                        'crossAxisAlignment': Schema.string(
                          description:
                              'How children are aligned on the cross axis. '
                              'See Flutter\'s CrossAxisAlignment for values. '
                              'Required for Column and Row widgets.',
                        ),
                        'data': Schema.string(
                          description:
                              'The text content. Required for Text widgets.',
                        ),
                        'divisions': Schema.integer(
                          description: 'The number of discrete intervals on '
                              'the slider. Required for Slider widgets.',
                        ),
                        'fontSize': Schema.number(
                          description: 'The font size for the text. Required '
                              'for Text widgets.',
                        ),
                        'fontWeight': Schema.string(
                          description: 'The font weight (e.g., "bold"). '
                              'Required for Text widgets.',
                        ),
                        'groupValue': Schema.string(
                          description: 'The currently selected value for a '
                              'group of radio buttons. The type of this '
                              'property should match the type of the "value" '
                              'property. Required for Radio widgets.',
                        ),
                        'hintText': Schema.string(
                          description: 'Hint text for the text field. '
                              'Required for TextField widgets.',
                        ),
                        'label': Schema.string(
                          description: 'A label displayed next to the widget. '
                              'Required for Checkbox and Radio widgets.',
                        ),
                        'mainAxisAlignment': Schema.string(
                          description:
                              'How children are aligned on the main axis. '
                              'See Flutter\'s MainAxisAlignment for values. '
                              'Required for Column and Row widgets.',
                        ),
                        'max': Schema.number(
                          description: 'The maximum value for the slider. '
                              'Required for Slider widgets.',
                        ),
                        'min': Schema.number(
                          description: 'The minimum value for the slider. '
                              'Required for Slider widgets.',
                        ),
                        'obscureText': Schema.boolean(
                          description:
                              'Whether the text should be obscured (e.g., for '
                              'passwords). Required for TextField widgets.',
                        ),
                        'padding': Schema.object(
                          properties: {
                            'left': Schema.number(),
                            'top': Schema.number(),
                            'right': Schema.number(),
                            'bottom': Schema.number(),
                          },
                          description: 'The padding around the child. '
                              'Required for Padding widgets.',
                        ),
                        'value': Schema.string(
                          description:
                              'The value of the widget. Type varies: String '
                              'for TextField, boolean for Checkbox, double for '
                              'Slider, and any type for Radio. Required for '
                              'TextField, Checkbox, Radio, and Slider widgets.',
                        ),
                      },
                      optionalProperties: [
                        'alignment',
                        'child',
                        'children',
                        'crossAxisAlignment',
                        'data',
                        'divisions',
                        'fontSize',
                        'fontWeight',
                        'groupValue',
                        'hintText',
                        'label',
                        'mainAxisAlignment',
                        'max',
                        'min',
                        'obscureText',
                        'padding',
                        'value',
                      ],
                      description:
                          'A map of properties specific to this widget type. '
                          'Its structure depends on the value of the "type" '
                          'field.',
                    ),
                  },
                  optionalProperties: ['props'],
                ),
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
