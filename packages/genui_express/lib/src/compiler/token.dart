// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The token kinds supported by the A2UI Express lexer.
enum TokenKind {
  /// String literal token enclosed in double quotes (e.g. `"label"`).
  string,

  /// Absolute or relative path reference in the data model (starts with `$`
  /// followed by alphanumeric path segments).
  path,

  /// Client-side check rule validation (starts with `?` followed by the check
  /// name).
  check,

  /// Numeric literal token (integer or decimal).
  number,

  /// Boolean literal token (`true` or `false`).
  boolean,

  /// Null value literal token (`null`).
  nullValue,

  /// An alphanumeric identifier representing a component or function name.
  identifier,

  /// Left parenthesis token `(`.
  lparen,

  /// Right parenthesis token `)`.
  rparen,

  /// Left bracket token `[`.
  lbracket,

  /// Right bracket token `]`.
  rbracket,

  /// Comma separator token `,`.
  comma,

  /// Equals assignment token `=`.
  equals,

  /// Colon key-value separator token `:`.
  colon,

  /// Left curly brace token `{`.
  lbrace,

  /// Right curly brace token `}`.
  rbrace,

  /// Whitespace token (ignored by parser).
  ws,
}

/// Represents a lexical token parsed from A2UI Express input.
class Token {
  /// The category/type of this token.
  final TokenKind kind;

  /// The parsed semantic value (e.g., `double`, `bool`, or stripped `String`).
  final Object? value;

  /// The raw matched substring from the input source code.
  final String text;

  /// Creates a lexical [Token] with its type, value, and original source text.
  Token(this.kind, this.value, this.text);

  @override
  String toString() => 'Token(${kind.name}, $value)';
}

/// Scans the input [text] and produces a flat list of scanned [Token]
/// objects.
///
/// Throws a [FormatException] if any unrecognized character sequence is
/// encountered.
List<Token> tokenize(String text) {
  final List<Token> tokens = [];
  var index = 0;

  final patterns = <(TokenKind, RegExp)>[
    (TokenKind.ws, RegExp(r'^\s+')),
    (TokenKind.string, RegExp(r'^"(?:[^"\\]|\\.)*"')),
    (TokenKind.path, RegExp(r'^\$[a-zA-Z0-9_/]+')),
    (TokenKind.check, RegExp(r'^\?[a-zA-Z_][a-zA-Z0-9_]*')),
    (TokenKind.number, RegExp(r'^-?\d+(?:\.\d+)?')),
    (TokenKind.boolean, RegExp(r'^\b(?:true|false)\b')),
    (TokenKind.nullValue, RegExp(r'^\bnull\b')),
    (TokenKind.identifier, RegExp(r'^[a-zA-Z_][a-zA-Z0-9_-]*')),
    (TokenKind.lparen, RegExp(r'^\(')),
    (TokenKind.rparen, RegExp(r'^\)')),
    (TokenKind.lbracket, RegExp(r'^\[')),
    (TokenKind.rbracket, RegExp(r'^\]')),
    (TokenKind.comma, RegExp(r'^,')),
    (TokenKind.equals, RegExp(r'^=')),
    (TokenKind.colon, RegExp(r'^:')),
    (TokenKind.lbrace, RegExp(r'^\{')),
    (TokenKind.rbrace, RegExp(r'^\}')),
  ];

  while (index < text.length) {
    final String substring = text.substring(index);
    var matched = false;
    for (final (kind, regex) in patterns) {
      final RegExpMatch? match = regex.firstMatch(substring);
      if (match != null) {
        final String matchedText = match.group(0)!;
        index += matchedText.length;
        matched = true;

        if (kind == TokenKind.ws) {
          break; // skip whitespace
        }

        Object? value = matchedText;
        if (kind == TokenKind.string) {
          value = matchedText
              .substring(1, matchedText.length - 1)
              .replaceAll(r'\"', '"');
        } else if (kind == TokenKind.number) {
          value = num.parse(matchedText);
        } else if (kind == TokenKind.boolean) {
          value = matchedText == 'true';
        } else if (kind == TokenKind.nullValue) {
          value = null;
        }

        tokens.add(Token(kind, value, matchedText));
        break;
      }
    }
    if (!matched) {
      throw FormatException('Unexpected character at index $index in "$text"');
    }
  }
  return tokens;
}
