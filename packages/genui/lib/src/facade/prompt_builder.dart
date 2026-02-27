// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../genui.dart';
import '../model/a2ui_message.dart';
import '../model/catalog.dart';

const String _importancePrefix = 'IMPORTANT:';

/// Common fragments for prompts.
abstract class PromptFragments {
  static const String acknowledgeUser = ''' 
Your responses should contain acknowledgment of the user message.
''';
  static const String requireAtLeastOneSubmitElement =
      '''
$_importancePrefix When you are asking for information from the user, you should always include
at least one submit button of some kind or another submitting element so that
the user can indicate that they are done providing information.
''';
}

// abstract class _SurfaceSystemPrompt {
//   static const String uniqueSurfaceId =
//       '''
// $_importancePrefix When you generate UI in a response, you MUST always create
// a new surface with a unique `surfaceId`. Do NOT reuse or update
// previously used `surfaceId`s. Each UI response must be in its own new surface.
// ''';
// }

/// A builder for a prompt to generate UI.
abstract class PromptBuilder {
  /// Creates a chat prompt builder.
  ///
  /// The builder will generate a prompt for a chat session,
  /// that instructs to create new surfaces for each response
  /// and restrict surface deletion and updates.
  factory PromptBuilder.chat({
    required Catalog catalog,
    List<String> systemPromptFragments = const [],
  }) {
    return BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowSurfaceCreation: true,
      allowSurfaceUpdate: false,
      allowSurfaceDeletion: false,
    );
  }

  factory PromptBuilder.custom({
    required Catalog catalog,
    required List<String> systemPromptFragments,
    required bool allowSurfaceCreation,
    required bool allowSurfaceUpdate,
    required bool allowSurfaceDeletion,
  }) {
    return BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowSurfaceCreation: allowSurfaceCreation,
      allowSurfaceUpdate: allowSurfaceUpdate,
      allowSurfaceDeletion: allowSurfaceDeletion,
    );
  }

  String get systemPrompt;
}

class BasicPromptBuilder implements PromptBuilder {
  BasicPromptBuilder({
    required this.catalog,
    required this.systemPromptFragments,
    required this.allowSurfaceCreation,
    required this.allowSurfaceUpdate,
    required this.allowSurfaceDeletion,
  });

  final Catalog catalog;

  final bool allowSurfaceCreation;
  final bool allowSurfaceUpdate;
  final bool allowSurfaceDeletion;

  /// Additional system prompt fragments.
  ///
  /// These fragments are added on top of what is provided by the catalog.
  final List<String> systemPromptFragments;

  static const _separator = '-------';

  static String _fragmentsToPrompt(List<String> fragments) =>
      fragments.map((e) => e.trim()).join('\n$_separator\n');

  @override
  late final String systemPrompt = () {
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
      '', // Empty line to separate anything concatenated later.
    ];

    return _fragmentsToPrompt(fragments);
  }();
}
