import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../flutter_genui.dart';

/// Generic facade for GenUi package.
class UiAgent {
  UiAgent(
    String genericPrompt,
    Catalog? catalog,
    this.onSurfaceAdded,
    this.onSurfaceUpdated,
    this.onSurfaceRemoved,
  ) : _genUiManager = GenUiManager(catalog: catalog) {
    _aiClient = GeminiAiClient(
      systemInstruction: '$genericPrompt\n\n$_technicalPrompt',
      tools: _genUiManager.getTools(),
    );
  }

  final ValueChanged<SurfaceAdded>? onSurfaceAdded;
  final ValueChanged<SurfaceUpdated>? onSurfaceUpdated;
  final ValueChanged<SurfaceRemoved>? onSurfaceRemoved;
  // ValueListenable<bool> get isProcessing => _genUiManager.isProcessing;

  final GenUiManager _genUiManager;
  late final AiClient _aiClient;
  final List<ChatMessage> _conversation = [];

  Future<void> sendRequest(UserMessage message) async {
    _conversation.add(message);
    await _aiClient.generateContent(List.of(_conversation), Schema.object());
  }

  void dispose() {
    _genUiManager.dispose();
  }
}

String _technicalPrompt = '''
Use the provided tools to build and manage the user interface in response to the user's requests. Call the `addOrUpdateSurface` tool to show new content or update existing content. Use the `deleteSurface` tool to remove UI that is no longer relevant.

When updating a surface, if you are adding new UI to an existing surface, you should usually create a container widget (like a Column) to hold both the existing and new UI, and set that container as the new root.
''';
