// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import 'parser/parser.dart';
import 'prompt/generator.dart';

/// Constructs [InferenceFormat] strategies bound to a set of active catalogs.
abstract class InferenceFormatFactory {
  const InferenceFormatFactory();

  /// Constructs an [InferenceFormat] bound to [catalogs].
  InferenceFormat createFormat(
    List<Catalog<ComponentApi>> catalogs, {
    PromptExamples? examples,
  });
}

/// Pairs the prompt generator (model input) and the parser (model output) of
/// one inference format.
abstract class InferenceFormat {
  const InferenceFormat();

  /// The generator that renders this format's system prompt instructions.
  PromptGenerator get promptGenerator;

  /// Creates a fresh parser bound to this format.
  ///
  /// Parsers carry streaming state, so each model turn needs its own.
  Parser createParser();
}
