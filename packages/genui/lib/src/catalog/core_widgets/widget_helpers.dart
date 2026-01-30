// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';

/// Builder function for creating a widget from a template and a list of data.
///
/// This is used by [ComponentChildrenBuilder] when children are defined by a
/// `template` which includes a `dataBinding` to a list in the [DataContext].
typedef TemplateListWidgetBuilder =
    Widget Function(
      BuildContext context,
      Map<String, Object?> data,
      String componentId,
      String dataBinding,
    );

/// Builder function for creating a parent widget given a list of pre-built
/// [childIds].
///
/// This is used by [ComponentChildrenBuilder] when children are defined as an
/// explicit list of component IDs.
typedef ExplicitListWidgetBuilder =
    Widget Function(
      List<String> childIds,
      ChildBuilderCallback buildChild,
      GetComponentCallback getComponent,
      DataContext dataContext,
    );

/// A helper widget to build widgets from component data that contains a list
/// of children.
///
/// This widget handles two cases for defining children:
/// 1. An explicit list of child widget IDs.
/// 2. A template with a data binding to a list of data.
///
/// The `childrenData` can be a `List<String>` of child IDs, or a `JsonMap`
/// with either an `explicitList` key (with a `List<String>` value) or a
/// `template` key. The `template` is a `JsonMap` with `dataBinding` and
/// `componentId` keys.
class ComponentChildrenBuilder extends StatelessWidget {
  /// Creates a new [ComponentChildrenBuilder].
  const ComponentChildrenBuilder({
    required this.childrenData,
    required this.dataContext,
    required this.buildChild,
    required this.getComponent,
    required this.explicitListBuilder,
    required this.templateListWidgetBuilder,
    super.key,
  });

  /// The data that defines the children to build.
  final Object? childrenData;

  /// The data context for the children.
  final DataContext dataContext;

  /// The callback to build a child widget.
  final ChildBuilderCallback buildChild;

  /// The callback to get a component's data by ID.
  final GetComponentCallback getComponent;

  /// The builder for an explicit list of children.
  final ExplicitListWidgetBuilder explicitListBuilder;

  /// The builder for a template-based list of children.
  final TemplateListWidgetBuilder templateListWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    final List<String>? explicitList = (childrenData is List)
        ? (childrenData as List).map((e) {
            if (e is String) return e;
            if (e is Map && e.containsKey('literalString')) {
              return e['literalString'] as String;
            }
            return e.toString();
          }).toList()
        : ((childrenData as JsonMap?)?['explicitList'] as List?)?.map((e) {
            if (e is String) return e;
            if (e is Map && e.containsKey('literalString')) {
              return e['literalString'] as String;
            }
            return e.toString();
          }).toList();

    if (explicitList != null) {
      return explicitListBuilder(
        explicitList,
        buildChild,
        getComponent,
        dataContext,
      );
    }

    if (childrenData is JsonMap) {
      final childrenMap = childrenData as JsonMap;
      final template = childrenMap['template'] as JsonMap?;
      if (template != null) {
        final dataBinding = template['dataBinding'] as String;
        final componentId = template['componentId'] as String;
        genUiLogger.finest(
          'Widget $componentId subscribing to ${dataContext.path}',
        );
        final ValueNotifier<Map<String, Object?>?> dataNotifier = dataContext
            .subscribe<Map<String, Object?>>(DataPath(dataBinding));
        return ValueListenableBuilder<Map<String, Object?>?>(
          valueListenable: dataNotifier,
          builder: (context, data, child) {
            genUiLogger.info(
              'ComponentChildrenBuilder: data type: ${data.runtimeType}, '
              'value: $data',
            );
            if (data != null) {
              return templateListWidgetBuilder(
                context,
                data,
                componentId,
                dataBinding,
              );
            }
            return const SizedBox.shrink();
          },
        );
      }
    }
    return const SizedBox.shrink();
  }
}

/// Builds a child widget, wrapping it in a [Flexible] if a weight is provided
/// in the component.
Widget buildWeightedChild({
  required String componentId,
  required DataContext dataContext,
  required ChildBuilderCallback buildChild,
  required int? weight,
}) {
  final Widget childWidget = buildChild(componentId, dataContext);
  if (weight != null) {
    return Flexible(flex: weight, child: childWidget);
  }
  return childWidget;
}
