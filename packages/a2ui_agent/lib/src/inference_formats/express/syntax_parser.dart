// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../primitives/errors.dart';
import 'ast.dart';
import 'lexer.dart';

/// Builds the Express abstract syntax tree from tokens.
///
/// The grammar is the reference `Express.g4`: a program is a sequence of
/// variable assignments, data-path assignments and standalone calls, with
/// expressions covering literals, paths, arrays, maps, checks, calls and
/// variable references.
class ExpressSyntaxParser {
  /// The tokens to parse, terminated by an end-of-file token.
  final List<ExpressToken> tokens;

  int _position = 0;

  ExpressSyntaxParser(this.tokens);

  /// Tokenizes and parses [source].
  factory ExpressSyntaxParser.fromSource(String source) =>
      ExpressSyntaxParser(ExpressLexer(source).tokenize());

  /// Parses the whole program.
  List<ExpressStatement> parseProgram() {
    final statements = <ExpressStatement>[];
    while (!_isAtEnd) {
      statements.add(_parseStatement());
    }
    return statements;
  }

  bool get _isAtEnd => _peek.type == ExpressTokenType.eof;

  ExpressToken get _peek => tokens[_position];

  ExpressToken get _previous => tokens[_position - 1];

  ExpressToken _advance() => tokens[_position++];

  bool _check(ExpressTokenType type) => _peek.type == type;

  bool _match(ExpressTokenType type) {
    if (!_check(type)) return false;
    _position++;
    return true;
  }

  ExpressToken _expect(ExpressTokenType type, String description) {
    if (_check(type)) return _advance();
    throw A2uiFormatError(
      'Expected $description but found '
      "'${_peek.lexeme.isEmpty ? 'end of input' : _peek.lexeme}'.",
      line: _peek.line,
    );
  }

  ExpressStatement _parseStatement() {
    final ExpressToken token = _peek;

    if (token.type == ExpressTokenType.path &&
        tokens[_position + 1].type == ExpressTokenType.assign) {
      _advance();
      _advance();
      return DataAssignment(
        token.line,
        token.value! as String,
        _parseExpression(),
      );
    }

    if (token.type == ExpressTokenType.identifier &&
        tokens[_position + 1].type == ExpressTokenType.assign) {
      _advance();
      _advance();
      return VariableAssignment(token.line, token.lexeme, _parseExpression());
    }

    final ExpressExpression expression = _parseExpression();
    if (expression is! CallExpression) {
      throw A2uiFormatError(
        'A standalone statement must be a call, such as surface("main").',
        line: token.line,
      );
    }
    return CallStatement(token.line, expression);
  }

  ExpressExpression _parseExpression() {
    final ExpressToken token = _peek;
    switch (token.type) {
      case ExpressTokenType.leftBracket:
        return _parseArray();
      case ExpressTokenType.leftBrace:
        return _parseMap();
      case ExpressTokenType.path:
        _advance();
        return PathExpression(token.line, token.value! as String);
      case ExpressTokenType.check:
        return _parseCheck();
      case ExpressTokenType.identifier:
        return _parseIdentifierExpression();
      case ExpressTokenType.underscore:
        _advance();
        return SkippedExpression(token.line);
      case ExpressTokenType.string:
        _advance();
        return LiteralExpression(
          token.line,
          token.value,
          isRawString: token.isRawString,
        );
      case ExpressTokenType.number:
      case ExpressTokenType.boolean:
        _advance();
        return LiteralExpression(token.line, token.value);
      case ExpressTokenType.nullLiteral:
        _advance();
        return LiteralExpression(token.line, null);
      default:
        throw A2uiFormatError(
          "Unexpected token '${token.lexeme}' where a value was expected.",
          line: token.line,
        );
    }
  }

  ExpressExpression _parseIdentifierExpression() {
    final ExpressToken name = _advance();
    if (!_check(ExpressTokenType.leftParen)) {
      return VariableExpression(name.line, name.lexeme);
    }
    return CallExpression(name.line, name.lexeme, _parseArguments());
  }

  List<ExpressArgument> _parseArguments() {
    _expect(ExpressTokenType.leftParen, "'('");
    final arguments = <ExpressArgument>[];
    if (_match(ExpressTokenType.rightParen)) return arguments;

    while (true) {
      if (_check(ExpressTokenType.identifier) &&
          tokens[_position + 1].type == ExpressTokenType.assign) {
        final ExpressToken name = _advance();
        _advance();
        arguments.add(
          ExpressArgument(name: name.lexeme, value: _parseExpression()),
        );
      } else {
        arguments.add(ExpressArgument(value: _parseExpression()));
      }

      if (_match(ExpressTokenType.comma)) {
        if (_match(ExpressTokenType.rightParen)) return arguments;
        continue;
      }
      _expect(ExpressTokenType.rightParen, "')' or ','");
      return arguments;
    }
  }

  ExpressExpression _parseArray() {
    final ExpressToken open = _advance();
    final items = <ExpressExpression>[];
    if (_match(ExpressTokenType.rightBracket)) {
      return ArrayExpression(open.line, items);
    }

    while (true) {
      items.add(_parseExpression());
      if (_match(ExpressTokenType.comma)) {
        if (_match(ExpressTokenType.rightBracket)) {
          return ArrayExpression(open.line, items);
        }
        continue;
      }
      _expect(ExpressTokenType.rightBracket, "']' or ','");
      return ArrayExpression(open.line, items);
    }
  }

  ExpressExpression _parseMap() {
    final ExpressToken open = _advance();
    final entries = <String, ExpressExpression>{};
    if (_match(ExpressTokenType.rightBrace)) {
      return MapExpression(open.line, entries);
    }

    while (true) {
      if (!_match(ExpressTokenType.identifier) &&
          !_match(ExpressTokenType.string)) {
        throw A2uiFormatError(
          'A map key must be an identifier or a string.',
          line: _peek.line,
        );
      }
      final ExpressToken key = _previous;
      _expect(ExpressTokenType.colon, "':'");
      entries[key.lexeme] = _parseExpression();

      if (_match(ExpressTokenType.comma)) {
        if (_match(ExpressTokenType.rightBrace)) {
          return MapExpression(open.line, entries);
        }
        continue;
      }
      _expect(ExpressTokenType.rightBrace, "'}' or ','");
      return MapExpression(open.line, entries);
    }
  }

  ExpressExpression _parseCheck() {
    final ExpressToken name = _advance();
    final arguments = <ExpressExpression>[];
    if (!_check(ExpressTokenType.leftParen)) {
      return CheckExpression(name.line, name.lexeme, arguments);
    }
    for (final ExpressArgument argument in _parseArguments()) {
      if (argument.name != null) {
        throw A2uiFormatError(
          'A check does not take named arguments.',
          line: name.line,
        );
      }
      arguments.add(argument.value);
    }
    return CheckExpression(name.line, name.lexeme, arguments);
  }
}
