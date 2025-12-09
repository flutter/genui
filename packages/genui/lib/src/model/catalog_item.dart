// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'data_model.dart';
import 'ui_models.dart';

/// A callback to get a component definition by its ID.
typedef GetComponentCallback = Component? Function(String componentId);

/// A callback that builds a child widget for a catalog item.
typedef ChildBuilderCallback =
    Widget Function(String id, [DataContext? dataContext]);

/// A callback that builds an example of a catalog item.
///
/// The returned string must be a valid JSON representation of a list of
/// [Component] objects. One of the components in the list must have the `id`
/// 'root'.
typedef ExampleBuilderCallback = String Function();

/// A callback that builds a widget for a catalog item.
typedef CatalogWidgetBuilder = Widget Function(CatalogItemContext itemContext);

class CatalogItemContext {
  CatalogItemContext({
    required this.data,
    required this.id,
    required this.buildChild,
    required this.dispatchEvent,
    required this.buildContext,
    required this.dataContext,
    required this.getComponent,
    required this.surfaceId,
  });

  final Object data;
  final String id;
  final ChildBuilderCallback buildChild;
  final DispatchEventCallback dispatchEvent;
  final BuildContext buildContext;
  final DataContext dataContext;
  final GetComponentCallback getComponent;
  final String surfaceId;
}

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

  /// A list of builder functions that each return a JSON string representing an
  /// example usage of this widget.
  ///
  /// Each returned string must be a valid JSON representation of a list of
  /// [Component] objects. For the example to be renderable, one of the
  /// components in the list must have the `id` 'root', which will be used as
  /// the entry point for rendering.
  ///
  /// To catch real data returned by the AI for debugging or creating new
  /// examples, [configure logging](https://github.com/flutter/genui/blob/main/packages/genui/README.md#how-can-i-configure-logging)
  /// to `Level.ALL` and search for the string `"definition": {` in the logs.
  final List<ExampleBuilderCallback> exampleData;
}
