// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A high-performance compiler and parser library for A2UI Express scripts.
///
/// Exposes lexer tokenization, recursive-descent AST parsing, catalog schema
/// introspection helpers, and prompt contract generation facilities.
library;

import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:genui/genui.dart';

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

/// Helper class that inspects active in-memory catalog schemas to map
/// positional signatures.
class CatalogSchemaHelper {
  /// The wrapped component/functions [Catalog].
  final Catalog catalog;

  /// Maps component names to their properties keys list in schema order.
  final Map<String, List<String>> componentProperties = {};

  /// Maps component names to their required property keys list.
  final Map<String, List<String>> componentRequired = {};

  /// Maps component names to whether they support checks validation rules.
  final Map<String, bool> componentIsCheckable = {};

  /// Maps function names to their argument properties list.
  final Map<String, List<String>> functionProperties = {};

  /// Maps function names to their required argument keys list.
  final Map<String, List<String>> functionRequired = {};

  /// Creates a [CatalogSchemaHelper] and triggers schema parsing for [catalog].
  CatalogSchemaHelper(this.catalog) {
    _loadMappings();
  }

  /// Iterates through catalog items and functions to establish property key
  /// ordering maps.
  void _loadMappings() {
    for (final CatalogItem item in catalog.items) {
      final String name = item.name;
      final Map<String, Object?> schema = item.dataSchema.value;

      final props = <String, dynamic>{};
      final reqs = <String>[];
      var isCheckable = false;

      final subSchemas = <Map<String, dynamic>>[schema];
      if (schema.containsKey('allOf')) {
        final Object? allOf = schema['allOf'];
        if (allOf is List) {
          for (final sub in allOf as List<Object?>) {
            if (sub is Map<String, dynamic>) {
              subSchemas.add(sub);
            }
          }
        }
      }

      for (final sub in subSchemas) {
        if (sub.containsKey(r'$ref')) {
          final ref = sub[r'$ref'] as String;
          if (ref.contains('Checkable')) {
            isCheckable = true;
          }
        }
        if (sub.containsKey('properties')) {
          final Object? p = sub['properties'];
          if (p is Map<String, dynamic>) {
            props.addAll(p);
          }
        }
        if (sub.containsKey('required')) {
          final Object? r = sub['required'];
          if (r is List) {
            reqs.addAll(r.cast<String>());
          }
        }
      }

      final orderedKeys = <String>[];
      for (final String k in props.keys) {
        if (k != 'component' && k != 'id') {
          orderedKeys.add(k);
        }
      }

      if (isCheckable) {
        orderedKeys.add('checks');
      }

      componentProperties[name] = orderedKeys;
      componentRequired[name] = reqs;
      componentIsCheckable[name] = isCheckable;
    }

    for (final ClientFunction func in catalog.functions) {
      final String name = func.name;
      final Map<String, dynamic> schema =
          func.argumentSchema.value as Map<String, dynamic>? ?? const {};
      final Map<String, dynamic> props =
          schema['properties'] as Map<String, dynamic>? ?? const {};
      final List<Object?> reqs =
          schema['required'] as List<Object?>? ?? const [];

      final orderedKeys = <String>[];
      orderedKeys.addAll(props.keys);

      final requiredKeys = <String>[];
      requiredKeys.addAll(reqs.cast<String>());

      functionProperties[name] = orderedKeys;
      functionRequired[name] = requiredKeys;
    }
  }

  /// Returns the properties list in schema declaration order for [name].
  List<String> getComponentProperties(String name) =>
      componentProperties[name] ?? const [];

  /// Returns the required property keys list for component [name].
  List<String> getComponentRequired(String name) =>
      componentRequired[name] ?? const [];

  /// Returns whether component [name] supports check validation rules.
  bool isCheckable(String name) => componentIsCheckable[name] ?? false;

  /// Returns the argument properties list in schema order for function [name].
  List<String> getFunctionProperties(String name) =>
      functionProperties[name] ?? const [];

  /// Returns the required argument keys list for function [name].
  List<String> getFunctionRequired(String name) =>
      functionRequired[name] ?? const [];
}

/// A high-performance compiler that converts A2UI Express DSL scripts into
/// valid A2UI envelopes.
class ExpressCompiler {
  /// The catalog schema helper holding property mapping configurations.
  final CatalogSchemaHelper helper;

  /// Creates an [ExpressCompiler] instance mapping against [catalog].
  ExpressCompiler(Catalog catalog) : helper = CatalogSchemaHelper(catalog);

  /// Compiles A2UI Express script [dslText] into a flat JSON-compatible
  /// envelope structure.
  ///
  /// Returns a `Map<String, dynamic>` containing `createSurface` and the
  /// compiled flat components array.
  Map<String, dynamic> compile(
    String dslText, {
    String surfaceId = 'default_surface',
    String catalogId = '',
  }) {
    final List<String> lines = dslText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<String> statements = [];
    StringBuffer? currentStatement;
    final assignmentStartRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*\s*=');

    for (final line in lines) {
      if (line.contains('<a2ui>') || line.contains('</a2ui>')) {
        continue;
      }
      if (assignmentStartRegex.hasMatch(line)) {
        if (currentStatement != null) {
          statements.add(currentStatement.toString().trim());
        }
        currentStatement = StringBuffer(line);
      } else {
        if (currentStatement != null) {
          currentStatement.write('\n$line');
        }
      }
    }
    if (currentStatement != null) {
      statements.add(currentStatement.toString().trim());
    }

    final Map<String, dynamic> rawSymbols = {};

    for (final stmt in statements) {
      if (!stmt.contains('=')) {
        continue;
      }
      final int index = stmt.indexOf('=');
      final String varName = stmt.substring(0, index).trim();
      final String exprText = stmt.substring(index + 1).trim();

      try {
        final List<Token> tokens = tokenize(exprText);
        final parser = TokenParser(tokens);
        rawSymbols[varName] = parser.parseExpression();
      } catch (e) {
        // Recover gracefully: register dummy loading text for the failed
        // branch.
        rawSymbols[varName] = {
          'call': 'Text',
          'args': ['Loading...'],
        };
      }
    }

    final List<Map<String, dynamic>> compiledComponents = [];

    if (!rawSymbols.containsKey('root')) {
      if (rawSymbols.isNotEmpty) {
        final String lastKey = rawSymbols.keys.last;
        final Object? lastVal = rawSymbols.remove(lastKey);
        rawSymbols['root'] = lastVal;
      } else {
        throw ArgumentError(
          "A2UI Express source must define a 'root' variable or at least "
          'one component.',
        );
      }
    }

    for (final MapEntry<String, dynamic> entry in rawSymbols.entries) {
      final String varName = entry.key;
      final Object? ast = entry.value;
      final Map<String, dynamic>? compDict = _compileAstNode(
        varName,
        ast,
        rawSymbols,
        compiledComponents,
      );
      if (compDict != null) {
        compiledComponents.add(compDict);
      }
    }

    final String resolvedCatalogId = catalogId.isNotEmpty
        ? catalogId
        : (helper.catalog.catalogId ?? 'https://a2ui.org/catalog.json');

    return {
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': surfaceId,
        'catalogId': resolvedCatalogId,
        'components': compiledComponents,
      },
    };
  }

  /// Compiles an individual variable's AST node into flat component
  /// dictionary format.
  Map<String, dynamic>? _compileAstNode(
    String varName,
    Object? ast,
    Map<String, dynamic> rawSymbols,
    List<Map<String, dynamic>> compiledComponents,
  ) {
    if (ast is! Map<String, dynamic> || !ast.containsKey('call')) {
      return null;
    }

    final compName = ast['call'] as String;
    final args = ast['args'] as List<Object?>;

    if (!helper.componentProperties.containsKey(compName)) {
      // Not a component, could be a standalone action/helper; skip writing
      // as component.
      return null;
    }

    final List<String> properties = helper.getComponentProperties(compName);
    final Map<String, dynamic> compDict = {
      'id': varName,
      'component': compName,
    };

    Object? siblingValuePath;

    // First pass: map basic properties
    for (var idx = 0; idx < args.length; idx++) {
      if (idx >= properties.length) {
        break;
      }
      final String propName = properties[idx];
      if (propName == 'checks') {
        continue; // Compile checks in second pass
      }

      Object? mappedVal = _compileValue(
        args[idx],
        rawSymbols,
        compiledComponents,
        isAction: propName == 'action' || propName == 'submitAction',
      );

      // Resilient Auto-Wrapping of string literals in component slots
      if ((propName == 'child' ||
              propName == 'trigger' ||
              propName == 'content') &&
          mappedVal is String &&
          !mappedVal.startsWith('inline_') &&
          !mappedVal.startsWith('txt_') &&
          !rawSymbols.containsKey(mappedVal)) {
        final syntheticId = 'txt_${varName}_$idx';
        compiledComponents.add(<String, dynamic>{
          'id': syntheticId,
          'component': 'Text',
          'text': mappedVal,
        });
        mappedVal = syntheticId;
      }

      if (propName == 'children' && mappedVal is List) {
        final List<Object?> newChildren = [];
        for (var cIdx = 0; cIdx < mappedVal.length; cIdx++) {
          final Object? item = mappedVal[cIdx];
          if (item is String &&
              !item.startsWith('inline_') &&
              !item.startsWith('txt_') &&
              !rawSymbols.containsKey(item)) {
            final syntheticId = 'txt_${varName}_c$cIdx';
            compiledComponents.add(<String, dynamic>{
              'id': syntheticId,
              'component': 'Text',
              'text': item,
            });
            newChildren.add(syntheticId);
          } else {
            newChildren.add(item);
          }
        }
        mappedVal = newChildren;
      }

      if ((propName == 'action' || propName == 'submitAction') &&
          mappedVal is String &&
          !mappedVal.startsWith('inline_') &&
          !mappedVal.startsWith('txt_') &&
          !rawSymbols.containsKey(mappedVal)) {
        mappedVal = <String, dynamic>{
          'event': <String, dynamic>{
            'name': mappedVal,
            'context': const <String, dynamic>{},
          },
        };
      }

      compDict[propName] = mappedVal;

      if (propName == 'value' &&
          mappedVal is Map<String, dynamic> &&
          mappedVal.containsKey('path')) {
        siblingValuePath = mappedVal;
      }
    }

    // Second pass: compile checks with implicit path injection
    for (var idx = 0; idx < args.length; idx++) {
      if (idx >= properties.length) {
        break;
      }
      final String propName = properties[idx];
      if (propName == 'checks') {
        final List<Map<String, dynamic>> compiledChecks = [];
        final List<Object?> rawChecks = args[idx] is List
            ? args[idx] as List
            : [args[idx]];

        for (final rc in rawChecks) {
          if (rc is Map<String, dynamic> && rc.containsKey('check')) {
            final checkName = rc['check'] as String;
            final checkArgs = rc['args'] as List<Object?>;
            final Map<String, dynamic> compiledArgs = {};

            final List<String> checkProps = helper.getFunctionProperties(
              checkName,
            );
            var messageVal =
                '${checkName[0].toUpperCase()}${checkName.substring(1)} '
                'check failed';

            final explicitArgs = List<Object?>.from(checkArgs);
            var isValueInjected = false;

            // Handle implicit target 'value' injection
            if (checkProps.isNotEmpty && checkProps[0] == 'value') {
              if (explicitArgs.isNotEmpty &&
                  explicitArgs[0] is Map<String, dynamic> &&
                  (explicitArgs[0] as Map<String, dynamic>).containsKey(
                    'path',
                  )) {
                // already has a path, do nothing
              } else {
                if (siblingValuePath != null) {
                  compiledArgs['value'] = siblingValuePath;
                  isValueInjected = true;
                }
              }
            }

            final startPropIdx = isValueInjected ? 1 : 0;

            for (var cIdx = 0; cIdx < explicitArgs.length; cIdx++) {
              final int propTargetIdx = cIdx + startPropIdx;
              if (propTargetIdx < checkProps.length) {
                compiledArgs[checkProps[propTargetIdx]] = _compileValue(
                  explicitArgs[cIdx],
                  rawSymbols,
                  compiledComponents,
                );
              } else {
                if (explicitArgs[cIdx] is String) {
                  messageVal = explicitArgs[cIdx] as String;
                }
              }
            }

            compiledChecks.add({
              'condition': {'call': checkName, 'args': compiledArgs},
              'message': messageVal,
            });
          }
        }
        compDict['checks'] = compiledChecks;
      }
    }

    return compDict;
  }

  /// Compiles an individual AST node value into valid A2UI equivalents.
  Object? _compileValue(
    Object? val,
    Map<String, dynamic> rawSymbols,
    List<Map<String, dynamic>> compiledComponents, {
    bool isAction = false,
  }) {
    if (val is Map<String, dynamic>) {
      if (val.containsKey('path')) {
        return val;
      }
      if (val.containsKey('variable')) {
        // Resolve variable ID
        return val['variable'];
      }
      if (val.containsKey('call')) {
        final fnName = val['call'] as String;
        final fnArgs = val['args'] as List<Object?>;

        // If it is a component call, auto-flatten it!
        if (helper.componentProperties.containsKey(fnName)) {
          final syntheticId = 'inline_${fnName}_${compiledComponents.length}';
          final Map<String, dynamic>? inlineComp = _compileAstNode(
            syntheticId,
            val,
            rawSymbols,
            compiledComponents,
          );
          if (inlineComp != null) {
            compiledComponents.add(inlineComp);
          }
          return syntheticId;
        }

        // Is it a reserved Template signature?
        if (fnName == 'Template') {
          final pathVal =
              _compileValue(
                    fnArgs[0],
                    rawSymbols,
                    compiledComponents,
                    isAction: isAction,
                  )
                  as Map<String, dynamic>;
          final Object? compIdVal = _compileValue(
            fnArgs[1],
            rawSymbols,
            compiledComponents,
            isAction: isAction,
          );
          return {'path': pathVal['path'], 'componentId': compIdVal};
        }

        // Is it a reserved Event signature?
        if (fnName == 'Event') {
          final eventName = fnArgs.isNotEmpty ? fnArgs[0] as String : '';
          final contextMap = fnArgs.length > 1
              ? fnArgs[1] as Map<String, dynamic>
              : const <String, dynamic>{};
          final Map<String, dynamic> compiledContext = {};
          for (final MapEntry<String, dynamic> entry in contextMap.entries) {
            compiledContext[entry.key] = _compileValue(
              entry.value,
              rawSymbols,
              compiledComponents,
              isAction: isAction,
            );
          }
          return {
            'event': {'name': eventName, 'context': compiledContext},
          };
        }

        // Is it a regular catalog function?
        if (helper.functionProperties.containsKey(fnName)) {
          final List<String> fnProps = helper.getFunctionProperties(fnName);
          final Map<String, dynamic> compiledArgs = {};
          for (var idx = 0; idx < fnArgs.length; idx++) {
            if (idx < fnProps.length) {
              compiledArgs[fnProps[idx]] = _compileValue(
                fnArgs[idx],
                rawSymbols,
                compiledComponents,
                isAction: isAction,
              );
            }
          }

          // Wrap in functionCall only if inside an action field
          if (isAction) {
            return {
              'functionCall': {'call': fnName, 'args': compiledArgs},
            };
          }

          // Compile direct dynamic function call expression (with returnType!)
          final Map<String, dynamic> resExpr = {
            'call': fnName,
            'args': compiledArgs,
          };
          // Read returnType from catalog definition if present
          final ClientFunction? fnDef = helper.catalog.functions
              .firstWhereOrNull((f) => f.name == fnName);
          final String? returnTypeConst = fnDef?.returnType.value;
          if (returnTypeConst != null) {
            resExpr['returnType'] = returnTypeConst;
          }
          return resExpr;
        }

        // Fallback
        return {
          'call': fnName,
          'args': fnArgs
              .map(
                (a) => _compileValue(
                  a,
                  rawSymbols,
                  compiledComponents,
                  isAction: isAction,
                ),
              )
              .toList(),
        };
      }

      return val.map(
        (k, v) => MapEntry(
          k,
          _compileValue(v, rawSymbols, compiledComponents, isAction: isAction),
        ),
      );
    }

    if (val is List) {
      return val
          .map(
            (item) => _compileValue(
              item,
              rawSymbols,
              compiledComponents,
              isAction: isAction,
            ),
          )
          .toList();
    }

    return val;
  }
}

/// Generates A2UI Express contract signatures based on the introspection
/// helper.
class ExpressPromptGenerator {
  /// The active catalog helper.
  final CatalogSchemaHelper helper;

  /// Creates an [ExpressPromptGenerator] wrapping [catalog].
  ExpressPromptGenerator(Catalog catalog)
    : helper = CatalogSchemaHelper(catalog);

  /// Generates compact positional signatures for all components in the
  /// catalog.
  String generateComponentSignatures() {
    final List<String> signatures = [];
    final List<String> sortedNames = helper.componentProperties.keys.toList()
      ..sort();
    for (final name in sortedNames) {
      final List<String> props = helper.getComponentProperties(name);
      final List<String> reqs = helper.getComponentRequired(name);
      final List<String> orderedArgs = [];
      for (final p in props) {
        final bool isReq = reqs.contains(p);
        final optSuffix = isReq ? '' : '?';
        orderedArgs.add('$p$optSuffix');
      }
      final sig = "• $name(${orderedArgs.join(', ')})";
      signatures.add(sig);
    }
    return signatures.join('\n');
  }

  /// Generates compact signatures for all client logic functions in the
  /// catalog.
  String generateFunctionSignatures() {
    final List<String> signatures = [];
    final List<String> sortedNames = helper.functionProperties.keys.toList()
      ..sort();
    for (final name in sortedNames) {
      final List<String> props = helper.getFunctionProperties(name);
      final List<String> reqs = helper.getFunctionRequired(name);
      final List<String> orderedArgs = [];
      for (final p in props) {
        final bool isReq = reqs.contains(p);
        final optSuffix = isReq ? '' : '?';
        orderedArgs.add('$p$optSuffix');
      }
      final sig = "• $name(${orderedArgs.join(', ')})";
      signatures.add(sig);
    }
    return signatures.join('\n');
  }

  /// Returns the complete system prompt contract text to guide the LLM.
  String generatePrompt() {
    final String compSigs = generateComponentSignatures();
    final String funcSigs = generateFunctionSignatures();

    return '''
# A2UI Express Output Contract

You must output the user interface using the compact A2UI Express DSL notation.
You MUST surround the entire A2UI Express DSL block with the sentinel tags `<a2ui>` and `</a2ui>`.

## Grammar Rules

1. Output exactly one variable assignment statement per line:
   variable_name = ComponentName(arg1, arg2, ...)

2. The interface tree must have a single entry point assigned to the
   reserved variable 'root'.

3. Primitives:
   - Strings: enclose in double quotes, e.g., "label"
   - Numbers: write as integers or decimals, e.g., 42
   - Booleans: write true or false
   - Null values: write null

4. Lists: represent as arrays, e.g., [child1, child2]

5. Data bindings: prefix absolute paths in the data model with '\$',
   e.g., \$/user/firstName. Prefix relative list scopes with '\$',
   e.g., \$firstName.

6. Logic and validation: prefix client check rules with '?', e.g., ?required or
   ?regex("^[0-9]{5}\$").

7. Action events: represent server-side actions using the Event helper:
   Event("save_deal", {rep: \$/form/rep})

8. Nested functions: call client functions directly using catalog signatures,
   for example openUrl("https://example.com").

## Positional Component Signatures

Use these exact positional signatures to instantiate components. Do not
output property keys:
$compSigs

## Positional Function Signatures

Use these exact positional signatures to instantiate check rules or logic
functions:
$funcSigs

## Examples

<a2ui>
root = Column([repField, valueField])
repField = TextField("Representative", \$/form/rep, "Enter name")
valueField = TextField(
  "Deal Value", \$/form/value, "0.00", "number", [?required]
)
</a2ui>
''';
  }
}

/// Conforms to the [PromptBuilder] facade in GenUI to provide A2UI Express
/// system prompts.
class ExpressPromptBuilder implements PromptBuilder {
  /// The registered component/functions [catalog].
  final Catalog catalog;

  /// High-level conversational prompt fragments.
  final Iterable<String> systemPromptFragments;

  /// Optional client-side mock data model schema configuration.
  final Map<String, dynamic>? clientDataModel;

  /// Creates an [ExpressPromptBuilder] with its catalog and prompts fragments.
  ExpressPromptBuilder({
    required this.catalog,
    this.systemPromptFragments = const [],
    this.clientDataModel,
  });

  @override
  Iterable<String> systemPrompt() {
    final promptGenerator = ExpressPromptGenerator(catalog);
    final String expressContract = promptGenerator.generatePrompt();

    final fragments = <String>[
      ...systemPromptFragments,
      ...catalog.systemPromptFragments,
      'Use A2UI Express syntax to generate rich UI elements.',
      expressContract,
      if (clientDataModel != null) _encodedDataModel(clientDataModel),
    ];

    return fragments.map((e) => e.trim());
  }

  @override
  String systemPromptJoined({
    String sectionSeparator = '\n-------------------------------------\n\n',
  }) => systemPrompt().map((e) => '${e.trim()}\n').join(sectionSeparator);

  static String _encodedDataModel(Map<String, dynamic>? clientDataModel) {
    if (clientDataModel == null) return '';
    final String encodedModel = const JsonEncoder.withIndent(
      '  ',
    ).convert(clientDataModel);
    return 'Client Data Model:\n$encodedModel';
  }
}
