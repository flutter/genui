// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../../flutter_genui.dart';

typedef ChildBuilderCallback = Widget Function(String id);

typedef CatalogWidgetBuilder =
    Widget Function({
      // The actual deserialized JSON data for this widget. The format of this
      // data will exactly match [CatalogItem.dataSchema].
      required Object data,
      // The ID of this widget.
      required String id,
      // A function used to build a child based on the given ID.
      required ChildBuilderCallback buildChild,
      // A function used to dispatch an event.
      required DispatchEventCallback dispatchEvent,
      required BuildContext context,
    });

/// Defines a UI layout type, its schema, and how to build its widget.
class CatalogItem {
  final String name; // The key used in JSON, e.g., 'text_chat_message'
  final Schema dataSchema; // The schema definition for this widget's data.
  final CatalogWidgetBuilder widgetBuilder;

  CatalogItem({
    required this.name,
    required this.dataSchema,
    required this.widgetBuilder,
  });
}
