// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';

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

  /// The builder for an explicit list of children.
  final Widget Function(List<Widget> children) explicitListBuilder;

  /// The builder for a template-based list of children.
  final Widget Function(
    BuildContext context,
    List<dynamic> list,
    String componentId,
    String dataBinding,
  )
  templateListWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    // Accept either a List of string IDs or the correct output, which is an
    // object with "explicitList" as the list property to use. This is
    // because the AIs seem to often get confused and generate just a list
    // of IDs.
    final explicitList = (childrenData is List)
        ? (childrenData as List).cast<String>()
        : ((childrenData as JsonMap?)?['explicitList'] as List?)
              ?.cast<String>();

    if (explicitList != null) {
      return explicitListBuilder(
        explicitList.map((String id) => buildChild(id, dataContext)).toList(),
      );
    }

    if (childrenData is JsonMap) {
      final childrenMap = childrenData as JsonMap;
      final template = childrenMap['template'] as JsonMap?;
      if (template != null) {
        final dataBinding = template['dataBinding'] as String;
        final componentId = template['componentId'] as String;
        final listNotifier = dataContext.subscribe<List<dynamic>>(
          DataPath(dataBinding),
        );
        return ValueListenableBuilder<List<dynamic>?>(
          valueListenable: listNotifier,
          builder: (context, list, child) {
            genUiLogger.info('buildChildrenFromComponentData: list=$list');
            if (list == null) {
              return const SizedBox.shrink();
            }
            return templateListWidgetBuilder(
              context,
              list,
              componentId,
              dataBinding,
            );
          },
        );
      }
    }
    return const SizedBox.shrink();
  }
}
