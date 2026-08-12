// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../parser/response_part.dart';

/// A named set of example messages used as a few-shot prompt turn.
///
/// The key of the surrounding map describes the example turn; the value is the
/// A2UI payload the model is expected to produce for it.
typedef PromptExamples = Map<String, List<AgentToRendererMessage>>;

/// Base class for format-specific prompt generators.
///
/// A generator renders the system instruction snippet describing how the model
/// must emit A2UI for one inference format, including the schemas of the
/// active catalogs. Callers prepend their own role and workflow preambles and
/// append their own suffixes.
abstract class PromptGenerator {
  /// The active catalogs to describe in the system instructions.
  final List<Catalog<ComponentApi>> catalogs;

  /// Optional few-shot example turns, keyed by a description of the turn.
  final PromptExamples? examples;

  const PromptGenerator(this.catalogs, {this.examples});

  /// Renders the format-specific system prompt instructions and catalog
  /// schemas.
  String generate();
}
