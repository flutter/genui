// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The tag that opens a Direct JSON payload block.
const String directJsonOpenTag = '<a2ui-json>';

/// The tag that closes a Direct JSON payload block.
const String directJsonCloseTag = '</a2ui-json>';

/// The tag that opens the catalog schema section of the system prompt.
const String a2uiSchemaOpenTag = '<a2ui_schema>';

/// The tag that closes the catalog schema section of the system prompt.
const String a2uiSchemaCloseTag = '</a2ui_schema>';

/// The A2UI message envelopes an agent may emit.
const List<String> a2uiMessageEnvelopes = [
  'createSurface',
  'updateComponents',
  'updateDataModel',
  'deleteSurface',
];
