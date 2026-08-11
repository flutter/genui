// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../primitives/errors.dart';

/// The kinds of token the Express lexer produces.
enum ExpressTokenType {
  identifier,
  path,
  check,
  number,
  string,
  boolean,
  nullLiteral,
  assign,
  leftParen,
  rightParen,
  leftBracket,
  rightBracket,
  leftBrace,
  rightBrace,
  comma,
  colon,
  underscore,
  eof,
}

/// A lexical token of the Express DSL.
class ExpressToken {
  /// What kind of token this is.
  final ExpressTokenType type;

  /// The token text as written, with quotes and prefixes removed for strings.
  final String lexeme;

  /// The decoded value for literal tokens.
  final Object? value;

  /// The 1-based source line the token starts on.
  final int line;

  /// Whether a string token was written as a raw string.
  final bool isRawString;

  const ExpressToken({
    required this.type,
    required this.lexeme,
    required this.line,
    this.value,
    this.isRawString = false,
  });

  @override
  String toString() => '${type.name}($lexeme)';
}

/// Turns Express source text into tokens.
///
/// Comments (`#`, `//`, `/* */`), semicolons and whitespace are skipped, as in
/// the reference grammar. Identifiers follow the Unicode identifier shape the
/// specification requires: an ASCII letter, an underscore or any non-ASCII
/// character to start, then the same plus digits.
class ExpressLexer {
  /// The source being scanned.
  final String source;

  int _offset = 0;
  int _line = 1;

  ExpressLexer(this.source);

  /// Scans [source] into a token list terminated by an
  /// [ExpressTokenType.eof] token.
  ///
  /// Throws [A2uiFormatError] on an unterminated string or an unexpected
  /// character.
  List<ExpressToken> tokenize() {
    final tokens = <ExpressToken>[];
    while (true) {
      final ExpressToken token = _next();
      tokens.add(token);
      if (token.type == ExpressTokenType.eof) return tokens;
    }
  }

  ExpressToken _next() {
    _skipIgnored();
    if (_offset >= source.length) {
      return ExpressToken(
        type: ExpressTokenType.eof,
        lexeme: '',
        line: _line,
      );
    }

    final int startLine = _line;
    final String char = source[_offset];

    switch (char) {
      case '=':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.assign,
          lexeme: '=',
          line: startLine,
        );
      case '(':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.leftParen,
          lexeme: '(',
          line: startLine,
        );
      case ')':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.rightParen,
          lexeme: ')',
          line: startLine,
        );
      case '[':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.leftBracket,
          lexeme: '[',
          line: startLine,
        );
      case ']':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.rightBracket,
          lexeme: ']',
          line: startLine,
        );
      case '{':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.leftBrace,
          lexeme: '{',
          line: startLine,
        );
      case '}':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.rightBrace,
          lexeme: '}',
          line: startLine,
        );
      case ',':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.comma,
          lexeme: ',',
          line: startLine,
        );
      case ':':
        _offset++;
        return ExpressToken(
          type: ExpressTokenType.colon,
          lexeme: ':',
          line: startLine,
        );
      case r'$':
        return _readPath(startLine);
      case '?':
        return _readCheck(startLine);
      case '"':
        return _readString(startLine, raw: false);
    }

    if ((char == 'r' || char == 'R') &&
        _offset + 1 < source.length &&
        source[_offset + 1] == '"') {
      _offset++;
      return _readString(startLine, raw: true);
    }

    if (_isDigit(char) ||
        (char == '-' &&
            _offset + 1 < source.length &&
            _isDigit(source[_offset + 1]))) {
      return _readNumber(startLine);
    }

    if (_isIdentifierStart(char)) return _readIdentifier(startLine);

    throw A2uiFormatError(
      "Unexpected character '$char' in Express source.",
      line: startLine,
    );
  }

  void _skipIgnored() {
    while (_offset < source.length) {
      final String char = source[_offset];
      if (char == '\n') {
        _line++;
        _offset++;
        continue;
      }
      if (char == ' ' || char == '\t' || char == '\r' || char == ';') {
        _offset++;
        continue;
      }
      if (char == '#' || source.startsWith('//', _offset)) {
        while (_offset < source.length && source[_offset] != '\n') {
          _offset++;
        }
        continue;
      }
      if (source.startsWith('/*', _offset)) {
        final int end = source.indexOf('*/', _offset + 2);
        final int stop = end < 0 ? source.length : end + 2;
        _line += '\n'.allMatches(source.substring(_offset, stop)).length;
        _offset = stop;
        continue;
      }
      return;
    }
  }

  ExpressToken _readPath(int line) {
    final int start = _offset;
    _offset++; // consume '$'
    while (_offset < source.length && _isPathChar(source[_offset])) {
      _offset++;
    }
    final String lexeme = source.substring(start, _offset);
    return ExpressToken(
      type: ExpressTokenType.path,
      lexeme: lexeme,
      value: lexeme.substring(1),
      line: line,
    );
  }

  ExpressToken _readCheck(int line) {
    _offset++; // consume '?'
    final int start = _offset;
    if (_offset >= source.length || !_isIdentifierStart(source[_offset])) {
      throw A2uiFormatError(
        "A check must be written '?name'.",
        line: line,
      );
    }
    while (_offset < source.length && _isIdentifierPart(source[_offset])) {
      _offset++;
    }
    return ExpressToken(
      type: ExpressTokenType.check,
      lexeme: source.substring(start, _offset),
      line: line,
    );
  }

  ExpressToken _readNumber(int line) {
    final int start = _offset;
    if (source[_offset] == '-') _offset++;
    while (_offset < source.length && _isDigit(source[_offset])) {
      _offset++;
    }
    if (_offset < source.length &&
        source[_offset] == '.' &&
        _offset + 1 < source.length &&
        _isDigit(source[_offset + 1])) {
      _offset++;
      while (_offset < source.length && _isDigit(source[_offset])) {
        _offset++;
      }
    }
    final String lexeme = source.substring(start, _offset);
    return ExpressToken(
      type: ExpressTokenType.number,
      lexeme: lexeme,
      value: num.parse(lexeme),
      line: line,
    );
  }

  ExpressToken _readIdentifier(int line) {
    final int start = _offset;
    while (_offset < source.length && _isIdentifierPart(source[_offset])) {
      _offset++;
    }
    final String lexeme = source.substring(start, _offset);

    switch (lexeme) {
      case 'true':
      case 'false':
        return ExpressToken(
          type: ExpressTokenType.boolean,
          lexeme: lexeme,
          value: lexeme == 'true',
          line: line,
        );
      case 'null':
        return ExpressToken(
          type: ExpressTokenType.nullLiteral,
          lexeme: lexeme,
          line: line,
        );
      case '_':
        return ExpressToken(
          type: ExpressTokenType.underscore,
          lexeme: lexeme,
          line: line,
        );
    }

    return ExpressToken(
      type: ExpressTokenType.identifier,
      lexeme: lexeme,
      line: line,
    );
  }

  ExpressToken _readString(int line, {required bool raw}) {
    final bool triple = source.startsWith('"""', _offset);
    final delimiter = triple ? '"""' : '"';
    _offset += delimiter.length;

    final buffer = StringBuffer();
    while (true) {
      if (_offset >= source.length) {
        throw A2uiFormatError('Unterminated string literal.', line: line);
      }
      if (source.startsWith(delimiter, _offset)) {
        _offset += delimiter.length;
        break;
      }
      final String char = source[_offset];
      if (char == '\n') {
        if (!triple && !raw) {
          throw A2uiFormatError('Unterminated string literal.', line: line);
        }
        _line++;
      }
      if (char == r'\' && !raw) {
        _offset++;
        if (_offset >= source.length) {
          throw A2uiFormatError('Unterminated escape sequence.', line: line);
        }
        buffer.write(_unescape(source[_offset], line));
        _offset++;
        continue;
      }
      buffer.write(char);
      _offset++;
    }

    return ExpressToken(
      type: ExpressTokenType.string,
      lexeme: buffer.toString(),
      value: buffer.toString(),
      line: line,
      isRawString: raw,
    );
  }

  String _unescape(String char, int line) {
    switch (char) {
      case 'n':
        return '\n';
      case 't':
        return '\t';
      case 'r':
        return '\r';
      case 'b':
        return '\b';
      case 'f':
        return '\f';
      case '"':
        return '"';
      case r'\':
        return r'\';
      case '/':
        return '/';
      case 'u':
        final int start = _offset + 1;
        if (start + 4 > source.length) {
          throw A2uiFormatError('Truncated unicode escape.', line: line);
        }
        final String hex = source.substring(start, start + 4);
        final int? code = int.tryParse(hex, radix: 16);
        if (code == null) {
          throw A2uiFormatError(
            "Invalid unicode escape '\\u$hex'.",
            line: line,
          );
        }
        _offset += 4;
        return String.fromCharCode(code);
      default:
        return char;
    }
  }

  static bool _isDigit(String char) =>
      char.compareTo('0') >= 0 && char.compareTo('9') <= 0;

  static bool _isPathChar(String char) =>
      _isDigit(char) ||
      char == '/' ||
      char == '_' ||
      _isAsciiLetter(char) ||
      char.codeUnitAt(0) > 0x7f;

  static bool _isAsciiLetter(String char) =>
      (char.compareTo('a') >= 0 && char.compareTo('z') <= 0) ||
      (char.compareTo('A') >= 0 && char.compareTo('Z') <= 0);

  static bool _isIdentifierStart(String char) =>
      _isAsciiLetter(char) || char == '_' || char.codeUnitAt(0) > 0x7f;

  static bool _isIdentifierPart(String char) =>
      _isIdentifierStart(char) || _isDigit(char);
}
