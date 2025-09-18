// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../primitives/simple_items.dart';
import 'ui_models.dart';

/// A callback that builds a child widget for a catalog item.
typedef ChildBuilderCallback = Widget Function(String id);

/// A callback that builds a child widget for a catalog item.
typedef ExampleBuilderCallback = JsonMap Function();

/// Store for widget values by surfaceId.
class WidgetValueStore {
  final Map<String, JsonMap> _values = {};

  JsonMap forSurface(String surfaceId) {
    return _values.putIfAbsent(surfaceId, () => {});
  }

  void delete(String surfaceId) {
    _values.remove(surfaceId);
  }
}

/// A callback that builds a widget for a catalog item.
typedef CatalogWidgetBuilder =
    Widget Function({
      // The actual deserialized JSON data for this widget. The format of this
      // data will exactly match [CatalogItem.dataSchema].
      required Object data,
      // The ID of this widget.
      required String id,
      // A function used to build a child based on the given ID.
      required ChildBuilderCallback buildChild,
      // A function used to dispatch an event.
      required DispatchEventCallback dispatchEvent,

      required BuildContext context,
      // The current values of all widgets on the surface.
      required JsonMap values,
    });

/// Defines a UI layout type, its schema, and how to build its widget.
@immutable
class CatalogItem {
  /// Creates a new [CatalogItem].
  const CatalogItem({
    required this.name,
    required this.dataSchema,
    required this.widgetBuilder,
    this.exampleData = const [],
  });

  /// The widget type name used in JSON, e.g., 'TextChatMessage'.
  final String name;

  /// The schema definition for this widget's data.
  final Schema dataSchema;

  /// The builder for this widget.
  final CatalogWidgetBuilder widgetBuilder;

  /// List of examples for this widget, for testing purposes.
  ///
  /// To catch real data returned by the AI,
  /// [configure logging](https://github.com/flutter/genui/blob/main/packages/flutter_genui/USAGE.md#configure-logging)
  /// to Level.ALL and search for the string `"definition": {` in the logs.
  final List<ExampleBuilderCallback> exampleData;
}
