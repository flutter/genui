// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

/// Provides a set of pre-defined, reusable schema objects for common
/// A2UI patterns, simplifying the creation of CatalogItem definitions.
class A2uiSchemas {
  /// Schema for a value that can be either a literal string or a
  /// data-bound path to a string in the DataModel. If both path and
  /// literalString are provided, the value at the path will be initialized
  /// with the literalString.
  static Schema stringReference({String? description}) => S.object(
    description: description,
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalString': S.string(),
    },
  );

  /// Schema for a value that can be either a literal number or a
  /// data-bound path to a number in the DataModel. If both path and
  /// literalNumber are provided, the value at the path will be initialized
  /// with the literalNumber.
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
  /// literalBoolean are provided, the value at the path will be initialized
  /// with the literalBoolean.
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
      'actionName': S.string(
        description: 'The name of the action to be sent to the server.',
      ),
      'context': S.list(
        description:
            'A list of name-value pairs to be sent with the action. The '
            'values are bind to the data model with a path, and should bind '
            'to all of the related data for this action.',
        items: S.object(
          properties: {'key': S.string(), 'path': S.string()},
          required: ['key', 'path'],
        ),
      ),
    },
    required: ['actionName'],
  );

  /// Schema for a value that can be either a literal array of strings or a
  /// data-bound path to an array of strings in the DataModel. If both path and
  /// literalStringArray are provided, the value at the path will be
  /// initialized with the literalStringArray.
  static Schema stringArrayReference({String? description}) => S.object(
    description: description,
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalStringArray': S.list(items: S.string()),
    },
  );
}
