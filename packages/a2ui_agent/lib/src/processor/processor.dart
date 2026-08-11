// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../inference_format.dart';
import '../inference_formats/direct_json/format.dart';
import '../parser/parser.dart';
import '../parser/response_part.dart';
import '../primitives/protocol_version.dart';
import '../prompt/generator.dart';
import '../validation/payload_validator.dart';

/// The request-scoped facade over an agent's A2UI capabilities.
///
/// A processor is bound to the catalogs negotiated for one renderer: it
/// renders the system prompt snippet describing them, creates turn-scoped
/// parsers, and validates what comes back. Create one per renderer capability
/// signature via `A2uiGenerator.createProcessor`, and keep it for as long as
/// that renderer's capabilities hold.
class A2uiRequestProcessor {
  /// The catalogs active for this session, already transformed.
  final List<Catalog<ComponentApi>> activeCatalogs;

  /// The few-shot example turns shown to the model.
  final PromptExamples? examples;

  /// The strategy pairing this session's prompt generator and parser.
  final InferenceFormat format;

  /// The protocol version this session speaks.
  final ProtocolVersion protocolVersion;

  String? _promptSnippet;

  A2uiRequestProcessor({
    required List<Catalog<ComponentApi>> catalogs,
    this.examples,
    InferenceFormatFactory? formatFactory,
    this.protocolVersion = ProtocolVersion.current,
  }) : activeCatalogs = List<Catalog<ComponentApi>>.unmodifiable(catalogs),
       format = (formatFactory ?? const DirectJsonFormatFactory()).createFormat(
         List<Catalog<ComponentApi>>.unmodifiable(catalogs),
         examples: examples,
       );

  /// The format-specific system prompt instructions for this session.
  ///
  /// Rendered once and reused: it is a pure function of the active catalogs
  /// and examples, and it is prepended to every request of the session.
  String get promptSnippet =>
      _promptSnippet ??= format.promptGenerator.generate();

  /// Creates a parser for one model turn.
  ///
  /// Parsers accumulate streaming state, so a turn must not share one with
  /// another turn.
  Parser createParser() => format.createParser();

  /// Parses and validates a complete model response.
  ///
  /// Returns the conversational text and compiled A2UI payloads in the order
  /// the model emitted them. Throws
  /// [A2uiValidationError] when a payload does not conform to the active
  /// catalogs, and
  /// [A2uiFormatError](../primitives/errors.dart) when it cannot be compiled
  /// at all.
  List<ResponsePart> parseResponse(String content, {bool wrapped = true}) =>
      createParser().parseResponse(content, wrapped: wrapped);

  /// Parses a streamed model response.
  ///
  /// Parts are yielded as soon as they are usable, so a renderer can build the
  /// UI while the model is still writing it.
  Stream<ResponsePart> parseStream(
    Stream<String> chunks, {
    bool wrapped = true,
  }) => createParser().parseStream(chunks, wrapped: wrapped);

  /// Validates the configured [examples] against the active catalogs.
  ///
  /// An example that names a component the negotiated catalogs do not have
  /// teaches the model to emit exactly what the renderer will reject, so this
  /// runs when the processor is created rather than at inference time.
  void validateExamples() {
    final PromptExamples? examples = this.examples;
    if (examples == null) return;

    final validator = A2uiPayloadValidator(
      catalogs: activeCatalogs,
      protocolVersion: protocolVersion,
    );
    for (final MapEntry<String, List<AgentToRendererMessage>> entry
        in examples.entries) {
      final List<A2uiValidationIssue> issues = validator.validate(entry.value);
      if (issues.isEmpty) continue;
      throw A2uiValidationError(
        "Prompt example '${entry.key}' does not conform to the active "
        'catalogs:\n${issues.map((issue) => '  - $issue').join('\n')}',
        details: issues,
      );
    }
  }
}
