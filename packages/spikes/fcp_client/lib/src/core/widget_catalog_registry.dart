// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../constants.dart';
import '../models/models.dart';

/// A function that builds a Flutter [Widget] from an FCP [LayoutNode].
///
/// - [context]: The Flutter build context.
/// - [node]: The FCP layout node containing the original metadata.
/// - [properties]: A map of resolved properties, combining static values from
///   the node and dynamic values from state bindings.
/// - [children]: A map of already-built child widgets, keyed by the property
///   name they were assigned to (e.g., "child", "appBar"). The value is a
///   list of widgets, even for single-child properties.
typedef CatalogWidgetBuilder =
    Widget Function(
      BuildContext context,
      LayoutNode node,
      Map<String, Object?> properties,
      Map<String, List<Widget>> children,
    );

/// A container for all the information needed to register a widget with the
/// FCP client, including its name, its builder function, and its definition
/// for the `WidgetCatalog`.
class CatalogItem {
  /// Creates a catalog item with the given [name], [builder], and [definition].
  ///
  /// The [name] must match the `type` in a `LayoutNode`. The [builder] is the
  /// function that builds the Flutter widget. The [definition] is the FCP
  /// definition of the widget, including its properties and events.
  const CatalogItem({
    required this.name,
    required this.builder,
    required this.definition,
  });

  /// The name of the widget, which must match the `type` in a `LayoutNode`.
  final String name;

  /// The function that builds the Flutter widget.
  final CatalogWidgetBuilder builder;

  /// The FCP definition of the widget, including its properties and events.
  final WidgetDefinition definition;
}

/// A registry that maps widget type strings from the catalog to concrete
/// [CatalogWidgetBuilder] functions.
///
/// This allows the FCP client to be extended with custom widget
/// implementations.
class WidgetCatalogRegistry {
  final Map<String, CatalogItem> _registeredWidgets = {};

  /// Registers a widget.
  ///
  /// If a widget with the same name already exists, it will be overwritten.
  void register(CatalogItem widget) {
    _registeredWidgets[widget.name] = widget;
  }

  /// Retrieves the builder for the given widget [type].
  ///
  /// Returns `null` if no builder is registered for the type.
  CatalogWidgetBuilder? getBuilder(String type) {
    return _registeredWidgets[type]?.builder;
  }

  /// Checks if a builder is registered for the given widget [type].
  bool hasBuilder(String type) {
    return _registeredWidgets.containsKey(type);
  }

  /// Generates a [WidgetCatalog] from all the registered widgets.
  ///
  /// This method iterates through all the `CatalogItem` instances and
  /// compiles their definitions into a single `WidgetCatalog` object that can
  /// be passed to the `FcpView`.
  ///
  /// The [catalogVersion] defaults to [fcpVersion]. The [dataTypes] are
  /// any custom data types to be included in the catalog.
  WidgetCatalog buildCatalog({
    String catalogVersion = fcpVersion,
    Map<String, Object?> dataTypes = const {},
  }) {
    final items = <String, WidgetDefinition?>{};
    for (final widget in _registeredWidgets.values) {
      items[widget.name] = widget.definition;
    }

    return WidgetCatalog.fromMap({
      'catalogVersion': catalogVersion,
      'dataTypes': dataTypes,
      'items': items,
    });
  }
}
