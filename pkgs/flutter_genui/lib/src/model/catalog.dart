// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import 'catalog_item.dart';

class Catalog {
  Catalog(this.items);

  final List<CatalogItem> items;

  Widget buildWidget(
    Map<String, Object?>
        data, // The actual deserialized JSON data for this layout
    Widget Function(String id) buildChild,
    void Function({
      required String widgetId,
      required String eventType,
      required Object? value,
    })
        dispatchActionEvent,
    void Function({
      required String widgetId,
      required String eventType,
      required Object? value,
    })
        dispatchChangeEvent,
    BuildContext context,
  ) {
    try {
      final widgetData = data['widget'] as Map<String, Object?>?;
      if (widgetData == null || widgetData.isEmpty) {
        return Container();
      }
      final widgetType = widgetData.keys.first;
      final item = items.firstWhereOrNull((item) => item.name == widgetType);
      if (item == null) {
        return Container();
      }

      return item.widgetBuilder(
        data: widgetData[widgetType]!,
        id: data['id'] as String,
        buildChild: buildChild,
        dispatchActionEvent: dispatchActionEvent,
        dispatchChangeEvent: dispatchChangeEvent,
        context: context,
      );
    } catch (e) {
      return Container();
    }
  }

  Schema get schema {
    // Dynamically build schema properties from supported layouts
    final schemaProperties = {
      for (var item in items) item.name: item.dataSchema,
    };
    final optionalSchemaProperties = [for (var item in items) item.name];

    return Schema.object(
      description:
          'Represents a *single* widget in a UI widget tree. '
          'This widget could be one of many supported types.',
      properties: {
        'id': Schema.string(),
        'widget': Schema.object(
          description:
              'The properties of the specific widget '
              'that this represents. This is a oneof - only *one* '
              'field should be set on this object!',
          properties: schemaProperties,
          optionalProperties: optionalSchemaProperties,
        ),
      },
    );
  }
}