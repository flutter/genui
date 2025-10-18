import 'package:flutter_genui/flutter_genui.dart';

import 'backend/api.dart';
import 'backend/model.dart';

class Protocol {
  Future<SurfaceUpdate?> sendRequest(String request) async {
    final toolCall = await Backend.sendRequest(
      UiSchemaDefinition(
        prompt: _prompt(request),
        tools: [_functionDeclaration()],
      ),
      _prompt(request),
    );

    if (toolCall == null) {
      return null;
    }

    final componentsJson = toolCall.args['components'] as List<dynamic>?;
    if (componentsJson == null) {
      return null;
    }
    final components = componentsJson
        .map((e) => Component.fromJson(e as JsonMap))
        .toList();

    return SurfaceUpdate(
      surfaceId: 'custom_backend',
      components: components,
    );
  }

  Catalog get catalog => _catalog;
}

const _toolName = 'uiGenerator';

final _catalog = CoreCatalogItems.asCatalog().copyWith([
  CoreCatalogItems.text,
  CoreCatalogItems.multipleChoice,
]);

String _prompt(String request) =>
    '''
You are a helpful assistant that provides concise and relevant information.
Always respond in a clear and structured manner.
Use the tool $_toolName to generate UI code snippets to satisfy user request.

User request: $request
''';

FunctionDeclaration _functionDeclaration() {
  return FunctionDeclaration(
    description: 'Generates UI.',
    name: _toolName,
    parameters: _catalog.definition,
  );
}
