// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/catalog.dart';
import '../model/tools.dart';
import 'surface_manager.dart';
import 'ui_tools.dart';

class GenuiManager {
  SurfaceManager surfaceManager;

  GenuiManager({Catalog? catalog})
    : surfaceManager = SurfaceManager(catalog: catalog);

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
}
