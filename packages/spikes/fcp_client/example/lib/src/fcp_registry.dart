// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';

import 'widgets/widgets.dart';

/// Creates and registers all the widget builders for the FCP client.
WidgetCatalogRegistry createRegistry() {
  final registry = WidgetCatalogRegistry();

  registry.register(
    CatalogItem(
      name: 'Text',
      builder: (context, node, properties, children) {
        return Text(properties['data'] as String? ?? '');
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'data': Schema.string(description: 'The text to display.'),
          },
          required: ['data'],
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'Container',
      builder: (context, node, properties, children) {
        return FcpContainer(properties: properties, children: children);
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'child': Schema.string(description: 'The child widget to display.'),
            'width': Schema.number(description: 'The width of the container.'),
            'height': Schema.number(
              description: 'The height of the container.',
            ),
            'color': Schema.string(description: 'The color of the container.'),
          },
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'Column',
      builder: (context, node, properties, children) {
        return FcpColumn(
          properties: properties,
          children: children['children'] ?? [],
        );
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'children': Schema.list(
              items: Schema.string(),
              description: 'The list of child widgets.',
            ),
            'mainAxisAlignment': Schema.string(
              description:
                  'How the children should be placed along the main axis.',
              enumValues: MainAxisAlignment.values.map((e) => e.name).toList(),
            ),
            'crossAxisAlignment': Schema.string(
              description:
                  'How the children should be placed along the cross axis.',
              enumValues: CrossAxisAlignment.values.map((e) => e.name).toList(),
            ),
          },
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'Row',
      builder: (context, node, properties, children) {
        return FcpRow(
          properties: properties,
          children: children['children'] ?? [],
        );
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'children': Schema.list(
              items: Schema.string(),
              description: 'The list of child widgets.',
            ),
            'mainAxisAlignment': Schema.string(
              description:
                  'How the children should be placed along the main axis.',
              enumValues: MainAxisAlignment.values.map((e) => e.name).toList(),
            ),
            'crossAxisAlignment': Schema.string(
              description:
                  'How the children should be placed along the cross axis.',
              enumValues: CrossAxisAlignment.values.map((e) => e.name).toList(),
            ),
          },
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'ElevatedButton',
      builder: (context, node, properties, children) {
        return FcpElevatedButton(
          node: node,
          properties: properties,
          child: children['child']?.first,
        );
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'child': Schema.string(description: 'The child widget to display.'),
            'onPressed': Schema.object(
              description: 'The event to fire when the button is pressed.',
            ),
          },
        ),
        events: ObjectSchema(
          properties: {'onPressed': Schema.object(properties: {})},
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'ListViewBuilder',
      builder: (context, node, properties, children) {
        // This is a special-cased widget handled by the FcpView itself.
        // This builder should not be called.
        return const SizedBox.shrink();
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'data': Schema.list(description: 'The list of data to display.'),
          },
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'Icon',
      builder: (context, node, properties, children) {
        return FcpIcon(properties: properties);
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'icon': Schema.string(
              description: 'The name of the icon to display.',
            ),
          },
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'SizedBox',
      builder: (context, node, properties, children) {
        return SizedBox(
          width: (properties['width'] as num?)?.toDouble(),
          height: (properties['height'] as num?)?.toDouble(),
        );
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'width': Schema.number(description: 'The width of the box.'),
            'height': Schema.number(description: 'The height of the box.'),
          },
        ),
      ),
    ),
  );

  registry.register(
    CatalogItem(
      name: 'Padding',
      builder: (context, node, properties, children) {
        return Padding(
          padding: EdgeInsets.all((properties['padding'] as num).toDouble()),
          child: children['child']?.first,
        );
      },
      definition: WidgetDefinition(
        properties: ObjectSchema(
          properties: {
            'padding': Schema.number(
              description: 'The amount of padding to apply.',
            ),
            'child': Schema.string(description: 'The child widget to display.'),
          },
        ),
      ),
    ),
  );

  return registry;
}
