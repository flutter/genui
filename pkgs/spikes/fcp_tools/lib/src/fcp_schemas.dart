// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';

final fcpPropertySchema = Schema.object(
  properties: {
    'name': Schema.string(description: 'The name of the property.'),
    'value': Schema.any(description: 'The value of the property.'),
  },
  required: ['name', 'value'],
);

final fcpBindingSchema = Schema.object(
  properties: {
    'name': Schema.string(description: 'The name of the property to bind.'),
    'path': Schema.string(
      description: 'The path to the value in the state object.',
    ),
  },
  required: ['name', 'path'],
);

/// A schema for a single layout node in an FCP packet.
final fcpLayoutNodeSchema = Schema.object(
  properties: {
    'id': Schema.string(
      description:
          'A unique identifier for this widget. This is used to '
          'refer to the widget in the layout and in event handlers.',
    ),
    'type': Schema.string(
      description:
          'The type of the widget. This must be one of the widget '
          'types available in the widget catalog.',
    ),
    'properties': Schema.list(
      description:
          'A list of static properties for this widget. The keys and values '
          'of this map must conform to the schema of the widget type.',
      items: fcpPropertySchema,
    ),
    'bindings': Schema.list(
      description:
          'A list of dynamic properties for this widget. The keys of this map '
          'must be valid properties for the widget type, and the values must '
          'be objects with a "path" property that points to a value in the '
          'state.',
      items: fcpBindingSchema,
    ),
  },
  required: ['id', 'type'],
);

/// A schema for the layout of an FCP packet.
final fcpLayoutSchema = Schema.object(
  properties: {
    'root': Schema.string(
      description:
          'The ID of the root widget. This widget will be the '
          'first widget to be rendered.',
    ),
    'nodes': Schema.list(
      description: 'A list of all the widgets in the layout.',
      items: fcpLayoutNodeSchema,
    ),
  },
  required: ['root', 'nodes'],
);

/// A schema for the state of an FCP packet.
final fcpStateSchema = Schema.list(
  description:
      'A list of key-value pairs representing the state of the UI. '
      'The keys of this map can be any string, and the values can be any valid '
      'JSON object. The state is used to store dynamic data that can be '
      'referenced by the widgets in the layout.',
  items: fcpPropertySchema,
);

/// A schema for a single layout patch operation.
final fcpLayoutOperationSchema = Schema.object(
  properties: {
    'op': Schema.string(
      description: 'The operation to perform.',
      enumValues: ['add', 'remove', 'replace'],
    ),
    'path': Schema.string(
      description:
          'A JSON Pointer (RFC 6901) path to the location in the layout to '
          'modify.',
    ),
    'value': Schema.any(
      description:
          'The value to apply. For "add" and "replace", this is the new '
          'content. For "remove", this is ignored.',
    ),
  },
  required: ['op', 'path'],
);
