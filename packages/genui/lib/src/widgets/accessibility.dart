// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
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
/// The attributes are merged into the component's own semantics node, so the
/// agent's label is announced ahead of whatever the component says for itself
/// and anything the component can do stays on the node that says it.
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

        return MergeSemantics(
          child: _A2uiSemanticsLabel(
            label: announced,
            hint: explained,
            textDirection: Directionality.of(context),
            child: child,
          ),
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

/// Puts the agent's label on the component, in place of the one the component
/// would announce for itself.
///
/// `accessibility.label` is the component's accessible name, not an addition
/// to it: the v1.0 text describes it as what assistive technology conveys the
/// element as. Flutter has no parameter for that. `Semantics` adds a label,
/// and `excludeSemantics` drops the subtree along with any action it carries,
/// which for a button means the label arrives and the button stops working.
///
/// So the replacement happens where the subtree is still a set of
/// configurations rather than nodes: `childConfigurationsDelegate` is handed
/// each child's configuration before it merges up, and clearing its label
/// there leaves the merged node announcing only what the agent wrote, with
/// the child's role and actions intact.
///
/// A child that builds a semantics node of its own is never offered, so its
/// label survives and the agent's is announced ahead of it. Every Material
/// control does that, which is why they take the label themselves instead:
/// see a2ui-project/a2ui#2697.
class _A2uiSemanticsLabel extends SingleChildRenderObjectWidget {
  const _A2uiSemanticsLabel({
    required this.label,
    required this.hint,
    required this.textDirection,
    required Widget super.child,
  });

  final String? label;
  final String? hint;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderA2uiSemanticsLabel(
        label: label,
        hint: hint,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderA2uiSemanticsLabel renderObject,
  ) {
    renderObject
      ..label = label
      ..hint = hint
      ..textDirection = textDirection;
  }
}

class _RenderA2uiSemanticsLabel extends RenderProxyBox {
  _RenderA2uiSemanticsLabel({
    required String? label,
    required String? hint,
    required TextDirection textDirection,
  }) : _label = label,
       _hint = hint,
       _textDirection = textDirection;

  String? _label;
  set label(String? value) {
    if (value == _label) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  String? _hint;
  set hint(String? value) {
    if (value == _hint) return;
    _hint = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    // A label without one trips an assertion in `SemanticsData`, and the
    // component's own direction is the one the label is read in.
    config.textDirection = _textDirection;
    if (_label case final String label) config.label = label;
    if (_hint case final String hint) config.hint = hint;

    config.childConfigurationsDelegate =
        (List<SemanticsConfiguration> children) {
          final builder = ChildSemanticsConfigurationsResultBuilder();
          for (final child in children) {
            // Cleared, not dropped: the child keeps its role, its value and its
            // actions, and loses only the name the agent is replacing.
            if (_label != null) child.label = '';
            builder.markAsMergeUp(child);
          }
          return builder.build();
        };
  }
}
