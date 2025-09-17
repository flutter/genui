// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'catalog_item.dart';
import 'ui_models.dart';

/// Represents a collection of UI components that a generative AI model can use
/// to construct a user interface.
///
/// A [Catalog] serves three primary purposes:
/// 1. It holds a list of [CatalogItem]s, which define the available widgets.
/// 2. It provides a mechanism to build a Flutter widget from a JSON-like data
///    structure ([JsonMap]).
/// 3. It dynamically generates a [Schema] that describes the structure of all
///    supported widgets, which can be provided to the AI model.
@immutable
class Catalog {
  /// Creates a new catalog with the given list of items.
  const Catalog(this.items);

  /// The list of [CatalogItem]s available in this catalog.
  final Iterable<CatalogItem> items;

  /// Returns a new [Catalog] containing the items from both this catalog and
  /// the provided [items].
  ///
  /// If an item with the same name already exists in the catalog, it will be
  /// replaced with the new item.
  Catalog copyWith(List<CatalogItem> newItems) {
    final itemsByName = {for (final item in items) item.name: item};
    itemsByName.addAll({for (final item in newItems) item.name: item});
    return Catalog(itemsByName.values);
  }

  /// Returns a new [Catalog] instance containing the items from this catalog
  /// with the specified items removed.
  Catalog copyWithout(Iterable<String> itemNames) {
    final namesToRemove = itemNames.toSet();
    final updatedItems = items
        .where((item) => !namesToRemove.contains(item.name))
        .toList();
    return Catalog(updatedItems);
  }

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
    JsonMap data, // The actual deserialized JSON data for this layout
    Widget Function(String id) buildChild,
    DispatchEventCallback dispatchEvent,
    BuildContext context,
    JsonMap valueStore,
  ) {
    final widgetType = (data['widget'] as JsonMap).keys.firstOrNull;
    final item = items.firstWhereOrNull((item) => item.name == widgetType);
    if (item == null) {
      genUiLogger.severe('Item $widgetType was not found in catalog');
      return Container();
    }

    genUiLogger.info('Building widget ${item.name} with id ${data['id']}');
    return item.widgetBuilder(
      data: ((data as Map)['widget'] as JsonMap)[widgetType]!,
      id: data['id'] as String,
      buildChild: buildChild,
      dispatchEvent: dispatchEvent,
      context: context,
      values: valueStore,
    );
  }

  /// A dynamically generated [Schema] that describes all widgets in the
  /// catalog.
  ///
  /// This schema is a "one-of" object, where the `widget` property can be one
  /// of the schemas from the [items] in the catalog. This is used to inform
  /// the generative AI model about the available UI components and their
  /// expected data structures.
  Schema get schema {
    // Dynamically build schema properties from supported layouts
    final schemaProperties = [
      for (var item in items)
        Schema.object(
          properties: {item.name: item.dataSchema},
          required: [item.name],
        ),
    ];

    return S.object(
      description:
          'Represents a *single* widget in a UI widget tree. '
          'This widget could be one of many supported types.',
      properties: {
        'id': S.string(),
        'widget': Schema.combined(
          description:
              'A wrapper object for a single widget definition. It MUST '
              'contain exactly one key, where the key is the name of a '
              'widget type (e.g., "Column", "Text", "ElevatedButton") from the '
              'list of allowed properties. The value is an object containing '
              'the definition of that widget using its properties. '
              'For example: `{"TypeOfWidget": {"widget_property": "Value of '
              'property"}}`',
          anyOf: schemaProperties,
        ),
      },
      required: ['id', 'widget'],
    );
  }
}
