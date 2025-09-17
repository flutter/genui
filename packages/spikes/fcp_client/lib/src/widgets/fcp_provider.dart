// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../models/models.dart';

/// An [InheritedWidget] that provides FCP-related data to the widget tree.
///
/// This is used to pass the [onEvent] callback down to widgets that need to
/// fire events, without having to pass the callback through many layers of
/// widget constructors.
class FcpProvider extends InheritedWidget {
  /// Creates an [FcpProvider] that provides an [onEvent] callback to its
  /// descendants.
  const FcpProvider({super.key, required super.child, this.onEvent});

  /// A callback function that is invoked when an event is triggered by a
  /// widget.
  final ValueChanged<EventPayload>? onEvent;

  /// Retrieves the [FcpProvider] from the given [context].
  static FcpProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FcpProvider>();
  }

  @override
  bool updateShouldNotify(FcpProvider oldWidget) {
    return onEvent != oldWidget.onEvent;
  }
}
