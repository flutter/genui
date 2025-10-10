// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'catalog_item.dart';
import 'data_model.dart';
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
  /// field in the [widgetData] map and uses its `widgetBuilder` to construct
  /// the widget.
  ///
  /// * [widgetData]: The deserialized JSON data for the widget to build.
  /// * [buildChild]: A function that can be called to recursively build child
  ///   widgets by their ID.
  /// * [dispatchEvent]: A callback to send UI events, like button presses or
  ///   value changes, back to the model.
  /// * [context]: The build context for the widget.
  Widget buildWidget({
    required String id,
    required JsonMap widgetData,
    required Widget Function(String id) buildChild,
    required DispatchEventCallback dispatchEvent,
    required BuildContext context,
    required DataContext dataContext,
  }) {
    final widgetType = widgetData.keys.firstOrNull;
    final item = items.firstWhereOrNull((item) => item.name == widgetType);
    if (item == null) {
      genUiLogger.severe('Item $widgetType was not found in catalog');
      return Container();
    }

    genUiLogger.info('Building widget ${item.name} with id $id');
    return item.widgetBuilder(
      data: widgetData[widgetType]! as JsonMap,
      id: id,
      buildChild: buildChild,
      dispatchEvent: dispatchEvent,
      context: context,
      dataContext: dataContext,
    );
  }

  /// A dynamically generated [Schema] that describes all widgets in the
  /// catalog.
  ///
  /// This schema is a "one-of" object, where the `widget` property can be one
  /// of the schemas from the [items] in the catalog. This is used to inform
  /// the generative AI model about the available UI components and their
  /// expected data structures.
  Schema get definition {
    final componentProperties = {
      for (var item in items) item.name: item.dataSchema,
    };

    return S.object(
      title: 'A2UI Catalog Description Schema',
      description:
          'A schema for a custom Catalog Description including A2UI '
          'components and styles.',
      properties: {
        'components': S.object(
          title: 'A2UI Components',
          description:
              'A schema that defines a catalog of A2UI components. '
              'Each key is a component name, and each value is the JSON '
              'schema for that component\'s properties.',
          properties: componentProperties,
        ),
        'styles': S.object(
          title: 'A2UI Styles',
          description:
              'A schema that defines a catalog of A2UI styles. Each key is a '
              'style name, and each value is the JSON schema for that style\'s '
              'properties.',
          properties: {},
        ),
      },
      required: ['components', 'styles'],
    );
  }
}
