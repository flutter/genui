// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/a2ui_message.dart';
import '../model/catalog.dart';

/// Common fragments for prompts.
abstract class PromptFragments {
  static String acknowledgeUser({String prefix = ''}) =>
      ''' 
${prefix}Your responses should contain acknowledgment of the user message.
'''
          .trim();
  static String requireAtLeastOneSubmitElement({String prefix = ''}) =>
      '''
${prefix}When you are asking for information from the user, you should always include
at least one submit button of some kind or another submitting element so that
the user can indicate that they are done providing information.
'''
          .trim();
}

// ignore: unused_element
abstract class _SurfaceSystemPrompt {
  // ignore: unused_field
  static String uniqueSurfaceId({String prefix = ''}) =>
      '''
${prefix}When you generate UI in a response, you MUST always create
a new surface with a unique `surfaceId`. Do NOT reuse or update
previously used `surfaceId`s. Each UI response must be in its own new surface.
'''
          .trim();
}

/// A builder for a prompt to generate UI.
abstract class PromptBuilder {
  static const String defaultImportancePrefix = 'IMPORTANT: ';
  const PromptBuilder();

  /// Creates a chat prompt builder.
  ///
  /// The builder will generate a prompt for a chat session,
  /// that instructs to create new surfaces for each response
  /// and restrict surface deletion and updates.
  factory PromptBuilder.chat({
    required Catalog catalog,
    Iterable<String> systemPromptFragments = const [],
    String importancePrefix = defaultImportancePrefix,
  }) {
    return BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowedOperations: const SurfaceOperations.createOnly(),
      importancePrefix: importancePrefix,
    );
  }

  factory PromptBuilder.custom({
    required Catalog catalog,
    required Iterable<String> systemPromptFragments,
    required SurfaceOperations allowedOperations,
    String importancePrefix = defaultImportancePrefix,
  }) {
    return BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowedOperations: allowedOperations,
      importancePrefix: importancePrefix,
    );
  }

  Iterable<String> get systemPrompt;

  String systemPromptJoined({String sectionSeparator = '\n\n----\n\n'}) =>
      systemPrompt.map((e) => e.trim()).join(sectionSeparator);
}

/// Defines the set of allowed surface operations.
final class SurfaceOperations {
  const SurfaceOperations.createOnly() : create = true, update = false;
  const SurfaceOperations.updateOnly() : create = false, update = true;
  const SurfaceOperations.createAndUpdate() : create = true, update = true;

  final bool create;
  final bool update;
}

final class BasicPromptBuilder extends PromptBuilder {
  const BasicPromptBuilder({
    required this.catalog,
    required this.systemPromptFragments,
    required this.allowedOperations,
    required this.importancePrefix,
  });

  final Catalog catalog;

  final SurfaceOperations allowedOperations;

  /// Prefix for important sections of the prompt.
  ///
  /// Sections, generated from the catalog that are marked as important
  /// will be prefixed with this string.
  final String importancePrefix;

  /// Additional system prompt fragments.
  ///
  /// These fragments are added on top of what is provided by the catalog.
  final Iterable<String> systemPromptFragments;

  Iterable<String> _fragmentsToPrompt(Iterable<String> fragments) =>
      fragments.map((e) => e.trim());

  @override
  Iterable<String> get systemPrompt {
    final String a2uiSchema = A2uiMessage.a2uiMessageSchema(
      catalog,
    ).toJson(indent: '  ');

    final fragments = <String>[
      ...systemPromptFragments,
      'Use the provided tools to respond to user using rich UI elements.',
      ...catalog.systemPromptFragments,
      '''
  <a2ui_schema>
  $a2uiSchema
  </a2ui_schema>
  ''',
    ];

    return _fragmentsToPrompt(fragments);
  }
}
