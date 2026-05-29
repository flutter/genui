// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import '../compiler/catalog_schema_helper.dart';

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
    const coreComponents = {
      'Button',
      'Card',
      'CheckBox',
      'ChoicePicker',
      'Column',
      'DateTimeInput',
      'Divider',
      'Icon',
      'List',
      'Modal',
      'Row',
      'Slider',
      'Tabs',
      'Text',
      'TextField',
    };

    final List<String> signatures = [];
    final List<String> sortedNames = helper.componentProperties.keys.toList()
      ..sort();
    for (final name in sortedNames) {
      final List<String> props = helper.getComponentProperties(name);
      final List<String> reqs = helper.getComponentRequired(name);
      final List<String> orderedArgs = [];
      final List<String> paramDescs = [];

      final bool isCore = coreComponents.contains(name);
      final String compDesc = isCore
          ? ''
          : helper.getComponentDescription(name);
      final Map<String, String> propDescs = isCore
          ? const {}
          : helper.getPropertyDescriptions(name);

      for (final p in props) {
        final bool isReq = reqs.contains(p);
        final optSuffix = isReq ? '' : '?';
        orderedArgs.add('$p$optSuffix');

        final String? pDesc = propDescs[p];
        if (pDesc != null && pDesc.isNotEmpty) {
          paramDescs.add('$p: $pDesc');
        }
      }

      var sig = '• $name(${orderedArgs.join(', ')})';
      if (compDesc.isNotEmpty) {
        sig += ' - $compDesc';
      }
      if (paramDescs.isNotEmpty) {
        sig += ' (${paramDescs.join('; ')})';
      }
      signatures.add(sig);
    }
    return signatures.join('\n');
  }

  /// Generates compact signatures for all client logic functions in the
  /// catalog.
  String generateFunctionSignatures() {
    const coreFunctions = {
      'and',
      'email',
      'formatCurrency',
      'formatDate',
      'formatNumber',
      'formatString',
      'length',
      'not',
      'numeric',
      'openUrl',
      'or',
      'pluralize',
      'regex',
      'required',
    };

    final List<String> signatures = [];
    final List<String> sortedNames = helper.functionProperties.keys.toList()
      ..sort();
    for (final name in sortedNames) {
      final List<String> props = helper.getFunctionProperties(name);
      final List<String> reqs = helper.getFunctionRequired(name);
      final List<String> orderedArgs = [];
      final List<String> paramDescs = [];

      final bool isCore = coreFunctions.contains(name);
      final String funcDesc = isCore ? '' : helper.getFunctionDescription(name);
      final Map<String, String> argDescs = isCore
          ? const {}
          : helper.getFunctionArgumentDescriptions(name);

      for (final p in props) {
        final bool isReq = reqs.contains(p);
        final optSuffix = isReq ? '' : '?';
        orderedArgs.add('$p$optSuffix');

        final String? aDesc = argDescs[p];
        if (aDesc != null && aDesc.isNotEmpty) {
          paramDescs.add('$p: $aDesc');
        }
      }

      var sig = '• $name(${orderedArgs.join(', ')})';
      if (funcDesc.isNotEmpty) {
        sig += ' - $funcDesc';
      }
      if (paramDescs.isNotEmpty) {
        sig += ' (${paramDescs.join('; ')})';
      }
      signatures.add(sig);
    }
    return signatures.join('\n');
  }

  /// Returns the complete system prompt contract text to guide the LLM.
  String generatePrompt() {
    final String compSigs = generateComponentSignatures();
    final String funcSigs = generateFunctionSignatures();

    return '''
# A2UI DSL Output Contract

You must output the user interface using the compact A2UI DSL notation.
You MUST surround the entire A2UI DSL block with the sentinel tags
`<a2ui>` and `</a2ui>`.

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

9. Data model population: Assign a value directly to an absolute data path
   (e.g. \$/path/to/key = "value") to populate or initialize values inside
   the shared dataModel. The value can be a primitive, array, or map.

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
valueField = TextField("Deal Value", \$/form/value, "0.00", "number", [?required])
\$/form/rep = "John Doe"
\$/form/value = 1500.00
</a2ui>
''';
  }
}
