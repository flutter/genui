// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../../inference_format.dart';
import '../../prompt/generator.dart';
import 'parser.dart';
import 'prompt_generator.dart';

/// Creates [DirectJsonFormat] strategies bound to a set of active catalogs.
class DirectJsonFormatFactory extends InferenceFormatFactory {
  /// The message envelopes the model is allowed to emit.
  final List<String>? allowedMessages;

  /// Overrides the streaming progressive keys derived from the catalogs.
  final Set<String>? customProgressiveKeys;

  const DirectJsonFormatFactory({
    this.allowedMessages,
    this.customProgressiveKeys,
  });

  @override
  DirectJsonFormat createFormat(
    List<Catalog<ComponentApi>> catalogs, {
    PromptExamples? examples,
  }) {
    return DirectJsonFormat(
      catalogs,
      examples: examples,
      allowedMessages: allowedMessages,
      customProgressiveKeys: customProgressiveKeys,
    );
  }
}

/// Pairs [DirectJsonPromptGenerator] with [DirectJsonParser].
///
/// This is the baseline format: the model emits the A2UI wire JSON itself,
/// wrapped in `<a2ui-json>` tags.
class DirectJsonFormat extends InferenceFormat {
  /// The active catalogs this format is bound to.
  final List<Catalog<ComponentApi>> catalogs;

  /// Overrides the streaming progressive keys derived from [catalogs].
  final Set<String>? customProgressiveKeys;

  @override
  final DirectJsonPromptGenerator promptGenerator;

  DirectJsonFormat(
    this.catalogs, {
    PromptExamples? examples,
    List<String>? allowedMessages,
    this.customProgressiveKeys,
  }) : promptGenerator = DirectJsonPromptGenerator(
         catalogs,
         examples: examples,
         allowedMessages: allowedMessages,
       );

  @override
  DirectJsonParser createParser() => DirectJsonParser(
    catalogs: catalogs,
    customProgressiveKeys: customProgressiveKeys,
  );
}
