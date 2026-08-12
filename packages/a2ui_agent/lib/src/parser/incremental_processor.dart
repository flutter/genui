// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'response_part.dart';
import 'sentinel_tokenizer.dart';

/// Shared streaming plumbing for format parsers.
///
/// The processor owns the sentinel tokenizer and the raw buffer for the block
/// currently being streamed. Formats only implement [emitDelta], which is
/// handed the whole raw block accumulated so far and returns the messages that
/// have not been emitted yet.
abstract class IncrementalStreamProcessor {
  final SentinelTokenizer _tokenizer;
  final StringBuffer _block = StringBuffer();
  bool _inBlock = false;
  bool _wrapped = true;

  IncrementalStreamProcessor({
    required String openTag,
    required String closeTag,
  }) : _tokenizer = SentinelTokenizer(openTag: openTag, closeTag: closeTag);

  /// Returns the messages of [rawBlock] that have not been emitted yet.
  ///
  /// [rawBlock] is the complete raw content of the current block accumulated
  /// so far, not a delta. [blockComplete] is true once the closing sentinel
  /// tag has been seen, or once the stream ended, at which point the format
  /// should salvage whatever it can from a truncated payload.
  ///
  /// Implementations must track their own emission state and must not emit the
  /// same content twice.
  List<AgentToRendererMessage> emitDelta(
    String rawBlock, {
    required bool blockComplete,
  });

  /// Discards per-block emission state, called when a new block starts.
  void resetBlock();

  /// Consumes a streamed [chunk].
  ///
  /// When [wrapped] is false the chunk is treated as raw payload content with
  /// no surrounding sentinel tags.
  List<ResponsePart> add(String chunk, {bool wrapped = true}) {
    _wrapped = wrapped;
    if (!wrapped) {
      if (!_inBlock) {
        _inBlock = true;
        resetBlock();
      }
      _block.write(chunk);
      return _emit(blockComplete: false);
    }

    final parts = <ResponsePart>[];
    for (final SentinelToken token in _tokenizer.add(chunk)) {
      parts.addAll(_handle(token));
    }
    return parts;
  }

  /// Flushes buffered state at the end of the stream.
  ///
  /// [wrapped] defaults to whatever the last [add] call used, so a stream that
  /// was parsed unwrapped is also flushed unwrapped.
  List<ResponsePart> flush({bool? wrapped}) {
    final parts = <ResponsePart>[];
    if (wrapped ?? _wrapped) {
      for (final SentinelToken token in _tokenizer.flush()) {
        parts.addAll(_handle(token));
      }
    }
    if (_inBlock) {
      parts.addAll(_emit(blockComplete: true));
      _inBlock = false;
      _block.clear();
    }
    return parts;
  }

  List<ResponsePart> _handle(SentinelToken token) {
    switch (token) {
      case TextToken(text: final String text):
        return text.isEmpty ? const [] : [TextPart(text)];
      case BlockStartToken():
        _inBlock = true;
        _block.clear();
        resetBlock();
        return const [];
      case BlockContentToken(content: final String content):
        _block.write(content);
        return _emit(blockComplete: false);
      case BlockEndToken():
        final List<ResponsePart> parts = _emit(blockComplete: true);
        _inBlock = false;
        _block.clear();
        return parts;
    }
  }

  List<ResponsePart> _emit({required bool blockComplete}) {
    final List<AgentToRendererMessage> messages = emitDelta(
      _block.toString(),
      blockComplete: blockComplete,
    );
    return messages.isEmpty ? const [] : [A2uiPart(messages)];
  }
}
