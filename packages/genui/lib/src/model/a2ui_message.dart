// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import 'a2ui_schemas.dart';
import 'catalog.dart';

/// Returns the JSON schema for an A2UI message, parameterized by [catalog].
///
/// The message types themselves live in `package:a2ui_core`; this schema is
/// GenUI-specific because it is parameterized by the renderer's [Catalog].
Schema a2uiMessageSchema(Catalog catalog) => _buildA2uiMessageSchema(catalog);

Schema _buildA2uiMessageSchema(Catalog catalog) {
  return S.combined(
    title: 'A2UI Message Schema',
    description:
        'Describes a JSON payload for an A2UI (Agent to UI) message, '
        'which is used to dynamically construct and update user interfaces.',
    oneOf: [
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'createSurface': A2uiSchemas.createSurfaceSchema(),
        },
        required: ['version', 'createSurface'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'updateComponents': A2uiSchemas.updateComponentsSchema(catalog),
        },
        required: ['version', 'updateComponents'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'updateDataModel': A2uiSchemas.updateDataModelSchema(),
        },
        required: ['version', 'updateDataModel'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: 'v0.9'),
          'deleteSurface': A2uiSchemas.deleteSurfaceSchema(),
        },
        required: ['version', 'deleteSurface'],
        additionalProperties: false,
      ),
    ],
  );
}
