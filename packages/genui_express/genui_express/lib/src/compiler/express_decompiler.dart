// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:genui/genui.dart';

import 'catalog_schema_helper.dart';

/// Decompiles standard A2UI wire JSON back into clean A2UI Express DSL lines.
class ExpressDecompiler {
  /// The helper class that inspects active catalog schemas.
  final CatalogSchemaHelper helper;

  /// Creates an [ExpressDecompiler] instance configured with the given
  /// [catalog].
  ExpressDecompiler(Catalog catalog) : helper = CatalogSchemaHelper(catalog);

  /// Decodes a JSON string, robustly stripping any single-line double-slash (//)
  /// comments first, and decompiles it into A2UI Express DSL.
  String decompileString(String jsonText) {
    final String cleanJson = stripComments(jsonText);
    final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
    return decompile(parsed);
  }

  /// Strips standard single-line double-slash (//) comments from a JSON string
  /// while safely leaving URLs (https://, http://) untouched.
  static String stripComments(String jsonText) {
    // Regex to find all // ... comments starting on a new line inside the JSON
    final commentRegex = RegExp(r'^\s*//.*$', multiLine: true);
    String clean = jsonText.replaceAll(commentRegex, '');

    // Also handle trailing inline comments
    final inlineCommentRegex = RegExp(r'\s*//.*$');
    clean = clean.replaceAllMapped(inlineCommentRegex, (match) {
      final String textBefore = match.input.substring(0, match.start);
      final int doubleQuoteCount = '"'.allMatches(textBefore).length;
      if (doubleQuoteCount % 2 != 0) {
        // Inside a string literal (like a URL), leave it alone!
        return match.group(0)!;
      }
      return '';
    });
    return clean.trim();
  }

  /// Decompiles standard A2UI wire JSON into clean A2UI Express lines.
  String decompile(Map<String, dynamic> envelopeJson) {
    Map<String, dynamic> dataModel = const {};
    List<dynamic> components = const [];

    if (envelopeJson.containsKey('createSurface')) {
      final Map<String, dynamic> createSurface =
          envelopeJson['createSurface'] as Map<String, dynamic>? ?? const {};
      components = createSurface['components'] as List<dynamic>? ?? const [];
      dataModel =
          createSurface['dataModel'] as Map<String, dynamic>? ?? const {};
    } else if (envelopeJson.containsKey('updateComponents')) {
      final Map<String, dynamic> updateComponents =
          envelopeJson['updateComponents'] as Map<String, dynamic>? ?? const {};
      components = updateComponents['components'] as List<dynamic>? ?? const [];
    } else if (envelopeJson.containsKey('updateDataModel')) {
      final Map<String, dynamic> updateDataModel =
          envelopeJson['updateDataModel'] as Map<String, dynamic>? ?? const {};
      final String path = updateDataModel['path'] as String? ?? '/';
      final Object? value = updateDataModel['value'];
      if (path == '/' && value is Map<String, dynamic>) {
        dataModel = value;
      } else if (path.startsWith('/')) {
        dataModel = {path.substring(1): value};
      } else {
        dataModel = {path: value};
      }
    } else {
      components = envelopeJson['components'] as List<dynamic>? ?? const [];
      dataModel =
          envelopeJson['dataModel'] as Map<String, dynamic>? ?? const {};
    }

    final List<String> dslLines = [];
    final Set<String> compIds = components
        .map((c) => (c as Map<String, dynamic>)['id'] as String)
        .toSet();

    // Decompile dataModel paths first
    if (dataModel.isNotEmpty) {
      final List<(String, dynamic)> flattened = _flattenDataModel(dataModel);
      // Sort by path key
      flattened.sort((a, b) => a.$1.compareTo(b.$1));
      for (final item in flattened) {
        final String valStr = _decompileValue(item.$2, compIds);
        dslLines.add('\$${item.$1} = $valStr');
      }
    }

    for (final dynamic compVal in components) {
      final c = compVal as Map<String, dynamic>;
      final compId = c['id'] as String;
      final compName = c['component'] as String;

      final List<String> properties = helper.getComponentProperties(compName);
      final List<String> argsReprs = [];

      for (final propName in properties) {
        if (propName == 'checks') {
          final List<dynamic> checksVal =
              c['checks'] as List<dynamic>? ?? const [];
          if (checksVal.isEmpty) {
            argsReprs.add('null');
            continue;
          }

          final List<String> compiledChecksList = [];
          for (final dynamic rcVal in checksVal) {
            final rc = rcVal as Map<String, dynamic>;
            final Map<String, dynamic> condition =
                rc['condition'] as Map<String, dynamic>? ?? const {};
            final String message = rc['message'] as String? ?? '';

            final checkName = condition['call'] as String;
            final Map<String, dynamic> checkArgs =
                condition['args'] as Map<String, dynamic>? ?? const {};

            final List<String> checkProps = helper.getFunctionProperties(
              checkName,
            );
            final List<String> explicitArgsReprs = [];

            // If first property is value (implicitly bound), skip it
            var startIdx = 0;
            if (checkProps.isNotEmpty && checkProps[0] == 'value') {
              startIdx = 1;
            }

            for (var idx = startIdx; idx < checkProps.length; idx++) {
              final String p = checkProps[idx];
              if (checkArgs.containsKey(p)) {
                explicitArgsReprs.add(_decompileValue(checkArgs[p], compIds));
              }
            }

            if (message.isNotEmpty &&
                message !=
                    '${checkName[0].toUpperCase()}'
                        '${checkName.substring(1)} check failed') {
              final String escapedMsg = message.replaceAll('"', '\\"');
              explicitArgsReprs.add('"$escapedMsg"');
            }

            if (explicitArgsReprs.isNotEmpty) {
              compiledChecksList.add(
                '?$checkName(${explicitArgsReprs.join(', ')})',
              );
            } else {
              compiledChecksList.add('?$checkName');
            }
          }

          if (compiledChecksList.length == 1) {
            argsReprs.add(compiledChecksList[0]);
          } else {
            argsReprs.add('[${compiledChecksList.join(', ')}]');
          }
          continue;
        }

        // Map other regular properties
        if (c.containsKey(propName)) {
          final Object? val = c[propName];
          argsReprs.add(_decompileValue(val, compIds));
        } else {
          argsReprs.add('null');
        }
      }

      // Strip trailing optional null arguments for readability
      while (argsReprs.isNotEmpty && argsReprs.last == 'null') {
        argsReprs.removeLast();
      }

      dslLines.add('$compId = $compName(${argsReprs.join(', ')})');
    }

    return dslLines.join('\n');
  }

  List<(String, dynamic)> _flattenDataModel(Map<String, dynamic> dataDict) {
    final List<(String, dynamic)> results = [];
    void recurse(Object? current, String path) {
      if (current is Map && current.isNotEmpty) {
        for (final MapEntry<dynamic, dynamic> entry in current.entries) {
          recurse(entry.value, '$path/${entry.key}');
        }
      } else {
        results.add((path, current));
      }
    }

    recurse(dataDict, '');
    return results;
  }

  String _decompileValue(Object? val, Set<String> compIds) {
    if (val is Map) {
      final Map<String, dynamic> map = val.cast<String, dynamic>();
      if (map.containsKey('path')) {
        if (map.containsKey('componentId')) {
          final String pathRepr = _decompileValue({
            'path': map['path'],
          }, compIds);
          final compIdRepr = map['componentId'] as String;
          return 'Template($pathRepr, $compIdRepr)';
        }
        final pathStr = map['path'] as String;
        if (pathStr.startsWith('/')) {
          return '\$/${pathStr.substring(1)}';
        }
        return '\$$pathStr';
      }

      if (map.containsKey('event')) {
        final evt = map['event'] as Map<String, dynamic>;
        final String name = evt['name'] as String? ?? '';
        final Map<String, dynamic> ctx =
            evt['context'] as Map<String, dynamic>? ?? const {};
        final List<String> ctxReprs = [];
        for (final MapEntry<String, dynamic> entry in ctx.entries) {
          ctxReprs.add(
            '${entry.key}: ${_decompileValue(entry.value, compIds)}',
          );
        }
        if (ctxReprs.isNotEmpty) {
          return 'Event("$name", {${ctxReprs.join(', ')}})';
        }
        return 'Event("$name")';
      }

      if (map.containsKey('functionCall')) {
        final fn = map['functionCall'] as Map<String, dynamic>;
        final name = fn['call'] as String;
        final Map<String, dynamic> args =
            fn['args'] as Map<String, dynamic>? ?? const {};

        final List<String> fnProps = helper.getFunctionProperties(name);
        final List<String> argsReprs = [];
        for (final p in fnProps) {
          if (args.containsKey(p)) {
            argsReprs.add(_decompileValue(args[p], compIds));
          } else {
            argsReprs.add('null');
          }
        }

        while (argsReprs.isNotEmpty && argsReprs.last == 'null') {
          argsReprs.removeLast();
        }
        return '$name(${argsReprs.join(', ')})';
      }

      if (map.containsKey('call')) {
        final name = map['call'] as String;
        final Map<String, dynamic> args =
            map['args'] as Map<String, dynamic>? ?? const {};
        final List<String> fnProps = helper.getFunctionProperties(name);
        final List<String> argsReprs = [];
        for (final p in fnProps) {
          if (args.containsKey(p)) {
            argsReprs.add(_decompileValue(args[p], compIds));
          } else {
            argsReprs.add('null');
          }
        }

        while (argsReprs.isNotEmpty && argsReprs.last == 'null') {
          argsReprs.removeLast();
        }
        return '$name(${argsReprs.join(', ')})';
      }

      // General Map
      final List<String> itemsReprs = [];
      for (final MapEntry<String, dynamic> entry in map.entries) {
        itemsReprs.add(
          '${entry.key}: ${_decompileValue(entry.value, compIds)}',
        );
      }
      return '{${itemsReprs.join(', ')}}';
    }

    if (val is List) {
      final List<String> listReprs = val
          .map((item) => _decompileValue(item, compIds))
          .toList();
      return '[${listReprs.join(', ')}]';
    }

    if (val is String) {
      if (compIds.contains(val)) {
        return val;
      }
      final String escaped = val.replaceAll('"', '\\"');
      return '"$escaped"';
    }

    if (val is bool) {
      return val ? 'true' : 'false';
    }

    if (val == null) {
      return 'null';
    }

    return val.toString();
  }
}
