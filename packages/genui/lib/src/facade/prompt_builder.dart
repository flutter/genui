// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../../genui.dart';

/// Common fragments for prompts.
abstract class PromptFragments {
  /// Requirement to acknowledges the user message.
  ///
  /// This is useful for chat-based prompts where the AI should
  /// acknowledge the user's message before responding.
  ///
  /// [prefix] is a prefix to be added to the system prompt.
  /// Is useful when you want to emphasize the importance of this fragment.
  static String acknowledgeUser({String prefix = ''}) =>
      ''' 
${prefix}Your responses should contain acknowledgment of the user message.
'''
          .trim();

  /// Requirement to include at least one submit element.
  ///
  /// This is useful for chat-based prompts where the AI should
  /// include at least one submit element in each response.
  ///
  /// [prefix] is a prefix to be added to the system prompt.
  /// Is useful when you want to emphasize the importance of this fragment.
  static String requireAtLeastOneSubmitElement({String prefix = ''}) =>
      '''
${prefix}When you are asking for information from the user, you should always include
at least one submit button of some kind or another submitting element so that
the user can indicate that they are done providing information.
'''
          .trim();

  /// Current date.
  ///
  /// This is useful when AI needs to know the current date.
  ///
  /// [prefix] is a prefix to be added to the system prompt.
  /// Is useful when you want to emphasize the importance of this fragment.
  static String currentDate({String prefix = ''}) =>
      'Current Date: '
      '${DateTime.now().toIso8601String().split('T').first}';

  /// Code execution restriction.
  ///
  /// This is useful when AI may need to execute code.
  ///
  /// [prefix] is a prefix to be added to the system prompt.
  /// Is useful when you want to emphasize the importance of this fragment.
  static String codeExecutionRestriction({String prefix = ''}) =>
      'You do not have the ability to execute code. If you need to '
      'perform calculations, do them yourself.';
}

/// A builder for a prompt to generate UI.
// TODO: consider adding operations that incorporate the user message and produce
// a final [ChatMessage].
// TODO: consider supporting non-text parts in system prompt.
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
    JsonMap? clientDataModel,
  }) {
    return _BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowedOperations: SurfaceOperations.createOnly(),
      importancePrefix: importancePrefix,
      clientDataModel: clientDataModel,
    );
  }

  factory PromptBuilder.custom({
    required Catalog catalog,
    required Iterable<String> systemPromptFragments,
    required SurfaceOperations allowedOperations,
    String importancePrefix = defaultImportancePrefix,
    JsonMap? clientDataModel,
  }) {
    return _BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowedOperations: allowedOperations,
      importancePrefix: importancePrefix,
      clientDataModel: clientDataModel,
    );
  }

  Iterable<String> systemPrompt();

  /// Returns the system prompt as a single string.
  ///
  /// The prompt sections are trimmed and then
  /// joined with the given section separator.
  String systemPromptJoined({String sectionSeparator = '\n\n----\n\n'}) =>
      systemPrompt().map((e) => e.trim()).join(sectionSeparator);
}

enum _ProtocolMessages {
  createSurface(
    name: 'createSurface',
    explanation: 'Creates a new surface.',
    properties: '''
Requires `surfaceId` (you must always use a unique ID for each created surface),
`catalogId` (use the catalog ID provided in system instructions), 
and `sendDataModel: true`.
''',
    // TODO: fihure out why we instruct AI to always set sendDataModel: true, instead of just setting it deterministically.
    // TODO: generate warning or error if surfaceId is not unique.
  ),
  updateComponents(
    name: 'updateComponents',
    explanation: 'Updates components in a surface.',
    properties: '''
Requires `surfaceId` and a list of `components`. 
One component MUST have `id: "root"`.
''',
  );

  const _ProtocolMessages({
    required this.name,
    required this.explanation,
    required this.properties,
  });

  final String name;
  final String explanation;
  final String? properties;

  String get tickedName => '`$name`';

  static String explainMessages(List<_ProtocolMessages> operations) {
    final names = operations.map((e) => e.tickedName).join(', ');
    final explanations = operations
        .map((e) => '- ${e.tickedName}: ${e.explanation}')
        .join('\n');
    final properties = operations
        .map((e) => '- ${e.tickedName}: ${e.properties}')
        .join('\n');

    return '''
Supported messages are: $names.

$explanations

Properties:

$properties

''';
  }
}

/// Defines the set of allowed surface operations.
final class SurfaceOperations {
  SurfaceOperations({
    required this.create,
    required this.update,
    required this.delete,
  });
  SurfaceOperations.createOnly()
    : this(create: true, update: false, delete: false);
  SurfaceOperations.updateOnly()
    : this(create: false, update: true, delete: false);
  SurfaceOperations.createAndUpdate()
    : this(create: true, update: true, delete: false);
  SurfaceOperations.all() : this(create: true, update: true, delete: true);

  final bool create;
  final bool update;
  final bool delete;

  // Properties:
  // - `createSurface`: requires `surfaceId`, `catalogId` (use the catalog ID provided in system instructions), and `sendDataModel: true`.
  // - `updateComponents`: requires `surfaceId` and a list of `components`. One component MUST have `id: "root"`.

  // IMPORTANT:
  // - Do not use tools or function calls for UI generation. Use JSON text blocks.
  // - Ensure all JSON is valid and fenced with ```json ... ```.

  // // ignore: unused_element
  // abstract class _SurfaceSystemPrompt {
  //   // ignore: unused_field
  //   static String uniqueSurfaceId({String prefix = ''}) =>
  //       '''
  // ${prefix}When you generate UI in a response, you MUST always create
  // a new surface with a unique `surfaceId`. Do NOT reuse or update
  // previously used `surfaceId`s. Each UI response must be in its own new surface.
  // '''
  //           .trim();
  // }

  late final Iterable<String> _surfaceOperationsFragments = () {
    if (delete) {
      throw UnimplementedError(
        'Delete is not supported yet. Please file an issue if you need it, '
        'and explain your scenario.',
      );
    }

    final parts = <String>[];

    //     parts.add('''
    // ## Controlling the UI

    // You can control the UI by outputting valid A2UI JSON messages wrapped in markdown code blocks.
    // ''');

    //     } else {
    //       assert(update);
    //       parts.add('Supported message is: `updateComponents`.');
    //     }

    //     if (update) {
    //       parts.add('''
    // To update an existing UI:
    // 1. Output an `updateComponents` message with the existing `surfaceId` and the new component definitions.
    // ''');
    //     }
    //     // To update an existing UI (e.g. adding items to an itinerary):
    //     // 1. Output an `updateComponents` message with the existing `surfaceId` and the new component definitions.
    //     if (create) {
    //       parts.add('''

    // ''');
    //     }

    //     if (update) {
    //       parts.add('update');
    //     }

    return parts;
  }();
}

final class _BasicPromptBuilder extends PromptBuilder {
  /// Creates a prompt builder.
  ///
  /// Even nullable parameters are required for readability, discoverability and
  /// reliability. To skip them, use helper methods of [PromptBuilder].
  const _BasicPromptBuilder({
    required this.catalog,
    required this.systemPromptFragments,
    required this.allowedOperations,
    required this.importancePrefix,
    required this.clientDataModel,
  });

  final Catalog catalog;

  final SurfaceOperations allowedOperations;

  /// Prefix for important sections of the prompt.
  ///
  /// Sections, generated from the catalog that are marked,
  /// to make sure AI follows them
  /// will be prefixed with this string.
  final String importancePrefix;

  /// Additional system prompt fragments.
  ///
  /// These fragments are added on top of what is provided by the catalog.
  final Iterable<String> systemPromptFragments;

  final JsonMap? clientDataModel;

  Iterable<String> _fragmentsToPrompt(Iterable<String> fragments) =>
      fragments.map((e) => e.trim());

  @override
  Iterable<String> systemPrompt() {
    final String a2uiSchema = A2uiMessage.a2uiMessageSchema(
      catalog,
    ).toJson(indent: '  ');

    final fragments = <String>[
      ...systemPromptFragments,
      'Use the provided tools to respond to user using rich UI elements.',
      ...catalog.systemPromptFragments,
      ...allowedOperations._surfaceOperationsFragments,
      'A2UI Message Schema:\n$a2uiSchema',
      ?_encodedDataModel(clientDataModel),
    ];

    return _fragmentsToPrompt(fragments);
  }

  static String? _encodedDataModel(JsonMap? clientDataModel) {
    if (clientDataModel == null) return null;
    final String encodedModel = const JsonEncoder.withIndent(
      '  ',
    ).convert(clientDataModel);
    return 'Client Data Model:\n$encodedModel';
  }
}
