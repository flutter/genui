// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';

import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../primitives/simple_items.dart';
import 'catalog_context.dart';

/// Common fragments for prompts, to explain agent behavior.
// This class should not contain technical details.
// Technical details should be communicated in the [PromptBuilder] constructors.
abstract class PromptFragments {
  /// Requirement to acknowledges the user message.
  ///
  /// This is useful for chat-based prompts where the AI should
  /// acknowledge the user's message before responding.
  ///
  /// [prefix] is a prefix to be added to the prompt.
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
  /// [prefix] is a prefix to be added to the prompt.
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
  /// [prefix] is a prefix to be added to the prompt.
  /// Is useful when you want to emphasize the importance of this fragment.
  static String currentDate({String prefix = ''}) =>
      '${prefix}Current Date: '
      '${DateTime.now().toIso8601String().split('T').first}';

  /// Restriction on using tools or function calls for UI generation.
  ///
  /// This is useful to communicate limitations of UI generation to the AI.
  ///
  /// [prefix] is a prefix to be added to the prompt.
  /// Is useful when you want to emphasize the importance of this fragment.
  static String uiGenerationRestriction({String prefix = ''}) =>
      '${prefix}Do not use tools or function calls for UI generation. '
      'Use JSON text blocks.\n'
      'Ensure all JSON is valid and fenced with ```json ... ```.';

  /// Carve-out from the no-tools-for-UI rule for the `loadCatalogItems`
  /// tool used by [CatalogPromptMode.incremental].
  ///
  /// Auto-injected by the prompt builder in [CatalogPromptMode.incremental];
  /// callers do not need to add it manually.
  ///
  /// [prefix] is a prefix to be added to the prompt.
  /// Is useful when you want to emphasize the importance of this fragment.
  static String incrementalCatalogToolPolicy({String prefix = ''}) =>
      '$prefix${CatalogContext.loadCatalogItemsTool.name} is available to load '
      'A2UI catalog item schemas and examples. Calling it is context loading, '
      'not UI generation. You may also call any other provided tools; when a '
      'response needs both schemas and other tools, call them together in the '
      'same turn rather than across separate turns.';
}

/// How the catalog is presented to the model in the system prompt.
enum CatalogPromptMode {
  /// Inline the full A2UI schema, including every catalog item schema in the
  /// `updateComponents` `oneOf`.
  fullSchema,

  /// Show a compact catalog manifest up front and let the model load exact
  /// component schemas and examples on demand via the `loadCatalogItems`
  /// tool.
  ///
  /// Callers MUST register that tool (wired to [CatalogContext.loadItems])
  /// before selecting this mode, or the model will be instructed to call a
  /// tool the host has not registered.
  incremental,
}

/// A builder for a prompt to generate UI.
// TODO: consider adding operations that incorporate the user message
// and produce a final [ChatMessage].
// TODO: consider supporting non-text parts in system prompt.
abstract class PromptBuilder {
  static const String defaultImportancePrefix = 'IMPORTANT: ';

  const PromptBuilder._();

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
    CatalogPromptMode catalogPromptMode = CatalogPromptMode.fullSchema,
  }) {
    return _BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowedOperations: SurfaceOperations.createOnly(dataModel: false),
      importancePrefix: importancePrefix,
      clientDataModel: clientDataModel,
      technicalPossibilities: const TechnicalPossibilities(),
      catalogPromptMode: catalogPromptMode,
    );
  }

  factory PromptBuilder.custom({
    required Catalog catalog,
    required SurfaceOperations allowedOperations,
    Iterable<String> systemPromptFragments = const [],
    String importancePrefix = defaultImportancePrefix,
    TechnicalPossibilities technicalPossibilities =
        const TechnicalPossibilities(),
    JsonMap? clientDataModel,
    CatalogPromptMode catalogPromptMode = CatalogPromptMode.fullSchema,
  }) {
    return _BasicPromptBuilder(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments,
      allowedOperations: allowedOperations,
      importancePrefix: importancePrefix,
      clientDataModel: clientDataModel,
      technicalPossibilities: technicalPossibilities,
      catalogPromptMode: catalogPromptMode,
    );
  }

  Iterable<String> systemPrompt();

  /// Returns the system prompt as a single string.
  ///
  /// The prompt sections are trimmed and then
  /// joined with the given section separator.
  String systemPromptJoined({
    String sectionSeparator = '\n-------------------------------------\n\n',
  }) => systemPrompt().map((e) => '${e.trim()}\n').join(sectionSeparator);
}

@visibleForTesting
enum ProtocolMessages {
  createSurface(
    name: 'createSurface',
    explanation: 'Creates a new surface.',
    properties: '''
Requires `surfaceId` (you must always use a unique ID for each created surface),
`catalogId` (use the catalog ID provided in system instructions),
and `sendDataModel: true`.
''',
    // TODO: figure out why we instruct AI to always set sendDataModel: true,
    // instead of always sending it deterministically when needed.
    // TODO: generate warning or error if surfaceId is not unique.
  ),
  updateComponents(
    name: 'updateComponents',
    explanation: 'Updates components in a surface.',
    properties: '''
Requires `surfaceId` and a list of `components`.
One component MUST have `id: "root"`.
''',
  ),
  updateDataModel(
    name: 'updateDataModel',
    explanation: 'Updates the data model.',
    properties: '''
Requires `surfaceId`, `path` and `value`.
''',
  ),
  deleteSurface(
    name: 'deleteSurface',
    explanation: 'Deletes a surface.',
    properties: '''
Requires `surfaceId`.
''',
  );

  const ProtocolMessages({
    required this.name,
    required this.explanation,
    required this.properties,
  });

  final String name;
  final String explanation;
  final String properties;

  String get tickedName => '`$name`';

  static String explainMessages(Set<ProtocolMessages> operations) {
    final String names = operations.map((e) => e.tickedName).join(', ');
    final String explanations = operations
        .map((e) => '- ${e.tickedName}: ${e.explanation.trim()}')
        .join('\n');
    final String properties = operations
        .map((e) => '- ${e.tickedName}: ${e.properties.trim()}')
        .join('\n');

    return '''
Supported messages are: $names.

$explanations

Properties:

$properties

''';
  }
}

final class TechnicalPossibilities {
  final bool codeExecution;
  final bool toolCall;
  final bool functionCall;
  final String importancePrefix;

  const TechnicalPossibilities({
    this.codeExecution = false,
    this.toolCall = false,
    this.functionCall = false,
    this.importancePrefix = PromptBuilder.defaultImportancePrefix,
  });

  /// System prompt fragment related to the surface operations.
  ///
  /// This fragment should be added to the system prompt and should be used to
  /// instruct the model on how to use the surface operations.
  ///
  /// Set [includeToolRestrictions] to `false` to omit the "no tools / no
  /// function calls for UI generation" lines. [CatalogPromptMode.incremental]
  /// does this because it legitimately exposes the `loadCatalogItems` tool, and
  /// the carve-out ([PromptFragments.incrementalCatalogToolPolicy]) would
  /// otherwise have to fight these blanket prohibitions.
  Iterable<String> systemPromptFragment({bool includeToolRestrictions = true}) {
    final result = <String>[];

    if (!codeExecution) {
      result.add(
        '${importancePrefix}You do not have the ability to execute code. '
        'If you need to perform calculations, do them yourself.',
      );
    }
    if (includeToolRestrictions && !toolCall) {
      result.add(
        '${importancePrefix}You do not have the ability '
        'to use tools for UI generation.',
      );
    }
    if (includeToolRestrictions && !functionCall) {
      result.add(
        '${importancePrefix}You do not have the ability '
        'to use function calls for UI generation.',
      );
    }
    return result;
  }
}

/// Pieces of prompt that defines allowed surface operations.
final class SurfaceOperations {
  SurfaceOperations({
    this.create = false,
    this.update = false,
    this.delete = false,
    this.dataModel = false,
  }) : assert(
         create || update || delete,
         'At least one operation must be enabled.',
       );
  SurfaceOperations.createOnly({required bool dataModel})
    : this(create: true, update: false, delete: false, dataModel: dataModel);
  SurfaceOperations.updateOnly({required bool dataModel})
    : this(create: false, update: true, delete: false, dataModel: dataModel);
  SurfaceOperations.createAndUpdate({required bool dataModel})
    : this(create: true, update: true, delete: false, dataModel: dataModel);
  SurfaceOperations.all({required bool dataModel})
    : this(create: true, update: true, delete: true, dataModel: dataModel);

  final bool create;
  final bool update;
  final bool delete;
  final bool dataModel;

  late final _operations = <ProtocolMessages>{
    if (create) ...{
      ProtocolMessages.createSurface,
      ProtocolMessages.updateComponents,
    },
    if (update) ProtocolMessages.updateComponents,
    if (delete) ProtocolMessages.deleteSurface,
    if (dataModel) ProtocolMessages.updateDataModel,
  };

  late final String _operationsFormatted = _operations
      .map((e) => e.tickedName)
      .join(', ');

  late final String _controllingUI = [
    '''
You can control the UI by outputting valid A2UI JSON messages wrapped in markdown code blocks.
    ''',
    ProtocolMessages.explainMessages(_operations),
    if (create)
      '''
To create a new UI:
1. Output a ${ProtocolMessages.createSurface.tickedName} message with a unique `surfaceId` and `catalogId` (use the catalog ID provided in system instructions).
2. Output an ${ProtocolMessages.updateComponents.tickedName} message with the `surfaceId` and the component definitions.
''',
    if (!update)
      '''
IMPORTANT: DO NOT update or modify surfaces created in previous turns. If the UI needs to change, you MUST create a NEW surface with a new unique `surfaceId`. You may only use ${ProtocolMessages.updateComponents.tickedName} to populate the components of a freshly created surface.
''',
    if (update)
      '''
To update an existing UI:
1. Output an ${ProtocolMessages.updateComponents.tickedName} message with the existing `surfaceId` and the new component definitions.
''',
  ].map((e) => e.trim()).join('\n\n');

  /// System prompt fragment related to the surface operations.
  ///
  /// This fragment should be added to the system prompt and should be used to
  /// instruct the model on how to use the surface operations.
  late final Iterable<String> systemPromptFragments = () {
    final parts = <String>[];

    parts.add(_fenced(_controllingUI, sectionName: 'CONTROLLING THE UI'));

    parts.add(
      _fenced('''
When constructing UI, you must output a VALID A2UI JSON object representing one of the A2UI message types ($_operationsFormatted).
- You can treat the A2UI schema as a specification for the JSON you typically output.
- The JSON block must be valid and complete.
- Ensure your JSON is fenced with ```json and ```.
''', sectionName: 'OUTPUT FORMAT'),
    );

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
    required this.technicalPossibilities,
    required this.catalogPromptMode,
  }) : super._();

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

  final TechnicalPossibilities technicalPossibilities;

  final CatalogPromptMode catalogPromptMode;

  @override
  Iterable<String> systemPrompt() {
    if (catalogPromptMode == CatalogPromptMode.incremental) {
      return _incrementalSystemPrompt();
    }
    final String a2uiSchema = A2uiMessage.a2uiMessageSchema(
      catalog,
    ).toJson(indent: '  ');

    return _assembleSystemPrompt(
      afterTechnical: const <String>[],
      catalogSection: _fenced(a2uiSchema, sectionName: 'A2UI JSON SCHEMA'),
      restrictUiTools: true,
    );
  }

  /// Builds the system prompt in incremental mode: the default fragment
  /// chain plus the `loadCatalogItems` carve-out, with a compact catalog
  /// manifest in place of the full A2UI schema.
  Iterable<String> _incrementalSystemPrompt() {
    // createSurface requires a non-null catalogId; incremental mode is
    // out of scope for anonymous inline catalogs.
    if (allowedOperations.create && catalog.catalogId == null) {
      throw StateError(
        'CatalogPromptMode.incremental requires a non-null catalogId when '
        'createSurface is enabled.',
      );
    }
    return _assembleSystemPrompt(
      afterTechnical: <String>[
        PromptFragments.incrementalCatalogToolPolicy(prefix: importancePrefix),
      ],
      catalogSection: _incrementalCatalogPrompt(),
      restrictUiTools: false,
    );
  }

  /// Assembles the shared system-prompt fragment chain.
  ///
  /// Both catalog prompt modes share this skeleton; they differ only in
  /// [afterTechnical] (the incremental tool-policy carve-out), the
  /// [catalogSection] (full schema vs. compact manifest), and whether the
  /// tool-restriction lines are emitted ([restrictUiTools]). Keeping the order
  /// in one place avoids the two modes silently drifting apart.
  ///
  /// Note: [Catalog.systemPromptFragments] and
  /// [SurfaceOperations.systemPromptFragments] are inlined in both modes: they
  /// carry guidance, not per-item schemas, so they do not contradict the
  /// manifest's "use the loaded schemas" instruction.
  Iterable<String> _assembleSystemPrompt({
    required Iterable<String> afterTechnical,
    required String catalogSection,
    required bool restrictUiTools,
  }) {
    final fragments = <String>[
      ...systemPromptFragments,
      'Use the provided tools to respond to user using rich UI elements.',
      ...technicalPossibilities.systemPromptFragment(
        includeToolRestrictions: restrictUiTools,
      ),
      ...afterTechnical,
      ...catalog.systemPromptFragments,
      ...allowedOperations.systemPromptFragments,
      catalogSection,
      ?_encodedDataModel(clientDataModel),
    ];

    return fragments.map((fragment) => fragment.trim());
  }

  /// A compact catalog manifest plus instructions to load item details on
  /// demand through the `loadCatalogItems` tool.
  String _incrementalCatalogPrompt() {
    final CatalogManifest manifest = CatalogContext.manifest(catalog);
    final String encodedManifest = const JsonEncoder.withIndent(
      '  ',
    ).convert(manifest.toJson());
    final String toolName = CatalogContext.loadCatalogItemsTool.name;

    return _fenced('''
The active A2UI catalog is available as a compact manifest below. It lists the
available components and a short description of each, but NOT their full schemas.

Before emitting any A2UI, call the $toolName tool (input shape
{"items": ["Card", "Text"]}) to load the exact schema and examples for the
components you need.

In updateComponents.components, each component is an object with:
- id: a unique component id. Use "root" for the root component.
- component: the catalog item name.
- additional properties defined by the loaded catalog item schema.

Do not invent component properties; build valid A2UI JSON from the loaded
schemas and examples.

Catalog manifest:
$encodedManifest
''', sectionName: 'A2UI CATALOG MANIFEST');
  }

  static String? _encodedDataModel(JsonMap? clientDataModel) {
    if (clientDataModel == null) return null;
    final String encodedModel = const JsonEncoder.withIndent(
      '  ',
    ).convert(clientDataModel);
    return 'Client Data Model:\n$encodedModel';
  }
}

String _fenced(String content, {required String sectionName}) {
  final String name = sectionName.toUpperCase().replaceAll(' ', '_');
  return '-----${name}_START-----\n'
      '${content.trim()}\n'
      '-----${name}_END-----';
}
