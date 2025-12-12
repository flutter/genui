// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import 'catalog.dart';
import 'tools.dart';

/// Provides a set of pre-defined, reusable schema objects for common
/// A2UI patterns, simplifying the creation of CatalogItem definitions.
class A2uiSchemas {
  /// Schema for a value that can be either a literal string or a
  /// data-bound path to a string in the DataModel. If both path and
  /// literal are provided, the value at the path will be initialized
  /// with the literal.
  ///
  /// If `enumValues` are provided, the string value (either literal or at the
  /// path) must be one of the values in the enum.
  static Schema stringReference({
    String? description,
    List<String>? enumValues,
  }) => S.object(
    description: description,
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
        enumValues: enumValues,
      ),
      'literalString': S.string(enumValues: enumValues),
    },
  );

  /// Schema for a value that can be either a literal number or a
  /// data-bound path to a number in the DataModel. If both path and
  /// literal are provided, the value at the path will be initialized
  /// with the literal.
  static Schema numberReference({String? description}) => S.object(
    description: description,
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalNumber': S.number(),
    },
  );

  /// Schema for a value that can be either a literal boolean or a
  /// data-bound path to a boolean in the DataModel. If both path and
  /// literal are provided, the value at the path will be initialized
  /// with the literal.
  static Schema booleanReference({String? description}) => S.object(
    description: description,
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalBoolean': S.boolean(),
    },
  );

  /// Schema for a property that holds a reference to a single child
  /// component by its ID.
  static Schema componentReference({String? description}) =>
      S.string(description: description);

  /// Schema for a property that holds a list of child components,
  /// either as an explicit list of IDs or a data-bound template.
  static Schema componentArrayReference({String? description}) => S.object(
    description: description,
    properties: {
      'explicitList': S.list(items: componentReference()),
      'template': S.object(
        properties: {'componentId': S.string(), 'dataBinding': S.string()},
        required: ['componentId', 'dataBinding'],
      ),
    },
  );

  /// Schema for a user-initiated action, including the action name
  /// and a context map of key-value pairs.
  static Schema action({String? description}) => S.object(
    description: description,
    properties: {
      'name': S.string(),
      'context': S.list(
        description:
            'A list of name-value pairs to be sent with the action to include '
            'data associated with the action, e.g. values that are submitted.',
        items: S.object(
          properties: {
            'key': S.string(),
            'value': S.object(
              properties: {
                'path': S.string(
                  description:
                      'A path in the data model which should be bound to an '
                      'input element, e.g. a string reference for a text '
                      'field, or number reference for a slider.',
                ),
                'literalString': S.string(
                  description: 'A literal string relevant to the action',
                ),
                'literalNumber': S.number(
                  description: 'A literal number relevant to the action',
                ),
                'literalBoolean': S.boolean(
                  description: 'A literal boolean relevant to the action',
                ),
              },
            ),
          },
          required: ['key', 'value'],
        ),
      ),
    },
    required: ['name'],
  );

  /// Schema for a value that can be either a literal array of strings or a
  /// data-bound path to an array of strings in the DataModel. If both path and
  /// literalArray are provided, the value at the path will be
  /// initialized with the literalArray.
  static Schema stringArrayReference({String? description}) => S.object(
    description: description,
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalArray': S.list(items: S.string()),
    },
  );

  /// Schema for a beginRendering message, which provides the root widget ID for
  /// the given surface so that the surface can be rendered.
  static Schema beginRenderingSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(
        description: 'The surface ID of the surface to render.',
      ),
      'root': S.string(
        description:
            'The root widget ID for the surface. '
            'All components must be descendents of this root in order to be '
            'displayed.',
      ),
      'catalogId': S.string(
        description:
            'The identifier of the component catalog to use for this surface.',
      ),
      'styles': S.object(
        properties: {
          'font': S.string(description: 'The base font for this surface'),
          'primaryColor': S.string(
            description: 'The seed color for the theme of this surface.',
          ),
        },
      ),
    },
    required: [surfaceIdKey, 'root'],
  );

  /// Schema for a beginRendering message, which provides the root widget ID for
  /// the given surface so that the surface can be rendered.
  static Schema beginRenderingSchemaNoCatalogId() => S.object(
    properties: {
      surfaceIdKey: S.string(
        description: 'The surface ID of the surface to render.',
      ),
      'root': S.string(
        description:
            'The root widget ID for the surface. '
            'All components must be descendents of this root in order to be '
            'displayed.',
      ),
      'styles': S.object(
        properties: {
          'font': S.string(description: 'The base font for this surface'),
          'primaryColor': S.string(
            description: 'The seed color for the theme of this surface.',
          ),
        },
      ),
    },
    required: [surfaceIdKey, 'root'],
  );

  /// Schema for a `deleteSurface` message which will delete the given surface.
  static Schema surfaceDeletionSchema() => S.object(
    properties: {surfaceIdKey: S.string()},
    required: [surfaceIdKey],
  );

  /// Schema for a `dataModelUpdate` message which will update the given path in
  /// the data model. If the path is omitted, the entire data model is replaced.
  static Schema dataModelUpdateSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(),
      'path': S.string(),
      'contents': S.any(
        description: 'The new contents to write to the data model.',
      ),
    },
    required: [surfaceIdKey, 'contents'],
  );

  /// Schema for a `surfaceUpdate` message which defines the components to be
  /// rendered on a surface.
  static Schema surfaceUpdateSchema(Catalog catalog) => S.object(
    properties: {
      surfaceIdKey: S.string(
        description:
            'The unique identifier for the UI surface to create or '
            'update. If you are adding a new surface this *must* be a '
            'new, unique identified that has never been used for any '
            'existing surfaces shown.',
      ),
      'components': S.list(
        description: 'A list of component definitions.',
        minItems: 1,
        items: S.object(
          description:
              'Represents a *single* component in a UI widget tree. '
              'This component could be one of many supported types.',
          properties: {
            'id': S.string(),
            'weight': S.integer(
              description:
                  'Optional layout weight for use in Row/Column children.',
            ),
            'component': S.object(
              description:
                  '''A wrapper object that MUST contain exactly one key, which is the name of the component type (e.g., 'Text'). The value is an object containing the properties for that specific component.''',
              properties: {
                for (var entry
                    in ((catalog.definition as ObjectSchema)
                                .properties!['components']!
                            as ObjectSchema)
                        .properties!
                        .entries)
                  entry.key: entry.value,
              },
            ),
          },
          required: ['id', 'component'],
        ),
      ),
    },
    required: [surfaceIdKey, 'components'],
  );
}
