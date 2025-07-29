import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../catalog_item.dart';

final _schema = Schema.object(
  properties: {
    'child': Schema.string(
      description: 'The ID of a child widget.',
    ),
  },
);

Widget _builder(
    dynamic data, // The actual deserialized JSON data for this layout
    String id,
    Widget Function(String id) buildChild,
    void Function(String widgetId, String eventType, Object? value)
        dispatchEvent,
    BuildContext context) {
  /// The ID of the child widget to display inside the button.
  final childId = data['child'] as String;
  final child = buildChild(childId);
  return ElevatedButton(
    onPressed: () => dispatchEvent(id, 'onTap', null),
    child: child,
  );
}

final elevatedButtonCatalogItem = CatalogItem(
  name: 'elevated_button',
  dataSchema: _schema,
  widgetBuilder: _builder,
);
