import '../../genui.dart';

// TODO(polina-c): add allowed surface operations
// TODO(polina-c): consider incorporating catalog rules to the catalog

/// A builder for a prompt to generate UI.
class PromptBuilder {
  /// Creates a chat prompt builder.
  ///
  /// The builder will generate a prompt for a chat session,
  /// that instructs to create new surfaces for each response
  /// and restrict surface deletion and updates.
  PromptBuilder.chat({required this.catalog, this.instructions});

  /// Instructions for the generated UI.
  ///
  /// This can include description of target user profile,
  /// description of the typical tasks the user wants to perform,
  /// wanted profile of the AI agent, examples of good responses,
  /// explanation when to use which catalog items.
  final String? instructions;

  /// Catalog to use for the generated UI.
  final Catalog catalog;

  late final String systemPrompt = () {
    final String a2uiSchema = A2uiMessage.a2uiMessageSchema(
      catalog,
    ).toJson(indent: '  ');

    return '''
${instructions ?? ''}

IMPORTANT: When you generate UI in a response, you MUST always create
a new surface with a unique `surfaceId`. Do NOT reuse or update
existing `surfaceId`s. Each UI response must be in its own new surface.

Do not delete existing surfaces.

<a2ui_schema>
$a2uiSchema
</a2ui_schema>

${StandardCatalogEmbed.standardCatalogRules}

$_basicChatPromptFragment''';
  }();
}

/// A basic chat prompt fragment.
const String _basicChatPromptFragment = '''

# Outputting UI information

Use the provided tools to respond to the user using rich UI elements.

Important considerations:
- When you are asking for information from the user, you should always include
  at least one submit button of some kind or another submitting element so that
  the user can indicate that they are done providing information.
''';
