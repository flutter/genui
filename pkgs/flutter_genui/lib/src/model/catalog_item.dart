import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

typedef CatalogWidgetBuilder =
    Widget Function({
      // The actual deserialized JSON data for this widget. The format of this
      // data will exactly match dataSchema below.
      required Object data,
      required String id, // The ID of this widget.
      required Widget Function(String id)
      buildChild, // A function used to build a child based on the given ID.
      required void Function({
        required String widgetId,
        required String eventType,
        required Object? value,
      })
      dispatchEvent, // A function used to dispatch an event.
      required BuildContext context, // The build context.
    });

/// Defines a UI layout type, its schema, and how to build its widget.
class CatalogItem {
  final String name; // The key used in JSON, e.g., 'text_chat_message'
  final Schema dataSchema; // The schema definition for this widget's data.
  final CatalogWidgetBuilder widgetBuilder;

  CatalogItem({
    required this.name,
    required this.dataSchema,
    required this.widgetBuilder,
  });
}
