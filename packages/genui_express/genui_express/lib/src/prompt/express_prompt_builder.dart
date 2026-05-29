// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:genui/genui.dart';

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

    final Iterable<String> translatedCatalogFragments =
        _translateSystemPromptFragments(catalog.systemPromptFragments);

    final fragments = <String>[
      ...systemPromptFragments,
      ...translatedCatalogFragments,
      'Use A2UI Express syntax to generate rich UI elements.',
      expressContract,
      if (clientDataModel != null) _encodedDataModel(clientDataModel),
    ];

    return fragments.map((e) => e.trim());
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
