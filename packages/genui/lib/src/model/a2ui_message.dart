// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:json_schema_builder/json_schema_builder.dart';

import 'a2ui_schemas.dart';
import 'catalog.dart';

/// Returns the JSON schema for an A2UI message, parameterized by [catalog].
///
/// The message types themselves live in `package:a2ui_core`; this schema is
/// GenUI-specific because it is parameterized by the renderer's [Catalog].
Schema a2uiMessageSchema(Catalog catalog) {
  return S.combined(
    title: 'A2UI Message Schema',
    description:
        'Describes a JSON payload for an A2UI (Agent to UI) message, '
        'which is used to dynamically construct and update user interfaces.',
    oneOf: [
      S.object(
        properties: {
          'version': S.string(constValue: core.a2uiProtocolVersion),
          'createSurface': A2uiSchemas.createSurfaceSchema(),
        },
        required: ['version', 'createSurface'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: core.a2uiProtocolVersion),
          'updateComponents': A2uiSchemas.updateComponentsSchema(catalog),
        },
        required: ['version', 'updateComponents'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: core.a2uiProtocolVersion),
          'updateDataModel': A2uiSchemas.updateDataModelSchema(),
        },
        required: ['version', 'updateDataModel'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: core.a2uiProtocolVersion),
          'deleteSurface': A2uiSchemas.deleteSurfaceSchema(),
        },
        required: ['version', 'deleteSurface'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: core.a2uiProtocolVersion),
          'functionCallId': S.string(
            description:
                'Unique ID for the instance of this function call. It is '
                'copied verbatim into the functionResponse or error.',
          ),
          'wantResponse': S.boolean(
            description:
                'If true, the client returns a functionResponse with the '
                'result of the call.',
          ),
          'callFunction': A2uiSchemas.callFunctionSchema(),
        },
        required: ['version', 'callFunction', 'functionCallId'],
        additionalProperties: false,
      ),
      S.object(
        properties: {
          'version': S.string(constValue: core.a2uiProtocolVersion),
          'actionId': S.string(
            description: 'The ID of the action call this response belongs to.',
          ),
          'actionResponse': A2uiSchemas.actionResponseSchema(),
        },
        required: ['version', 'actionResponse', 'actionId'],
        additionalProperties: false,
      ),
    ],
  );
}
