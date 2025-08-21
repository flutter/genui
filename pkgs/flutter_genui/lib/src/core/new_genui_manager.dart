// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import 'core_catalog.dart';

/// A class that defines the UI surfaces that can be updated by the AI client.
class GenUiSurfaces {
  /// Creates a new [GenUiSurfaces] with the given [surfacesIds] and
  /// [description].
  GenUiSurfaces({required this.surfacesIds, required this.description});

  /// Ids of the surfaces that can be updated.
  final Set<String> surfacesIds;

  /// Explains the surfaces, itemized in [surfacesIds], for the AI.
  final String description;
}

/// An abstract class for warnings that can be issued by the [NewGenUiManager].
abstract class GenUiWarning {
  /// The warning message.
  String get message;
}

// TODO: rename to GenUiManager after implementing.
/// A manager for the state of the generative UI.
class NewGenUiManager {
  /// Creates a new [NewGenUiManager].
  NewGenUiManager({
    required this.aiClient,
    required GenUiSurfaces surfaces,
    required this.generalPrompt,
    this.onWarning,
    Catalog? catalog,
  }) : _surfaces = surfaces {
    this.catalog = catalog ?? coreCatalog;
  }

  /// The catalog of UI components that can be used to build the UI.
  late final Catalog catalog;

  /// The AI client to use for generating UI.
  final AiClient aiClient;

  /// The general prompt to use for the AI.
  final String generalPrompt;

  /// Called when there is a warning to report.
  final ValueChanged<GenUiWarning>? onWarning;

  /// If true, the AI is processing a request.
  ValueListenable<bool> get isProcessing => _isProcessing;
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);

  /// Surfaces updatable by the AI client.
  GenUiSurfaces get surfaces => _surfaces;
  GenUiSurfaces _surfaces;
  set surfaces(GenUiSurfaces value) {
    _surfaces = value;
    throw UnimplementedError();
  }

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
  ///
  /// The future will complete when the prompt is responded to.
  Future<void> sendTextPrompt(String prompt) {
    throw UnimplementedError();
  }

  /// Stream of updates for the surface.
  ///
  /// If the surface with [surfaceId] does not exist in [surfaces],
  /// will throw an error.
  ///
  /// The stream will complete when the surface is removed
  /// from [surfaces].
  Stream<WidgetBuilder> surfaceUpdates(String surfaceId) =>
      throw UnimplementedError();

  /// Stream of updates for all surfaces.
  Stream<SurfaceUpdate> get allSurfaceUpdates => throw UnimplementedError();
}

/// A class that represents an update to a UI surface.
class SurfaceUpdate {
  /// Creates a new [SurfaceUpdate] with the given [surfaceId] and [builder].
  SurfaceUpdate({required this.surfaceId, required this.builder});

  /// The ID of the surface that was updated.
  final String surfaceId;

  /// The builder for the updated surface.
  final WidgetBuilder builder;
}
