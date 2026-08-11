// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../../parser/incremental_processor.dart';
import '../../parser/parser.dart';
import '../../parser/response_part.dart';
import '../../primitives/errors.dart';
import '../../primitives/protocol_version.dart';
import '../../validation/payload_validator.dart';
import 'compiler.dart';
import 'constants.dart';
import 'decompiler.dart';
import 'statement_splitter.dart';
import 'syntax_parser.dart';

/// Parses A2UI Express payloads enclosed in `<a2ui-express>` tags.
class ExpressParser extends Parser {
  /// The active catalogs signatures are resolved against.
  final List<Catalog<ComponentApi>> catalogs;

  /// The surface used when a block does not call `surface(...)`.
  final String defaultSurfaceId;

  /// The protocol version emitted messages declare.
  final ProtocolVersion protocolVersion;

  /// Surfaces the renderer already has, which must not be created again.
  final Set<String> existingSurfaceIds;

  /// Whether compiled payloads are checked for dangling child references and
  /// reference cycles.
  final bool checkReferences;

  ExpressStreamProcessor? _stream;

  ExpressParser({
    required this.catalogs,
    this.defaultSurfaceId = expressDefaultSurfaceId,
    this.protocolVersion = ProtocolVersion.current,
    this.existingSurfaceIds = const {},
    this.checkReferences = false,
  });

  @override
  String get openTag => expressOpenTag;

  @override
  String get closeTag => expressCloseTag;

  @override
  List<AgentToRendererMessage> compile(String formatContent) {
    final List<AgentToRendererMessage> messages = _newCompiler().compile(
      formatContent,
    );
    _validator.validateOrThrow(messages, checkReferences: checkReferences);
    return messages;
  }

  @override
  String decompile(List<AgentToRendererMessage> a2uiPayload) =>
      ExpressDecompiler(catalogs: catalogs).decompile(a2uiPayload);

  @override
  List<ResponsePart> parseChunk(String chunk, {bool wrapped = true}) =>
      _processor.add(chunk, wrapped: wrapped);

  @override
  List<ResponsePart> flush() => _processor.flush();

  ExpressCompiler _newCompiler() => ExpressCompiler(
    catalogs: catalogs,
    defaultSurfaceId: defaultSurfaceId,
    protocolVersion: protocolVersion,
    existingSurfaceIds: existingSurfaceIds,
  );

  A2uiPayloadValidator get _validator => A2uiPayloadValidator(
    catalogs: catalogs,
    protocolVersion: protocolVersion,
  );

  ExpressStreamProcessor get _processor =>
      _stream ??= ExpressStreamProcessor(
        createCompiler: _newCompiler,
        validator: _validator,
        openTag: openTag,
        closeTag: closeTag,
      );
}

/// Compiles Express statements as they stream in.
///
/// Express is line oriented, so a block can be compiled statement by statement
/// rather than re-parsed from the top on every chunk: each completed statement
/// is handed to a long-lived [ExpressCompiler] session that carries the
/// surface, the catalog and the ids handed out so far.
class ExpressStreamProcessor extends IncrementalStreamProcessor {
  /// Creates the compiler session used for a block.
  final ExpressCompiler Function() createCompiler;

  /// Validates the messages produced for each statement.
  final A2uiPayloadValidator validator;

  ExpressCompiler? _compiler;
  int _consumed = 0;

  ExpressStreamProcessor({
    required this.createCompiler,
    required this.validator,
    required super.openTag,
    required super.closeTag,
  });

  @override
  void resetBlock() {
    _compiler = null;
    _consumed = 0;
  }

  @override
  List<AgentToRendererMessage> emitDelta(
    String rawBlock, {
    required bool blockComplete,
  }) {
    if (_consumed > rawBlock.length) return const [];
    final String pending = rawBlock.substring(_consumed);

    if (blockComplete && pending.trim().isNotEmpty) {
      try {
        return _compile(pending, rawBlock.length);
      } on A2uiFormatError {
        // The stream stopped mid-statement. Salvage the statements that did
        // arrive in full rather than losing the whole block.
        final int prefix = completeStatementPrefixLength(pending);
        if (prefix == 0) return const [];
        return _compile(pending.substring(0, prefix), _consumed + prefix);
      }
    }

    final int prefix = completeStatementPrefixLength(pending);
    if (prefix == 0) return const [];
    return _compile(pending.substring(0, prefix), _consumed + prefix);
  }

  List<AgentToRendererMessage> _compile(String source, int consumed) {
    _consumed = consumed;
    if (source.trim().isEmpty) return const [];

    final ExpressCompiler compiler = _compiler ??= createCompiler();
    final List<AgentToRendererMessage> messages = compiler.compileStatements(
      ExpressSyntaxParser.fromSource(source).parseProgram(),
    );
    if (messages.isNotEmpty) validator.validateOrThrow(messages);
    return messages;
  }
}
