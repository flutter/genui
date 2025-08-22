// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import 'genui_configuration.dart';
import 'surface_manager.dart';
import 'ui_tools.dart';

enum GenUiStyle { flexible, chat }

class GenUiManager {
  SurfaceManager surfaceManager;

  GenUiManager({Catalog? catalog, required this.configuration})
    : surfaceManager = SurfaceManager(
        catalog: catalog,
        configuration: configuration,
      );

  Map<String, ValueNotifier<UiDefinition?>> get surfaces =>
      surfaceManager.surfaces;

  Stream<GenUiUpdate> get updates => surfaceManager.updates;

  Catalog get catalog => surfaceManager.catalog;

  final GenUiConfiguration configuration;

  /// Returns a list of [AiTool]s that can be used to manipulate the UI.
  ///
  /// These tools should be provided to the [AiClient] to allow the AI to
  /// generate and modify the UI.
  List<AiTool> getTools() {
    return [
      if (configuration.actions.allowCreate ||
          configuration.actions.allowUpdate)
        AddOrUpdateSurfaceTool(surfaceManager, configuration),
      if (configuration.actions.allowDelete) DeleteSurfaceTool(surfaceManager),
    ];
  }

  void dispose() {
    surfaceManager.dispose();
  }

  void addOrUpdateSurface(String s, Map<String, Object?> definition) =>
      surfaceManager.addOrUpdateSurface(s, definition);

  void deleteSurface(String s) => surfaceManager.deleteSurface(s);
}
