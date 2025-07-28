import 'package:flutter/widgets.dart';
import '../models/models.dart';

/// A function that builds a Flutter [Widget] from an FCP [LayoutNode].
///
/// - [context]: The Flutter build context.
/// - [node]: The FCP layout node containing the original metadata.
/// - [properties]: A map of resolved properties, combining static values from
///   the node and dynamic values from state bindings.
/// - [children]: A map of already-built child widgets, keyed by the property
///   name they were assigned to (e.g., "child", "appBar", "children"). The
///   value can be a single [Widget] or a `List<Widget>`.
typedef FcpCatalogItemBuilder = Widget Function(
  BuildContext context,
  LayoutNode node,
  Map<String, Object?> properties,
  Map<String, dynamic> children,
);

/// A registry that maps catalog item type strings from the catalog to concrete
/// [FcpCatalogItemBuilder] functions.
///
/// This allows the FCP client to be extended with custom catalog item
/// implementations.
class CatalogRegistry {
  final Map<String, FcpCatalogItemBuilder> _builders = {};

  /// Registers a builder for a given catalog item type.
  ///
  /// If a builder for this [type] already exists, it will be overwritten.
  void register(String type, FcpCatalogItemBuilder builder) {
    _builders[type] = builder;
  }

  /// Retrieves the builder for the given catalog item [type].
  ///
  /// Returns `null` if no builder is registered for the type.
  FcpCatalogItemBuilder? getBuilder(String type) {
    return _builders[type];
  }

  /// Checks if a builder is registered for the given catalog item [type].
  bool hasBuilder(String type) {
    return _builders.containsKey(type);
  }
}
