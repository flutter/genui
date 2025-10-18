import 'package:flutter_genui/flutter_genui.dart';

import 'backend/api.dart';
import 'backend/model.dart';

class Protocol {
  Future<SurfaceUpdate?> sendRequest(String request) async {
    // ignore: unused_local_variable
    final toolCall = await Backend.sendRequest(
      UiSchemaDefinition(
        prompt: _prompt(request),
        tools: [_functionDeclaration()],
      ),
      _prompt(request),
    );

    return null;
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
