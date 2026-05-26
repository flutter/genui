// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:genui/genui.dart';

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

  static String _encodedDataModel(Map<String, Object?>? clientDataModel) {
    if (clientDataModel == null) return '';
    final String encodedModel = const JsonEncoder.withIndent(
      '  ',
    ).convert(clientDataModel);
    return 'Client Data Model:\n$encodedModel';
  }
}
