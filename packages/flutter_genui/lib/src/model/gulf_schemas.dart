// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';

/// Provides a set of pre-defined, reusable schema objects for common
/// GULF patterns, simplifying the creation of CatalogItem definitions.
class GulfSchemas {
  /// Schema for a value that can be either a literal string or a
  /// data-bound path to a string in the DataModel.
  static final Schema stringReference = S.object(
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalString': S.string(),
    },
  );

  /// Schema for a value that can be either a literal number or a
  /// data-bound path to a number in the DataModel.
  static final Schema numberReference = S.object(
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalNumber': S.number(),
    },
  );

  /// Schema for a value that can be either a literal boolean or a
  /// data-bound path to a boolean in the DataModel.
  static final Schema booleanReference = S.object(
    properties: {
      'path': S.string(
        description: 'A relative or absolute path in the data model.',
      ),
      'literalBoolean': S.boolean(),
    },
  );

  /// Schema for a property that holds a reference to a single child
  /// component by its ID.
  static final Schema componentReference = S.string();

  /// Schema for a property that holds a list of child components,
  /// either as an explicit list of IDs or a data-bound template.
  static final Schema componentArrayReference = S.object(
    properties: {
      'explicitList': S.list(items: componentReference),
      'template': S.object(
        properties: {'componentId': S.string(), 'dataBinding': S.string()},
        required: ['componentId', 'dataBinding'],
      ),
    },
  );

  /// Schema for a user-initiated action, including the action name
  /// and a context map of key-value pairs.
  static final Schema action = S.object(
    properties: {
      'action': S.string(),
      'context': S.list(
        items: S.object(
          properties: {
            'key': S.string(),
            'value': S.object(
              properties: {
                'path': S.string(),
                'literalString': S.string(),
                'literalNumber': S.number(),
                'literalBoolean': S.boolean(),
              },
            ),
          },
          required: ['key', 'value'],
        ),
      ),
    },
    required: ['action'],
  );
}
