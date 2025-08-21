// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import 'surface_manager.dart';
import 'ui_tools.dart';

class GenUiManager {
  SurfaceManager surfaceManager;

  GenUiManager({Catalog? catalog})
    : surfaceManager = SurfaceManager(catalog: catalog);

  Map<String, ValueNotifier<UiDefinition?>> get surfaces =>
      surfaceManager.surfaces;

  Stream<GenUiUpdate> get updates => surfaceManager.updates;

  Catalog get catalog => surfaceManager.catalog;

  /// Returns a list of [AiTool]s that can be used to manipulate the UI.
  ///
  /// These tools should be provided to the [AiClient] to allow the AI to
  /// generate and modify the UI.
  List<AiTool> getTools() {
    return [
      AddOrUpdateSurfaceTool(surfaceManager),
      DeleteSurfaceTool(surfaceManager),
    ];
  }

  ValueNotifier<UiDefinition?> surface(String surfaceId) =>
      surfaceManager.surface(surfaceId);

  void dispose() {
    surfaceManager.dispose();
  }

  void addOrUpdateSurface(String s, Map<String, Object?> definition) =>
      surfaceManager.addOrUpdateSurface(s, definition);

  void deleteSurface(String s) => surfaceManager.deleteSurface(s);
}
