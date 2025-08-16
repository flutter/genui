// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';

final textCatalogItem = CatalogItem(
  name: 'Text',
  definition: WidgetDefinition(
    properties:
        Schema.object(
              properties: {
                'text': Schema.string(description: 'The text to display.'),
              },
              required: ['text'],
            )
            as ObjectSchema,
  ),
  builder: (context, node, properties, children) {
    return Text(properties['text'] as String);
  },
);

final textFieldCatalogItem = CatalogItem(
  name: 'TextField',
  definition: WidgetDefinition(
    properties:
        Schema.object(
              properties: {
                'hintText': Schema.string(
                  description:
                      'The hint text to display in '
                      'the text field when it is empty.',
                ),
              },
            )
            as ObjectSchema,
  ),
  builder: (context, node, properties, children) {
    return TextField(
      decoration: InputDecoration(hintText: properties['hintText'] as String?),
    );
  },
);

final elevatedButtonCatalogItem = CatalogItem(
  name: 'ElevatedButton',
  definition: WidgetDefinition(
    properties:
        Schema.object(
              properties: {
                'child': Schema.string(
                  description:
                      'The ID of the widget to display inside the button. '
                      'This widget must be defined in the `nodes` list.',
                ),
              },
              required: ['child'],
            )
            as ObjectSchema,
  ),
  builder: (context, node, properties, children) {
    return ElevatedButton(
      onPressed: () {
        FcpProvider.of(context)?.onEvent?.call(
          EventPayload(sourceNodeId: node.id, eventName: 'onPressed'),
        );
      },
      child: children['child']!.first,
    );
  },
);

final columnCatalogItem = CatalogItem(
  name: 'Column',
  definition: WidgetDefinition(
    properties:
        Schema.object(
              properties: {
                'children': Schema.list(
                  items: Schema.string(),
                  description:
                      'A list of widget IDs to display in the column. '
                      'These widgets must be defined in the `nodes` list.',
                ),
              },
            )
            as ObjectSchema,
  ),
  builder: (context, node, properties, children) {
    return Column(children: children['children'] ?? []);
  },
);

final exampleCatalog = WidgetCatalogRegistry()
  ..register(textCatalogItem)
  ..register(textFieldCatalogItem)
  ..register(elevatedButtonCatalogItem)
  ..register(columnCatalogItem);
