// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'response_part.dart';

/// An event produced by [SentinelTokenizer].
sealed class SentinelToken {
  const SentinelToken();
}

/// Conversational text that appeared outside any sentinel-tagged block.
final class TextToken extends SentinelToken {
  /// The newly available text. In streaming mode this is a delta, not the
  /// accumulated run.
  final String text;

  const TextToken(this.text);
}

/// Marks the point where an opening sentinel tag was consumed.
final class BlockStartToken extends SentinelToken {
  const BlockStartToken();
}

/// Raw content from inside a sentinel-tagged block.
final class BlockContentToken extends SentinelToken {
  /// The newly available raw content. In streaming mode this is a delta.
  final String content;

  const BlockContentToken(this.content);

  @override
  String toString() => 'BlockContentToken($content)';
}

/// Marks the end of a sentinel-tagged block.
final class BlockEndToken extends SentinelToken {
  /// Whether the block was terminated by its closing tag.
  ///
  /// This is `false` when the stream ended while a block was still open, which
  /// happens when a model is cut off mid-payload.
  final bool terminated;

  const BlockEndToken({required this.terminated});
}

/// Splits a response, or a stream of response chunks, into conversational text
/// and the raw content of sentinel-tagged blocks.
///
/// The tokenizer never emits text that could still turn out to be the start of
/// a sentinel tag: a trailing partial tag is held back until the next chunk
/// resolves it, so `<a2ui` split across two chunks is not leaked to the caller
/// as conversational text.
class SentinelTokenizer {
  /// The tag that opens a raw payload block, e.g. `<a2ui-json>`.
  final String openTag;

  /// The tag that closes a raw payload block, e.g. `</a2ui-json>`.
  final String closeTag;

  final StringBuffer _buffer = StringBuffer();
  bool _inBlock = false;

  SentinelTokenizer({required this.openTag, required this.closeTag});

  /// Whether the tokenizer is currently inside a sentinel-tagged block.
  bool get inBlock => _inBlock;

  /// Consumes [chunk] and returns every token that became unambiguous.
  List<SentinelToken> add(String chunk) {
    _buffer.write(chunk);
    final tokens = <SentinelToken>[];
    var rest = _buffer.toString();
    _buffer.clear();

    while (true) {
      final String tag = _inBlock ? closeTag : openTag;
      final int index = rest.indexOf(tag);
      if (index < 0) {
        // Hold back anything that might be the beginning of `tag`.
        final int keep = _partialTagSuffixLength(rest, tag);
        final String emit = rest.substring(0, rest.length - keep);
        if (emit.isNotEmpty) {
          tokens.add(
            _inBlock ? BlockContentToken(emit) : TextToken(emit),
          );
        }
        _buffer.write(rest.substring(rest.length - keep));
        return tokens;
      }

      final String emit = rest.substring(0, index);
      if (emit.isNotEmpty) {
        tokens.add(_inBlock ? BlockContentToken(emit) : TextToken(emit));
      }
      tokens.add(
        _inBlock ? const BlockEndToken(terminated: true) : const
            BlockStartToken(),
      );
      _inBlock = !_inBlock;
      rest = rest.substring(index + tag.length);
    }
  }

  /// Flushes buffered content once the stream has ended.
  ///
  /// An unterminated block is closed with `BlockEndToken(terminated: false)`
  /// so that callers can decide whether to salvage a truncated payload.
  List<SentinelToken> flush() {
    final tokens = <SentinelToken>[];
    final rest = _buffer.toString();
    _buffer.clear();
    if (rest.isNotEmpty) {
      tokens.add(_inBlock ? BlockContentToken(rest) : TextToken(rest));
    }
    if (_inBlock) {
      tokens.add(const BlockEndToken(terminated: false));
      _inBlock = false;
    }
    return tokens;
  }

  /// Tokenizes a complete [content] string into ordered [RawResponsePart]s.
  ///
  /// Conversational text is trimmed and empty runs are dropped; raw block
  /// content is preserved verbatim.
  static List<RawResponsePart> unwrap(
    String content, {
    required String openTag,
    required String closeTag,
  }) {
    final tokenizer = SentinelTokenizer(openTag: openTag, closeTag: closeTag);
    final List<SentinelToken> tokens = [
      ...tokenizer.add(content),
      ...tokenizer.flush(),
    ];

    final parts = <RawResponsePart>[];
    final text = StringBuffer();
    final raw = StringBuffer();
    var inBlock = false;

    void flushText() {
      final String value = text.toString().trim();
      text.clear();
      if (value.isNotEmpty) parts.add(RawResponsePart(TextPart(value)));
    }

    for (final token in tokens) {
      switch (token) {
        case TextToken(text: final String chunk):
          text.write(chunk);
        case BlockStartToken():
          flushText();
          inBlock = true;
        case BlockContentToken(content: final String content):
          raw.write(content);
        case BlockEndToken(terminated: final bool terminated):
          parts.add(
            RawResponsePart(
              RawA2uiPart(raw.toString()),
              isFinal: terminated,
            ),
          );
          raw.clear();
          inBlock = false;
      }
    }
    if (!inBlock) flushText();
    return parts;
  }

  /// The length of the longest suffix of [value] that is a proper prefix of
  /// [tag].
  static int _partialTagSuffixLength(String value, String tag) {
    final int max = value.length < tag.length - 1
        ? value.length
        : tag.length - 1;
    for (var length = max; length > 0; length--) {
      if (value.endsWith(tag.substring(0, length))) return length;
    }
    return 0;
  }
}
