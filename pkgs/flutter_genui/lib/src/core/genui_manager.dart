// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import 'core_catalog.dart';

class GenUiManager {
  GenUiManager({required this.aiClient, Catalog? catalog}) {
    this.catalog = catalog ?? coreCatalog;
  }

  late final Catalog catalog;
  final AiClient aiClient;

  void setUpdatableSurfaces(List<String> surfaces, String description) {
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
