// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../../flutter_genui.dart';

typedef CatalogChildBuilder = Widget Function(String id);

/// Represents a collection of UI components that a generative AI model can use
/// to construct a user interface.
///
/// A [Catalog] serves two primary purposes:
/// 1. It holds a list of [CatalogItem]s, which define the available widgets.
/// 2. It provides a mechanism to build a Flutter widget from a JSON-like data
///    structure (`Map<String, Object?>`).
/// 3. It dynamically generates a [Schema] that describes the structure of all
///    supported widgets, which can be provided to the AI model.
class Catalog {
  /// Creates a new catalog with the given list of [items].
  const Catalog(this.items);

  /// The list of [CatalogItem]s available in this catalog.
  final List<CatalogItem> items;

  /// Builds a Flutter widget from a JSON-like data structure.
  ///
  /// This method looks up the appropriate [CatalogItem] based on the `widget`
  /// field in the [data] map and uses its `widgetBuilder` to construct the
  /// widget.
  ///
  /// * [data]: The deserialized JSON data for the widget to build.
  /// * [buildChild]: A function that can be called to recursively build child
  ///   widgets by their ID.
  /// * [dispatchEvent]: A callback to send UI events, like button presses or
  ///   value changes, back to the model.
  /// * [context]: The build context for the widget.
  Widget buildWidget(
    Map<String, Object?>
    data, // The actual deserialized JSON data for this layout
    Widget Function(String id) buildChild,
    DispatchEventCallback dispatchEvent,
    BuildContext context,
  ) {
    final widgetType = (data['widget'] as Map<String, Object?>).keys.first;
    final item = items.firstWhereOrNull((item) => item.name == widgetType);
    if (item == null) {
      print('Item $widgetType was not found in catalog');
      return Container();
    }

    return item.widgetBuilder(
      data: ((data as Map)['widget'] as Map<String, Object?>)[widgetType]!,
      id: data['id'] as String,
      buildChild: buildChild,
      dispatchEvent: dispatchEvent,
      context: context,
    );
  }

  /// A dynamically generated [Schema] that describes all widgets in the
  /// catalog.
  ///
  /// This schema is a "one-of" object, where the `widget` property can be one
  /// of the schemas from the [items] in the catalog. This is used to inform the
  /// generative AI model about the available UI components and their expected
  /// data structures.
  Schema get schema {
    // Dynamically build schema properties from supported layouts
    final schemaProperties = {
      for (var item in items) item.name: item.dataSchema,
    };

    return S.object(
      description:
          'Represents a *single* widget in a UI widget tree. '
          'This widget could be one of many supported types.',
      properties: {
        'id': S.string(),
        'widget': S.object(
          description:
              'The properties of the specific widget '
              'that this represents. This is a oneof - only *one* '
              'field should be set on this object!',
          properties: schemaProperties,
        ),
      },
      required: ['id', 'widget'],
    );
  }
}
