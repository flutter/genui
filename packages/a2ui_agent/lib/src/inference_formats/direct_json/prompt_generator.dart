// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';

import '../../parser/response_part.dart';
import '../../prompt/generator.dart';
import '../../utils/catalog_document.dart';
import 'constants.dart';

/// Renders the system prompt for the Direct JSON inference format.
///
/// The snippet describes the sentinel tags, the message envelopes the agent
/// may emit, the component ordering the streaming parser relies on, and the
/// schemas of the active catalogs.
class DirectJsonPromptGenerator extends PromptGenerator {
  /// The message envelopes the model is allowed to emit.
  ///
  /// Defaults to every envelope in the protocol. Narrow it to, say,
  /// `['createSurface', 'updateComponents']` for a chat agent that only ever
  /// builds new surfaces.
  final List<String>? allowedMessages;

  const DirectJsonPromptGenerator(
    super.catalogs, {
    super.examples,
    this.allowedMessages,
  });

  /// The envelopes this generator advertises.
  List<String> get messages => allowedMessages ?? a2uiMessageEnvelopes;

  @override
  String generate() {
    final buffer = StringBuffer()
      ..writeln('# A2UI output format')
      ..writeln()
      ..writeln(
        'You build user interfaces by emitting A2UI protocol messages as '
        'JSON.',
      )
      ..writeln()
      ..writeln('## Rules')
      ..writeln()
      ..writeln(
        '- A response may contain any number of A2UI blocks, and '
        'conversational text before, between or after them.',
      )
      ..writeln(
        '- Every A2UI block MUST be wrapped in `$directJsonOpenTag` and '
        '`$directJsonCloseTag` tags.',
      )
      ..writeln(
        '- The content of a block MUST be raw JSON: a list of A2UI messages. '
        'Do not wrap it in a markdown code fence.',
      )
      ..writeln(
        '- Each message MUST validate against the schemas below and MUST '
        'carry exactly one of these envelopes: ${messages.join(', ')}.',
      )
      ..writeln(
        '- Within the `components` list of a message, the `root` component '
        'MUST come first and every parent MUST come before its children. The '
        'renderer streams the UI in the order you emit it.',
      )
      ..writeln(
        '- Never invent a component or property that is not in the catalog '
        'schemas below.',
      )
      ..writeln()
      ..writeln('## Catalog schemas')
      ..writeln()
      ..writeln(a2uiSchemaOpenTag)
      ..writeln(_encode(_catalogDocuments()))
      ..writeln(a2uiSchemaCloseTag);

    final String examplesSection = _renderExamples();
    if (examplesSection.isNotEmpty) {
      buffer
        ..writeln()
        ..write(examplesSection);
    }
    return buffer.toString();
  }

  List<Map<String, dynamic>> _catalogDocuments() => [
    for (final Catalog<ComponentApi> catalog in catalogs)
      catalogToDocument(catalog),
  ];

  String _renderExamples() {
    final PromptExamples? examples = this.examples;
    if (examples == null || examples.isEmpty) return '';

    final buffer = StringBuffer()
      ..writeln('## Examples')
      ..writeln();
    for (final MapEntry<String, List<AgentToRendererMessage>> entry
        in examples.entries) {
      buffer
        ..writeln('### ${entry.key}')
        ..writeln()
        ..writeln(directJsonOpenTag)
        ..writeln(
          _encode([
            for (final AgentToRendererMessage message in entry.value)
              message.toJson(),
          ]),
        )
        ..writeln(directJsonCloseTag)
        ..writeln();
    }
    return buffer.toString();
  }

  static String _encode(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);
}
