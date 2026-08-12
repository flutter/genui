// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'response_part.dart';
import 'sentinel_tokenizer.dart';

/// Base class for response parsers across all inference format strategies.
///
/// A parser tokenizes LLM output, unwraps the format's sentinel tags, and
/// compiles the raw format expressions it finds into A2UI messages.
///
/// Parsers are turn-scoped: [parseChunk] accumulates streaming state, so a
/// fresh parser must be created for each model turn (see
/// `InferenceFormat.createParser`).
abstract class Parser {
  const Parser();

  /// The tag that opens a raw payload block for this format.
  String get openTag;

  /// The tag that closes a raw payload block for this format.
  String get closeTag;

  /// Converts [blocks] back into a single string, re-adding the sentinel tags
  /// around each raw A2UI section and concatenating conversational text.
  String wrap(List<RawResponsePart> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      switch (block.part) {
        case TextPart(text: final String text):
          buffer.write(text);
        case RawA2uiPart(a2uiRaw: final String a2uiRaw):
          buffer
            ..write(openTag)
            ..write(a2uiRaw)
            ..write(closeTag);
      }
    }
    return buffer.toString();
  }

  /// Tokenizes an LLM response into an ordered list of [RawResponsePart]s.
  ///
  /// Conversational text and tagged payload blocks are returned in exactly the
  /// order the model emitted them.
  List<RawResponsePart> unwrap(String content) =>
      SentinelTokenizer.unwrap(content, openTag: openTag, closeTag: closeTag);

  /// Compiles a raw format content string into A2UI messages.
  ///
  /// Throws [A2uiFormatError](../primitives/errors.dart) when the content
  /// cannot be compiled.
  List<AgentToRendererMessage> compile(String formatContent);

  /// Decompiles A2UI messages back into this format's raw notation.
  String decompile(List<AgentToRendererMessage> a2uiPayload);

  /// Parses a complete, non-streamed response.
  ///
  /// When [wrapped] is true the content is unwrapped first and the
  /// chronological order of text and payload blocks is preserved; otherwise
  /// the whole of [content] is compiled as a single payload.
  List<ResponsePart> parseResponse(String content, {bool wrapped = true}) {
    if (!wrapped) return [A2uiPart(compile(content))];

    final result = <ResponsePart>[];
    for (final RawResponsePart rawPart in unwrap(content)) {
      switch (rawPart.part) {
        case TextPart part:
          result.add(part);
        case RawA2uiPart(a2uiRaw: final String a2uiRaw):
          result.add(A2uiPart(compile(a2uiRaw)));
      }
    }
    return result;
  }

  /// Processes an incremental [chunk] of a streamed response.
  ///
  /// Returns only what became available since the previous call. Call [flush]
  /// once the stream ends to release anything still buffered.
  List<ResponsePart> parseChunk(String chunk, {bool wrapped = true});

  /// Releases buffered streaming state at the end of a stream.
  ///
  /// A payload block left unterminated by the model is salvaged here if the
  /// format can repair it.
  List<ResponsePart> flush();

  /// Parses a stream of response chunks into a stream of [ResponsePart]s.
  ///
  /// This is a convenience wrapper around [parseChunk] and [flush].
  Stream<ResponsePart> parseStream(
    Stream<String> chunks, {
    bool wrapped = true,
  }) async* {
    await for (final chunk in chunks) {
      yield* Stream<ResponsePart>.fromIterable(
        parseChunk(chunk, wrapped: wrapped),
      );
    }
    yield* Stream<ResponsePart>.fromIterable(flush());
  }
}
