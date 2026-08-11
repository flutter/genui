// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../../primitives/errors.dart';
import '../../primitives/protocol_version.dart';

/// Repairs and parses the raw JSON a model emitted between the sentinel tags.
///
/// Models reliably produce a handful of near-miss JSON forms. Rather than
/// discard an otherwise sound payload, these are repaired: markdown fences,
/// smart quotes, trailing commas, a single message emitted outside a list, and
/// a missing protocol `version` on the envelope.
abstract final class PayloadFixer {
  /// Parses [payload] into A2UI message envelopes, repairing what it can.
  ///
  /// Throws [A2uiFormatError] when the content is not recoverable JSON.
  static List<Map<String, dynamic>> parseAndFix(
    String payload, {
    ProtocolVersion version = ProtocolVersion.current,
  }) {
    final String sanitized = normalizeSmartQuotes(stripMarkdownFence(payload));
    if (sanitized.trim().isEmpty) {
      throw A2uiFormatError('A2UI payload block is empty.');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(sanitized);
    } on FormatException catch (error) {
      try {
        decoded = jsonDecode(removeTrailingCommas(sanitized));
      } on FormatException {
        throw A2uiFormatError(
          'Failed to parse A2UI JSON payload: ${error.message}',
          source: sanitized,
        );
      }
    }

    final List<Object?> entries = decoded is List ? decoded : [decoded];
    final messages = <Map<String, dynamic>>[];
    for (final entry in entries) {
      if (entry is! Map) {
        throw A2uiFormatError(
          'A2UI payload entries must be JSON objects, got '
          '${entry.runtimeType}.',
          source: sanitized,
        );
      }
      final Map<String, dynamic> message = entry.cast<String, dynamic>();
      messages.add(
        message.containsKey('version')
            ? message
            : {'version': version.wireValue, ...message},
      );
    }
    return messages;
  }

  /// Removes a markdown code fence wrapped around [payload].
  static String stripMarkdownFence(String payload) {
    String trimmed = payload.trim();
    if (trimmed.startsWith('```json')) {
      trimmed = trimmed.substring('```json'.length);
    } else if (trimmed.startsWith('```')) {
      trimmed = trimmed.substring('```'.length);
    } else {
      return trimmed;
    }
    if (trimmed.endsWith('```')) {
      trimmed = trimmed.substring(0, trimmed.length - '```'.length);
    }
    return trimmed.trim();
  }

  /// Replaces smart (curly) quotes with straight quotes.
  static String normalizeSmartQuotes(String json) => json
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('‘', "'")
      .replaceAll('’', "'");

  /// Removes commas that directly precede a closing bracket or brace.
  ///
  /// Commas inside string literals are left alone.
  static String removeTrailingCommas(String json) {
    final buffer = StringBuffer();
    var inString = false;
    var escaped = false;

    for (var i = 0; i < json.length; i++) {
      final String char = json[i];
      if (escaped) {
        escaped = false;
        buffer.write(char);
        continue;
      }
      if (char == r'\' && inString) {
        escaped = true;
        buffer.write(char);
        continue;
      }
      if (char == '"') {
        inString = !inString;
        buffer.write(char);
        continue;
      }
      if (!inString && char == ',') {
        final int next = _nextNonWhitespace(json, i + 1);
        if (next < json.length && (json[next] == ']' || json[next] == '}')) {
          continue;
        }
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  static int _nextNonWhitespace(String value, int from) {
    var index = from;
    while (index < value.length && value[index].trim().isEmpty) {
      index++;
    }
    return index;
  }
}
