// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// An [InheritedWidget] that provides GULF-related data to the widget tree.
///
/// This is used to pass the [onEvent] callback down to widgets that need to
/// fire events, without having to pass them through many layers of widget
/// constructors.
class GulfProvider extends InheritedWidget {
  /// Creates an [GulfProvider] that provides callbacks to its descendants.
  const GulfProvider({super.key, required super.child, this.onEvent});

  /// A callback function that is invoked when an event is triggered by a
  /// widget.
  final ValueChanged<Map<String, dynamic>>? onEvent;

  /// Retrieves the [GulfProvider] from the given [context].
  static GulfProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GulfProvider>();
  }

  @override
  bool updateShouldNotify(GulfProvider oldWidget) {
    return onEvent != oldWidget.onEvent;
  }
}
