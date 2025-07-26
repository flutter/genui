import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';

typedef CatalogWidgetBuilder = Widget Function(
  dynamic data, // The actual deserialized JSON data for this layout
  String id,
  Widget Function(String id) buildChild,
  void Function(String widgetId, String eventType, Object? value) dispatchEvent,
  BuildContext context,
);

/// Defines a UI layout type, its schema, and how to build its widget.
class CatalogItem {
  final String name; // The key used in JSON, e.g., 'text_chat_message'
  final Schema dataSchema; // The schema definition for this layout's data
  final CatalogWidgetBuilder widgetBuilder;

  CatalogItem({
    required this.name,
    required this.dataSchema,
    required this.widgetBuilder,
  });
}
