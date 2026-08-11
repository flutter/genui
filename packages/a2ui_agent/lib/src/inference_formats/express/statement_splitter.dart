// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The length of the prefix of [source] that contains only complete
/// statements.
///
/// Express is line oriented: a statement ends at a newline or `;` that is not
/// inside brackets, a string or a comment. A statement that spans lines —
/// because a call's argument list is still open — is not complete until its
/// brackets close, so a streaming compiler must hold it back.
///
/// Returns 0 when nothing is complete yet.
int completeStatementPrefixLength(String source) {
  var index = 0;
  var depth = 0;
  var boundary = 0;

  while (index < source.length) {
    final String char = source[index];

    if (char == '"' || _isRawStringStart(source, index)) {
      final int end = _skipString(source, index);
      if (end < 0) return boundary;
      index = end;
      continue;
    }

    if (char == '#' || source.startsWith('//', index)) {
      while (index < source.length && source[index] != '\n') {
        index++;
      }
      continue;
    }

    if (source.startsWith('/*', index)) {
      final int end = source.indexOf('*/', index + 2);
      if (end < 0) return boundary;
      index = end + 2;
      continue;
    }

    if (char == '(' || char == '[' || char == '{') {
      depth++;
    } else if (char == ')' || char == ']' || char == '}') {
      if (depth > 0) depth--;
    } else if (depth == 0 && (char == '\n' || char == ';')) {
      boundary = index + 1;
    }
    index++;
  }

  return boundary;
}

bool _isRawStringStart(String source, int index) {
  final String char = source[index];
  if (char != 'r' && char != 'R') return false;
  if (index + 1 >= source.length || source[index + 1] != '"') return false;
  if (index == 0) return true;
  final String previous = source[index - 1];
  // `r"` only starts a raw string when `r` is not part of an identifier.
  return !_isIdentifierPart(previous);
}

bool _isIdentifierPart(String char) {
  final int code = char.codeUnitAt(0);
  return char == '_' ||
      code > 0x7f ||
      (code >= 0x30 && code <= 0x39) ||
      (code >= 0x41 && code <= 0x5a) ||
      (code >= 0x61 && code <= 0x7a);
}

/// Returns the index just past the string literal starting at [start], or -1
/// when the literal is unterminated.
int _skipString(String source, int start) {
  var index = start;
  final bool raw = source[index] == 'r' || source[index] == 'R';
  if (raw) index++;

  final delimiter = source.startsWith('"""', index) ? '"""' : '"';
  index += delimiter.length;

  while (index < source.length) {
    if (!raw && source[index] == r'\') {
      index += 2;
      continue;
    }
    if (source.startsWith(delimiter, index)) return index + delimiter.length;
    index++;
  }
  return -1;
}
