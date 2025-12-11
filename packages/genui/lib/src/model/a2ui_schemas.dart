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
      'context': S.object(
        description:
            'A map of name-value pairs to be sent with the action to include '
            'data associated with the action, e.g. values that are submitted.',
        additionalProperties: true,
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

  /// Schema for a value that can be either a literal array of objects (maps)
  /// or a data-bound path to an array of objects in the DataModel. If both
  /// path and literalArray are provided, the value at the path will be
  /// initialized with the literalArray.
  static Schema objectArrayReference({String? description}) => S.object(
    description: description,
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalArray': S.list(items: S.object(additionalProperties: true)),
    },
  );

  /// Schema for a createSurface message, which initializes a surface.
  static Schema createSurfaceSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(
        description: 'The surface ID of the surface to create.',
      ),
      'catalogId': S.string(
        description: 'The catalog ID to use for this surface.',
      ),
    },
    required: [surfaceIdKey, 'catalogId'],
  );

  /// Schema for a `deleteSurface` message which will delete the given surface.
  static Schema surfaceDeletionSchema() => S.object(
    properties: {surfaceIdKey: S.string()},
    required: [surfaceIdKey],
  );

  /// Schema for a `updateDataModel` message which will update the given path in
  /// the data model. If the path is omitted, the entire data model is replaced.
  static Schema updateDataModelSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(),
      'path': S.string(),
      'op': S.string(
        description: 'The operation to perform (add, replace, remove).',
        enumValues: ['add', 'replace', 'remove'],
      ),
      'value': S.any(description: 'The new value to write to the data model.'),
    },
    required: [surfaceIdKey, 'value'],
  );

  /// Schema for a `updateComponents` message which defines the components to be
  /// rendered on a surface.
  static Schema updateComponentsSchema(Catalog catalog) => S.object(
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
            'id': S.string(
              description:
                  'The unique identifier for this component. The root '
                  "component of the surface MUST have the id 'root'.",
            ),
            'weight': S.integer(
              description:
                  'Optional layout weight for use in Row/Column children.',
            ),
            'component': S.string(
              description: 'The type of the component.',
              enumValues:
                  ((catalog.definition as ObjectSchema)
                              .properties!['components']!
                          as ObjectSchema)
                      .properties!
                      .keys
                      .toList(),
            ),
          },
          required: ['id', 'component'],
          additionalProperties: true,
        ),
      ),
    },
    required: [surfaceIdKey, 'components'],
  );

  /// Schema for an `error` message which reports an error.
  static Schema errorSchema() => S.object(
    properties: {
      'code': S.string(),
      'message': S.string(),
      'surfaceId': S.string(),
      'path': S.string(),
    },
    required: ['code', 'message'],
  );
}
