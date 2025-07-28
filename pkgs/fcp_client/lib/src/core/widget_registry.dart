import 'package:flutter/widgets.dart';
import '../models/models.dart';

/// A function that builds a Flutter [Widget] from an FCP [WidgetNode].
///
/// - [context]: The Flutter build context.
/// - [node]: The FCP widget node containing the original metadata.
/// - [properties]: A map of resolved properties, combining static values from
///   the node and dynamic values from state bindings.
/// - [children]: A map of already-built child widgets, keyed by the property
///   name they were assigned to (e.g., "child", "appBar", "children"). The
///   value can be a single [Widget] or a `List<Widget>`.
typedef FcpWidgetBuilder =
    Widget Function(
      BuildContext context,
      WidgetNode node,
      Map<String, Object?> properties,
      Map<String, dynamic> children,
    );

/// A registry that maps widget type strings from the manifest to concrete
/// [FcpWidgetBuilder] functions.
///
/// This allows the FCP client to be extended with custom widget
/// implementations.
class WidgetRegistry {
  final Map<String, FcpWidgetBuilder> _builders = {};

  /// Registers a builder for a given widget type.
  ///
  /// If a builder for this [type] already exists, it will be overwritten.
  void register(String type, FcpWidgetBuilder builder) {
    _builders[type] = builder;
  }

  /// Retrieves the builder for the given widget [type].
  ///
  /// Returns `null` if no builder is registered for the type.
  FcpWidgetBuilder? getBuilder(String type) {
    return _builders[type];
  }

  /// Checks if a builder is registered for the given widget [type].
  bool hasBuilder(String type) {
    return _builders.containsKey(type);
  }
}
