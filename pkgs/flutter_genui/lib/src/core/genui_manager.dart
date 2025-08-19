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

  /// Sets the surfaces that can be updated by the AI client.
  void setSurfaces(GenUiSurfaces surfaces) {
    throw UnimplementedError();
  }

  Widget build({required BuildContext context, required String surfaceId}) {
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
