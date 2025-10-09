// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../core/interpreter.dart';

/// An [InheritedWidget] that provides A2UI-related data to the widget tree.
///
/// This is used to pass the [onEvent] callback down to widgets that need to
/// fire events, without having to pass them through many layers of widget
/// constructors.
class A2uiProvider extends InheritedWidget {
  /// Creates an [A2uiProvider] that provides callbacks to its descendants.
  const A2uiProvider({
    super.key,
    required super.child,
    required this.interpreter,
    this.onEvent,
    this.onDataModelUpdate,
  });

  /// The interpreter that processes the A2UI stream.
  final A2uiInterpreter interpreter;

  /// A callback function that is invoked when an event is triggered by a
  /// widget.
  final ValueChanged<Map<String, dynamic>>? onEvent;

  /// A callback function that is invoked when the data model is updated by a
  /// widget.
  final void Function(String path, dynamic value)? onDataModelUpdate;

  /// Retrieves the [A2uiProvider] from the given [context].
  static A2uiProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<A2uiProvider>();
  }

  @override
  bool updateShouldNotify(A2uiProvider oldWidget) {
    return onEvent != oldWidget.onEvent ||
        onDataModelUpdate != oldWidget.onDataModelUpdate ||
        interpreter != oldWidget.interpreter;
  }
}
