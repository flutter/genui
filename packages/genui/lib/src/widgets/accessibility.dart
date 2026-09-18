// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../model/data_model.dart';
import 'widget_utilities.dart';

/// Applies a component's A2UI `accessibility` attributes to [child].
///
/// `ComponentCommon` gives every component an optional `accessibility` object.
/// Its `label` is what assistive technology should announce the component as,
/// and its `description` is the longer explanation offered after it. Both are
/// `DynamicString`s, so either may be a literal, a `{"path": ...}` binding or
/// a `{"call": ...}` function call, and both resolve through the same
/// [BoundString] the rest of the catalog binds with.
///
/// Use [wrap] rather than the constructor: a component without accessibility
/// attributes — the common case — is left exactly as it was, instead of
/// gaining a widget that has nothing to do.
class A2uiAccessibility extends StatelessWidget {
  /// Creates an [A2uiAccessibility].
  const A2uiAccessibility({
    super.key,
    required this.label,
    required this.description,
    required this.dataContext,
    required this.child,
  });

  /// The raw `accessibility.label`, before resolution.
  final Object? label;

  /// The raw `accessibility.description`, before resolution.
  final Object? description;

  /// The data context a bound label or description resolves against.
  final DataContext dataContext;

  /// The component this describes.
  final Widget child;

  /// [child] with the `accessibility` attributes of [componentData] applied,
  /// or [child] itself when there are none to apply.
  ///
  /// [componentData] is the component's own JSON, as the agent sent it.
  static Widget wrap({
    required Object? componentData,
    required DataContext dataContext,
    required Widget child,
  }) {
    if (componentData is! Map) return child;
    final Object? attributes = componentData['accessibility'];
    if (attributes is! Map) return child;

    final Object? label = attributes['label'];
    final Object? description = attributes['description'];
    if (label == null && description == null) return child;

    return A2uiAccessibility(
      label: label,
      description: description,
      dataContext: dataContext,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nested rather than resolved together because each value carries its own
    // subscription: a label bound to a path has to rebuild when that path
    // changes, whether or not the description is bound to anything.
    return _resolve(label, (String? resolvedLabel) {
      return _resolve(description, (String? resolvedDescription) {
        // A binding that has not resolved yet reads as null, and announcing
        // nothing is better than announcing an empty node.
        final String? announced = _orNull(resolvedLabel);
        final String? explained = _orNull(resolvedDescription);
        if (announced == null && explained == null) return child;

        return Semantics(
          label: announced,
          hint: explained,
          container: true,
          // Without this the component's own semantics merge into this node,
          // and the agent's label comes back joined to whatever the component
          // already said. The component keeps its own node — and with it any
          // action it carries — and this one says only what the agent asked
          // for.
          explicitChildNodes: true,
          child: child,
        );
      });
    });
  }

  Widget _resolve(Object? value, Widget Function(String?) builder) {
    if (value == null) return builder(null);
    if (value is String) return builder(value);
    return BoundString(
      dataContext: dataContext,
      value: value,
      builder: (BuildContext context, String? resolved) => builder(resolved),
    );
  }

  static String? _orNull(String? value) =>
      value == null || value.isEmpty ? null : value;
}
