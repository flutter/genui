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
  const Catalog(this.items, {this.catalogId});

  /// The list of [CatalogItem]s available in this catalog.
  final Iterable<CatalogItem> items;

  /// A string that uniquely identifies this catalog. It is recommended to use
  /// a reverse-domain name notation, e.g. 'com.example.my_catalog'.
  final String? catalogId;

  /// Returns a new [Catalog] containing the items from both this catalog and
  /// the provided [items].
  ///
  /// If an item with the same name already exists in the catalog, it will be
  /// replaced with the new item.
  Catalog copyWith(List<CatalogItem> newItems, {String? catalogId}) {
    final Map<String, CatalogItem> itemsByName = {
      for (final item in items) item.name: item,
    };
    itemsByName.addAll({for (final item in newItems) item.name: item});
    return Catalog(itemsByName.values, catalogId: catalogId ?? this.catalogId);
  }

  /// Returns a new [Catalog] instance containing the items from this catalog
  /// with the specified items removed.
  Catalog copyWithout(Iterable<CatalogItem> itemNames, {String? catalogId}) {
    final Set<String> namesToRemove = itemNames
        .map<String>((item) => item.name)
        .toSet();
    final List<CatalogItem> updatedItems = items
        .where((item) => !namesToRemove.contains(item.name))
        .toList();
    return Catalog(updatedItems, catalogId: catalogId ?? this.catalogId);
  }

  /// Builds a Flutter widget from a JSON-like data structure.
  Widget buildWidget(CatalogItemContext itemContext) {
    final widgetData = itemContext.data as JsonMap;
    final String? widgetType = widgetData.keys.firstOrNull;
    final CatalogItem? item = items.firstWhereOrNull(
      (item) => item.name == widgetType,
    );
    if (item == null) {
      genUiLogger.severe('Item $widgetType was not found in catalog');
      return Container();
    }

    genUiLogger.info('Building widget ${item.name} with id ${itemContext.id}');
    return item.widgetBuilder(
      CatalogItemContext(
        data: JsonMap.from(widgetData[widgetType]! as Map),
        id: itemContext.id,
        buildChild: (String childId, [DataContext? childDataContext]) =>
            itemContext.buildChild(
              childId,
              childDataContext ?? itemContext.dataContext,
            ),
        dispatchEvent: itemContext.dispatchEvent,
        buildContext: itemContext.buildContext,
        dataContext: itemContext.dataContext,
        getComponent: itemContext.getComponent,
        surfaceId: itemContext.surfaceId,
      ),
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
    final Map<String, Schema> componentProperties = {
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
