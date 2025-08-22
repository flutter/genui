// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/catalog.dart';
import '../model/ui_models.dart';

/// A callback for when a user interacts with a widget.
typedef UiEventCallback = void Function(UiEvent event);

class SurfaceController {
  SurfaceController({
    required this.definitionNotifier,
    required this.catalog,
    required this.onEvent,
  });

  final ValueNotifier<UiDefinition?> definitionNotifier;
  final Catalog catalog;

  /// A callback for when a user interacts with a widget.
  final UiEventCallback onEvent;
}
