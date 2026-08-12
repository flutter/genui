// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';

import '../../parser/parser.dart';
import '../../parser/response_part.dart';
import '../../primitives/protocol_version.dart';
import '../../utils/schema_utils.dart';
import '../../validation/payload_validator.dart';
import 'constants.dart';
import 'payload_fixer.dart';
import 'streaming.dart';

/// Parses standard A2UI JSON payloads enclosed in `<a2ui-json>` tags.
class DirectJsonParser extends Parser {
  /// The active catalogs compiled payloads are validated against.
  final List<Catalog<ComponentApi>> catalogs;

  /// Overrides the progressive keys derived from [catalogs].
  final Set<String>? customProgressiveKeys;

  /// The protocol version payloads must declare.
  final ProtocolVersion protocolVersion;

  /// Whether compiled payloads are checked for dangling child references and
  /// reference cycles.
  ///
  /// Off by default because a turn may legitimately update components that a
  /// previous turn defined, which this parser cannot see.
  final bool checkReferences;

  Set<String>? _progressiveKeys;
  DirectJsonStreamProcessor? _stream;

  DirectJsonParser({
    required this.catalogs,
    this.customProgressiveKeys,
    this.protocolVersion = ProtocolVersion.current,
    this.checkReferences = false,
  });

  @override
  String get openTag => directJsonOpenTag;

  @override
  String get closeTag => directJsonCloseTag;

  /// The string property keys that may be auto-closed when a streamed value is
  /// cut off mid-token.
  ///
  /// Derived from the active catalogs unless [customProgressiveKeys] overrides
  /// them.
  Set<String> get progressiveKeys =>
      customProgressiveKeys ??
      (_progressiveKeys ??= progressiveStringKeys(catalogs));

  @override
  List<AgentToRendererMessage> compile(String formatContent) {
    final List<Map<String, dynamic>> payload = PayloadFixer.parseAndFix(
      formatContent,
      version: protocolVersion,
    );
    final List<AgentToRendererMessage> messages = [
      for (final Map<String, dynamic> json in payload)
        A2uiMessage.fromJson(json),
    ];
    A2uiPayloadValidator(
      catalogs: catalogs,
      protocolVersion: protocolVersion,
    ).validateOrThrow(messages, checkReferences: checkReferences);
    return messages;
  }

  @override
  String decompile(List<AgentToRendererMessage> a2uiPayload) {
    return const JsonEncoder.withIndent('  ').convert([
      for (final AgentToRendererMessage message in a2uiPayload)
        message.toJson(),
    ]);
  }

  @override
  List<ResponsePart> parseChunk(String chunk, {bool wrapped = true}) =>
      _processor.add(chunk, wrapped: wrapped);

  @override
  List<ResponsePart> flush() => _processor.flush();

  DirectJsonStreamProcessor get _processor =>
      _stream ??= DirectJsonStreamProcessor(
        catalogs: catalogs,
        progressiveKeys: progressiveKeys,
        protocolVersion: protocolVersion,
        openTag: openTag,
        closeTag: closeTag,
      );
}
