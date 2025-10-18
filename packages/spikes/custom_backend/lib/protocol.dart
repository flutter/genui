// ignore_for_file: avoid_dynamic_calls

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

    final componentsMap = toolCall.args['components'] as JsonMap?;
    if (componentsMap == null) {
      return null;
    }
    final components = componentsMap.entries.map((entry) {
      final componentName = entry.key;
      final componentProps = entry.value as Map<String, dynamic>;
      return Component(
        id: componentName,
        componentProperties: {componentName: componentProps},
      );
    }).toList();

    return SurfaceUpdate(surfaceId: 'custom_backend', components: components);
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
