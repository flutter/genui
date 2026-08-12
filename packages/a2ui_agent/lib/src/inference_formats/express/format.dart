// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../../inference_format.dart';
import '../../prompt/generator.dart';
import 'constants.dart';
import 'parser.dart';
import 'prompt_generator.dart';

/// Creates [ExpressFormat] strategies bound to a set of active catalogs.
class ExpressFormatFactory extends InferenceFormatFactory {
  /// The surface used when a block does not call `surface(...)`.
  final String defaultSurfaceId;

  /// Surfaces the renderer already has, which must not be created again.
  final Set<String> existingSurfaceIds;

  const ExpressFormatFactory({
    this.defaultSurfaceId = expressDefaultSurfaceId,
    this.existingSurfaceIds = const {},
  });

  @override
  ExpressFormat createFormat(
    List<Catalog<ComponentApi>> catalogs, {
    PromptExamples? examples,
  }) {
    return ExpressFormat(
      catalogs,
      examples: examples,
      defaultSurfaceId: defaultSurfaceId,
      existingSurfaceIds: existingSurfaceIds,
    );
  }
}

/// Pairs [ExpressPromptGenerator] with [ExpressParser].
///
/// Express trades the verbosity of raw A2UI JSON for a positional DSL, which
/// cuts output tokens substantially — the reason it exists — at the cost of
/// requiring a catalog on the agent side to map arguments onto properties.
class ExpressFormat extends InferenceFormat {
  /// The active catalogs this format is bound to.
  final List<Catalog<ComponentApi>> catalogs;

  /// The surface used when a block does not call `surface(...)`.
  final String defaultSurfaceId;

  /// Surfaces the renderer already has, which must not be created again.
  final Set<String> existingSurfaceIds;

  @override
  final ExpressPromptGenerator promptGenerator;

  ExpressFormat(
    this.catalogs, {
    PromptExamples? examples,
    this.defaultSurfaceId = expressDefaultSurfaceId,
    this.existingSurfaceIds = const {},
  }) : promptGenerator = ExpressPromptGenerator(catalogs, examples: examples);

  @override
  ExpressParser createParser() => ExpressParser(
    catalogs: catalogs,
    defaultSurfaceId: defaultSurfaceId,
    existingSurfaceIds: existingSurfaceIds,
  );
}
