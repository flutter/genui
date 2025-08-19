// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../../flutter_genui.dart';

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

  /// Stream of updates for surfaces.
  Stream<String> get uiStream => throw UnimplementedError();
}
