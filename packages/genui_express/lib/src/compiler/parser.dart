// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'token.dart';

/// A recursive-descent parser that parses a list of [Token] objects into an
/// AST.
class TokenParser {
  /// The sequence of scanned tokens.
  final List<Token> tokens;

  /// The current parsing index pointer.
  int pos = 0;

  /// Creates a [TokenParser] wrapping a token stream.
  TokenParser(this.tokens);

  /// Inspects the current token at the pointer without consuming it.
  Token? peek() {
    if (pos < tokens.length) {
      return tokens[pos];
    }
    return null;
  }

  /// Consumes and returns the current token, optionally validating its [kind].
  ///
  /// Throws a [FormatException] if the pointer is at the end of input or
  /// if the token category mismatch.
  Token consume([TokenKind? kind]) {
    final Token? tok = peek();
    if (tok == null) {
      throw const FormatException('Unexpected end of input');
    }
    if (kind != null && tok.kind != kind) {
      throw FormatException(
        'Expected ${kind.name}, got ${tok.kind.name}: ${tok.text}',
      );
    }
    pos++;
    return tok;
  }

  /// Parses the current expression subtree recursively.
  ///
  /// Supports arrays, paths, check rules, function calls, and primitive values.
  Object? parseExpression() {
    final Token? tok = peek();
    if (tok == null) {
      throw const FormatException('Expected expression');
    }

    final TokenKind kind = tok.kind;
    if (kind == TokenKind.lbracket) {
      return parseArray();
    }
    if (kind == TokenKind.path) {
      consume();
      return {'path': (tok.value as String).substring(1)};
    }
    if (kind == TokenKind.check) {
      return parseCheck();
    }
    if (kind == TokenKind.identifier) {
      consume();
      final Token? nextTok = peek();
      if (nextTok != null && nextTok.kind == TokenKind.lparen) {
        return parseCall(tok.value as String);
      }
      return {'variable': tok.value};
    }
    if (kind == TokenKind.string ||
        kind == TokenKind.number ||
        kind == TokenKind.boolean ||
        kind == TokenKind.nullValue) {
      consume();
      return tok.value;
    }
    throw FormatException('Unexpected token ${kind.name}: ${tok.text}');
  }

  /// Parses a comma-separated array literal enclosed in brackets `[...]`.
  List<Object?> parseArray() {
    consume(TokenKind.lbracket);
    final List<Object?> items = [];
    final Token? p = peek();
    if (p != null && p.kind != TokenKind.rbracket) {
      items.add(parseExpression());
      while (peek() != null && peek()!.kind == TokenKind.comma) {
        consume(TokenKind.comma);
        items.add(parseExpression());
      }
    }
    consume(TokenKind.rbracket);
    return items;
  }

  /// Parses a client-side check rule starting with `?` (e.g. `?required` or
  /// `?length(min, max)`).
  Map<String, Object?> parseCheck() {
    final Token tok = consume(TokenKind.check);
    final String name = (tok.value as String).substring(1); // strip ?
    final Token? nextTok = peek();
    final List<Object?> args = [];
    if (nextTok != null && nextTok.kind == TokenKind.lparen) {
      consume(TokenKind.lparen);
      final Token? p = peek();
      if (p != null && p.kind != TokenKind.rparen) {
        args.add(parseExpression());
        while (peek() != null && peek()!.kind == TokenKind.comma) {
          consume(TokenKind.comma);
          args.add(parseExpression());
        }
      }
      consume(TokenKind.rparen);
    }
    return {'check': name, 'args': args};
  }

  /// Parses a function call expression (e.g. `ComponentName(args)` or
  /// `FunctionName(args)`).
  Map<String, Object?> parseCall(String name) {
    consume(TokenKind.lparen);
    final List<Object?> args = [];
    final Token? p = peek();
    if (p != null && p.kind != TokenKind.rparen) {
      if (p.kind == TokenKind.lbrace) {
        args.add(parseMap());
      } else {
        args.add(parseExpression());
      }

      while (peek() != null && peek()!.kind == TokenKind.comma) {
        consume(TokenKind.comma);
        final Token? nextP = peek();
        if (nextP != null && nextP.kind == TokenKind.lbrace) {
          args.add(parseMap());
        } else {
          args.add(parseExpression());
        }
      }
    }
    consume(TokenKind.rparen);
    return {'call': name, 'args': args};
  }

  /// Parses a key-value map literal enclosed in braces `{key: value, ...}`.
  Map<String, Object?> parseMap() {
    consume(TokenKind.lbrace);
    final Map<String, Object?> res = {};
    final Token? p = peek();
    if (p != null && p.kind != TokenKind.rbrace) {
      final Token kTok = consume(TokenKind.identifier);
      consume(TokenKind.colon);
      final Object? v = parseExpression();
      res[kTok.value as String] = v;
      while (peek() != null && peek()!.kind == TokenKind.comma) {
        consume(TokenKind.comma);
        final Token nextKTok = consume(TokenKind.identifier);
        consume(TokenKind.colon);
        final Object? nextV = parseExpression();
        res[nextKTok.value as String] = nextV;
      }
    }
    consume(TokenKind.rbrace);
    return res;
  }
}
