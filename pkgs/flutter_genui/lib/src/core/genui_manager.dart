// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import 'core_catalog.dart';

/// Surfaces that can be updated by the AI client.
class GenUiSurfaces {
  /// Ids of the surfaces that can be updated.
  final Set<String> surfacesIds;

  /// The [description] explains the surfaces for the AI.
  final String description;

  GenUiSurfaces({required this.surfacesIds, required this.description});
}

class GenUiManager {
  GenUiManager({
    required this.aiClient,
    required GenUiSurfaces surfaces,
    Catalog? catalog,
  }) : _surfaces = surfaces {
    this.catalog = catalog ?? coreCatalog;
  }

  late final Catalog catalog;
  final AiClient aiClient;
  GenUiSurfaces _surfaces;

  /// Resets the surfaces updatable by the AI client.
  set surfaces(GenUiSurfaces value) {
    throw UnimplementedError();
  }

  /// Resets the surfaces updatable by the AI client.
  GenUiSurfaces get surfaces => _surfaces;

  /// Builds a widget for the given [surfaceId].
  ///
  /// If the surface is not defined by AI yet, will use default builder.
  ///
  /// If [defaultBuilder] is not provided, `SizedBox.shrink()` will be rendered.
  ///
  /// If the surface with [surfaceId] does not exist in [surfaces],
  /// will throw an error.
  Widget build({
    required BuildContext context,
    required String surfaceId,
    WidgetBuilder? defaultBuilder,
  }) {
    throw UnimplementedError();
  }

  /// Sends a text prompt to the AI client.
  void sendTextPrompt(String prompt) {
    throw UnimplementedError();
  }

  /// Stream of updates for the surface.
  Stream<WidgetBuilder> uiStream(String surfaceId) =>
      throw UnimplementedError();
}
