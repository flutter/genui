// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:genui/genui.dart';

import '../compiler/catalog_schema_helper.dart';
import '../compiler/express_decompiler.dart';
import 'express_prompt_generator.dart';

/// Conforms to the [PromptBuilder] facade in GenUI to provide A2UI Express
/// system prompts.
class ExpressPromptBuilder implements PromptBuilder {
  /// The registered component/functions [catalog].
  final Catalog catalog;

  /// High-level conversational prompt fragments.
  final Iterable<String> systemPromptFragments;

  /// Optional client-side mock data model schema configuration.
  final Map<String, Object?>? clientDataModel;

  /// Allowed operations config if using custom builder.
  final SurfaceOperations? allowedOperations;

  /// Technical capabilities if using custom builder.
  final TechnicalPossibilities? technicalPossibilities;

  /// Prefix for important prompt fragments.
  final String importancePrefix;

  /// Creates an [ExpressPromptBuilder] configured for a typical chat session.
  ExpressPromptBuilder.chat({
    required this.catalog,
    this.systemPromptFragments = const [],
    this.clientDataModel,
    this.importancePrefix = PromptBuilder.defaultImportancePrefix,
  }) : allowedOperations = null,
       technicalPossibilities = null;

  /// Creates an [ExpressPromptBuilder] with full custom configuration control.
  ExpressPromptBuilder.custom({
    required this.catalog,
    required this.allowedOperations,
    this.systemPromptFragments = const [],
    this.importancePrefix = PromptBuilder.defaultImportancePrefix,
    this.technicalPossibilities = const TechnicalPossibilities(),
    this.clientDataModel,
  });

  @override
  Iterable<String> systemPrompt() {
    final promptGenerator = ExpressPromptGenerator(catalog);
    final String expressContract = promptGenerator.generatePrompt();

    final decompiler = ExpressDecompiler(catalog);
    final String customExample = _generateDynamicCatalogExample(
      decompiler.helper,
    );

    final strictGuidelines =
        '# A2UI DSL Output Guidelines\n\n'
        'IMPORTANT: You MUST output user interfaces using the '
        'A2UI DSL notation.\n'
        'You MUST surround the entire A2UI DSL block with the '
        'sentinel tags `<a2ui>` and `</a2ui>` '
        'to separate it from your conversational explanation.\n\n'
        'CRITICAL (Grammar Rules):\n'
        '- In your generated A2UI DSL code, you MUST ONLY pass '
        'positional arguments inside all component constructors (e.g. '
        'Component(arg1, arg2)). Do NOT use named arguments, property '
        'keys, or key-value assignments inside constructors!\n'
        '- Do NOT generate any HTML/XML-like tags (such as <h1>, <ul>, <li>, '
        '<p>, <div>, <span>) inside the `<a2ui>` block! Every element '
        'MUST be instantiated using standard positional component A2UI '
        'DSL signatures.\n'
        '- Do NOT mention technical jargon like "A2UI", "DSL", or '
        '"sentinel tags" in your conversation with the user.\n\n'
        'Example:\n'
        '$customExample';

    final Iterable<String> translatedCatalogFragments =
        _translateSystemPromptFragments(catalog.systemPromptFragments);

    final fragments = <String>[
      ...systemPromptFragments,
      ...translatedCatalogFragments,
      'Use A2UI Express syntax to generate rich UI elements.',
      expressContract,
      strictGuidelines,
      if (clientDataModel != null) _encodedDataModel(clientDataModel),
    ];

    return fragments.map((e) => e.trim());
  }

  String _generateDynamicCatalogExample(CatalogSchemaHelper schemaHelper) {
    // Find components from the catalog (ignoring layout Column/Row)
    final List<CatalogItem> components = catalog.items.where((item) {
      final String name = item.name;
      return name != 'Column' && name != 'Row';
    }).toList();

    if (components.isEmpty) {
      return '<a2ui>\n'
          'root = Text("No components registered")\n'
          '</a2ui>';
    }

    final lines = <String>[];
    final childrenNames = <String>[];

    // Select up to 2 components for clean, natural layout demonstration
    final int maxExamples = components.length > 2 ? 2 : components.length;
    for (var i = 0; i < maxExamples; i++) {
      final CatalogItem item = components[i];
      final String name = item.name;
      final List<String> props = schemaHelper.getComponentProperties(name);

      final args = <String>[];
      for (final p in props) {
        if (p == 'checks') {
          args.add('?required');
        } else {
          args.add('"example_${name.toLowerCase()}_val"');
        }
      }

      // Strip trailing optional nulls
      while (args.isNotEmpty && args.last == 'null') {
        args.removeLast();
      }

      final varName =
          '${name.substring(0, 1).toLowerCase()}${name.substring(1)}$i';
      childrenNames.add(varName);
      lines.add('$varName = $name(${args.join(', ')})');
    }

    return '<a2ui>\n'
        'root = Column([${childrenNames.join(', ')}])\n'
        '${lines.join('\n')}\n'
        '</a2ui>';
  }

  Iterable<String> _translateSystemPromptFragments(Iterable<String> fragments) {
    final decompiler = ExpressDecompiler(catalog);

    return fragments.map((fragment) {
      if (!fragment.contains('```json')) {
        return fragment;
      }

      // Normalize line endings to \n to prevent carriage return conflicts
      final String normalizedFragment = fragment.replaceAll('\r\n', '\n');

      // 1. Strip out legacy "Create a surface" list item
      // and its JSON code block.
      final createSurfaceRegex = RegExp(
        r'\d+\.\s*Create a surface:\s*```json[\s\S]*?```\s*\n?',
        caseSensitive: false,
      );
      final String cleanFragment = normalizedFragment.replaceAll(
        createSurfaceRegex,
        '',
      );

      // 2. Renumber "2. Update components:" to "1. Update components:"
      final String renumberedFragment = cleanFragment.replaceFirst(
        RegExp(r'\d+\.\s*Update components:'),
        '1. Update components:',
      );

      final int len = renumberedFragment.length > 40
          ? 40
          : renumberedFragment.length;
      final String start = renumberedFragment.substring(0, len);
      // ignore: avoid_print
      print(
        '[ExpressPromptBuilder] Translating fragment starting with: '
        '"$start..."',
      );

      // Regex to find all ```json ... ``` blocks in the markdown text
      final regex = RegExp(r'```json\s*([\s\S]*?)\s*```');

      return renumberedFragment.replaceAllMapped(regex, (match) {
        final String jsonText = match.group(1)?.trim() ?? '';

        // ignore: avoid_print
        print('[ExpressPromptBuilder] Found json block: "$jsonText"');

        if (jsonText.isEmpty) return match.group(0)!;

        try {
          final String cleanJson = ExpressDecompiler.stripComments(jsonText);
          final Object? parsed = jsonDecode(cleanJson);
          if (parsed is Map<String, dynamic>) {
            // Decompile the JSON envelope back into clean A2UI Express DSL
            // code!
            final String dslText = decompiler.decompile(parsed);

            // ignore: avoid_print
            print('[ExpressPromptBuilder] Decompiled to: "$dslText"');

            if (dslText.trim().isNotEmpty) {
              return '```a2ui\n$dslText\n```';
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('[ExpressPromptBuilder] Error decompiling JSON: $e');
        }
        return match.group(0)!;
      });
    });
  }

  @override
  String systemPromptJoined({
    String sectionSeparator = '\n-------------------------------------\n\n',
  }) => systemPrompt().map((e) => '${e.trim()}\n').join(sectionSeparator);

  static String _encodedDataModel(Map<String, Object?>? clientDataModel) {
    if (clientDataModel == null) return '';
    final String encodedModel = const JsonEncoder.withIndent(
      '  ',
    ).convert(clientDataModel);
    return 'Client Data Model:\n$encodedModel';
  }
}
