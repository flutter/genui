// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';

/// A lightweight JSON syntax highlighter that produces colored [TextSpan]s.
///
/// Uses a simple regex-based approach to highlight JSON keys, strings, numbers,
/// booleans, and null values without requiring external packages.
class JsonHighlighter {
  JsonHighlighter._();

  static final JsonHighlighter instance = JsonHighlighter._();

  // Colors inspired by VS Code's light theme
  static const Color _keyColor = Color(0xFF0451A5); // Blue
  static const Color _stringColor = Color(0xFFA31515); // Red
  static const Color _numberColor = Color(0xFF098658); // Green
  static const Color _boolNullColor = Color(0xFF0000FF); // Blue
  static const Color _braceColor = Color(0xFF000000); // Black
  static const Color _defaultColor = Color(0xFF000000); // Black

  /// Highlights a JSON string and returns a [TextSpan] with syntax coloring.
  TextSpan highlight(String json) {
    final spans = <TextSpan>[];

    // JSON token regex
    final regex = RegExp(
      r'("(?:[^"\\]|\\.)*")\s*:' // key: "..." followed by ':'
      r'|("(?:[^"\\]|\\.)*")' // string value
      r'|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)' // number
      r'|(true|false|null)' // boolean/null
      r'|([{}\[\],:])' // structural characters
      r'|(\s+)', // whitespace
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(json)) {
      // Add any unmatched text before this match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: json.substring(lastEnd, match.start),
            style: const TextStyle(color: _defaultColor),
          ),
        );
      }

      if (match.group(1) != null) {
        // JSON key (with the colon)
        final keyPart = match.group(1)!;
        final colonPart = json.substring(
          match.start + keyPart.length,
          match.end,
        );
        spans.add(
          TextSpan(
            text: keyPart,
            style: const TextStyle(color: _keyColor),
          ),
        );
        spans.add(
          TextSpan(
            text: colonPart,
            style: const TextStyle(color: _braceColor),
          ),
        );
      } else if (match.group(2) != null) {
        // String value
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(color: _stringColor),
          ),
        );
      } else if (match.group(3) != null) {
        // Number
        spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(color: _numberColor),
          ),
        );
      } else if (match.group(4) != null) {
        // Boolean or null
        spans.add(
          TextSpan(
            text: match.group(4),
            style: const TextStyle(
              color: _boolNullColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (match.group(5) != null) {
        // Structural characters: {, }, [, ], ,, :
        spans.add(
          TextSpan(
            text: match.group(5),
            style: const TextStyle(color: _braceColor),
          ),
        );
      } else if (match.group(6) != null) {
        // Whitespace
        spans.add(TextSpan(text: match.group(6)));
      }

      lastEnd = match.end;
    }

    // Add any remaining text
    if (lastEnd < json.length) {
      spans.add(
        TextSpan(
          text: json.substring(lastEnd),
          style: const TextStyle(color: _defaultColor),
        ),
      );
    }

    return TextSpan(
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.5,
      ),
      children: spans,
    );
  }

  /// Pretty-prints a JSONL string (one JSON object per line, each formatted).
  static String prettyPrintJsonl(String jsonl) {
    final lines = const LineSplitter()
        .convert(jsonl)
        .where((line) => line.trim().isNotEmpty);

    final formatted = <String>[];
    for (final line in lines) {
      try {
        final parsed = jsonDecode(line.trim());
        formatted.add(const JsonEncoder.withIndent('  ').convert(parsed));
      } catch (_) {
        // If it's not valid JSON, keep the line as-is
        formatted.add(line);
      }
    }
    return formatted.join('\n\n');
  }
}
