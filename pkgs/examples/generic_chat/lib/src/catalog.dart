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
    void Function(String widgetId, String eventType, Object? value)
        dispatchEvent,
    BuildContext context,
  ) {
    final widgetType = (data['widget'] as Map<String, Object?>).keys.first;
    final item = items.firstWhereOrNull((item) => item.name == widgetType);
    if (item == null) {
      print('Item $widgetType was not found in catalog');
      return Container();
    }

    return item.widgetBuilder(
      (data['widget'] as Map<String, Object?>)[widgetType],
      data['id'] as String,
      buildChild,
      dispatchEvent,
      context,
    );
  }

  Schema get schema {
    // Dynamically build schema properties from supported layouts
    final schemaProperties = {
      for (var item in items) item.name: item.dataSchema,
    };
    final optionalSchemaProperties = [
      for (var item in items) item.name,
    ];

    return Schema.object(
        description:
            'Represents a *single* widget in a UI widget tree. This widget could be one of many supported types.',
        properties: {
          'id': Schema.string(),
          'widget': Schema.object(
              description:
                  'The properties of the specific widget that this represents. This is a oneof - only *one* field should be set on this object!',
              properties: schemaProperties,
              optionalProperties: optionalSchemaProperties),
        });
  }
}
