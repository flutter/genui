// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import '../models/component.dart';

/// A function that builds a Flutter [Widget] from a [Component].
///
/// - [context]: The Flutter build context.
/// - [component]: The component containing the original metadata.
/// - [properties]: A map of resolved properties, combining static values from
///   the component and dynamic values from data bindings.
/// - [children]: A map of already-built child widgets, keyed by the property
///   name they were assigned to (e.g., "child", "children").
typedef CatalogWidgetBuilder =
    Widget Function(
      BuildContext context,
      Component component,
      Map<String, Object?> properties,
      Map<String, List<Widget>> children,
    );

/// A registry that maps component type strings to concrete
/// [CatalogWidgetBuilder] functions.
///
/// This allows the simple A2UI client to be extended with custom widget
/// implementations.
class WidgetRegistry {
  /// Creates a new [WidgetRegistry].
  WidgetRegistry();

  final Map<String, CatalogWidgetBuilder> _builders = {};

  /// Registers a widget builder for a given [type].
  ///
  /// If a builder for the same [type] already exists, it will be overwritten.
  void register(String type, CatalogWidgetBuilder builder) {
    _builders[type] = builder;
  }

  /// Retrieves the builder for the given widget [type].
  ///
  /// Returns `null` if no builder is registered for the type.
  CatalogWidgetBuilder? getBuilder(String type) {
    return _builders[type];
  }
}
