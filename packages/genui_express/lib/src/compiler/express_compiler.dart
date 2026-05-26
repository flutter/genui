// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:genui/genui.dart';

import 'catalog_schema_helper.dart';
import 'parser.dart';
import 'token.dart';

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
  /// Returns a `Map<String, Object?>` containing `createSurface` and the
  /// compiled flat components array.
  Map<String, Object?> compile(
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
    final assignmentStartRegex = RegExp(
      r'^(?:[a-zA-Z_][a-zA-Z0-9_-]*|\$[a-zA-Z0-9_/]+)\s*=',
    );

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

    final Map<String, Object?> rawSymbols = {};
    final Map<String, Object?> pathAssignments = {};

    for (final stmt in statements) {
      if (!stmt.contains('=')) {
        continue;
      }
      final int index = stmt.indexOf('=');
      final String leftHandSide = stmt.substring(0, index).trim();
      final String exprText = stmt.substring(index + 1).trim();

      try {
        final List<Token> tokens = tokenize(exprText);
        final parser = TokenParser(tokens);
        final Object? parsedExpr = parser.parseExpression();

        if (leftHandSide.startsWith(r'$/')) {
          pathAssignments[leftHandSide] = parsedExpr;
        } else {
          rawSymbols[leftHandSide] = parsedExpr;
        }
      } catch (e) {
        // Recover gracefully: register dummy loading text for the failed
        // branch.
        rawSymbols[leftHandSide] = {
          'call': 'Text',
          'args': ['Loading...'],
        };
      }
    }

    final List<Map<String, Object?>> compiledComponents = [];

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

    for (final MapEntry<String, Object?> entry in rawSymbols.entries) {
      final String varName = entry.key;
      final Object? ast = entry.value;
      final Map<String, Object?>? compDict = _compileAstNode(
        varName,
        ast,
        rawSymbols,
        compiledComponents,
      );
      if (compDict != null) {
        compiledComponents.add(compDict);
      }
    }

    final Map<String, Object?> dataModelAccumulator = {};
    for (final MapEntry<String, Object?> entry in pathAssignments.entries) {
      final String pathKey = entry.key.substring(2); // strip $/
      final Object? evaluated = _compileValue(
        entry.value,
        rawSymbols,
        compiledComponents,
      );
      _setValueAtPath(dataModelAccumulator, pathKey, evaluated);
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
        'dataModel': dataModelAccumulator,
      },
    };
  }

  /// Compiles an individual variable's AST node into flat component
  /// dictionary format.
  Map<String, Object?>? _compileAstNode(
    String varName,
    Object? ast,
    Map<String, Object?> rawSymbols,
    List<Map<String, Object?>> compiledComponents,
  ) {
    if (ast is! Map<String, Object?> || !ast.containsKey('call')) {
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
    final Map<String, Object?> compDict = {
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
        compiledComponents.add(<String, Object?>{
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
            compiledComponents.add(<String, Object?>{
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
        mappedVal = <String, Object?>{
          'event': <String, Object?>{
            'name': mappedVal,
            'context': const <String, Object?>{},
          },
        };
      }

      compDict[propName] = mappedVal;

      if (propName == 'value' &&
          mappedVal is Map<String, Object?> &&
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
        final List<Map<String, Object?>> compiledChecks = [];
        final List<Object?> rawChecks = args[idx] is List<Object?>
            ? args[idx] as List<Object?>
            : [args[idx]];

        for (final rc in rawChecks) {
          if (rc is Map<String, Object?> && rc.containsKey('check')) {
            final checkName = rc['check'] as String;
            final checkArgs = rc['args'] as List<Object?>;
            final Map<String, Object?> compiledArgs = {};

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
                  explicitArgs[0] is Map<String, Object?> &&
                  (explicitArgs[0] as Map<String, Object?>).containsKey(
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
    Map<String, Object?> rawSymbols,
    List<Map<String, Object?>> compiledComponents, {
    bool isAction = false,
  }) {
    if (val is Map<String, Object?>) {
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
          final Map<String, Object?>? inlineComp = _compileAstNode(
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
                  as Map<String, Object?>;
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
              ? fnArgs[1] as Map<String, Object?>
              : const <String, Object?>{};
          final Map<String, Object?> compiledContext = {};
          for (final MapEntry<String, Object?> entry in contextMap.entries) {
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
          final Map<String, Object?> compiledArgs = {};
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
          final Map<String, Object?> resExpr = {
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

  /// Helper method to structuredly set values at a nested JSON [path].
  void _setValueAtPath(Map<String, Object?> map, String path, Object? value) {
    final List<String> keys = path
        .split('/')
        .where((k) => k.isNotEmpty)
        .toList();
    if (keys.isEmpty) return;

    var current = map;
    for (var i = 0; i < keys.length - 1; i++) {
      final String key = keys[i];
      if (!current.containsKey(key) || current[key] is! Map<String, Object?>) {
        current[key] = <String, Object?>{};
      }
      current = current[key] as Map<String, Object?>;
    }
    current[keys.last] = value;
  }
}
