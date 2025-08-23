import 'package:flutter/rendering.dart';

import '../../flutter_genui.dart';
import '../ai_client/ai_client.dart';
import '../core/genui_manager.dart';

/// Generic facade for GenUi package.
class UiAgent {
  UiAgent(
    String genericPrompt,
    this.onSurfaceAdded,
    this.onSurfaceUpdated,
    this.onSurfaceRemoved,
  ) : _genUiManager = GenUiManager() {
    _aiClient = GeminiAiClient(
      systemInstruction: '$genericPrompt\n\n$_technicalPrompt',
      tools: _genUiManager.getTools(),
    );
  }

  final GenUiManager _genUiManager;
  late final AiClient _aiClient;

  final ValueChanged<SurfaceAdded>? onSurfaceAdded;
  final ValueChanged<SurfaceUpdated>? onSurfaceUpdated;
  final ValueChanged<SurfaceRemoved>? onSurfaceRemoved;

  void dispose() {
    _genUiManager.dispose();
  }
}

String _technicalPrompt = '''
Use the provided tools to build and manage the user interface in response to the user's requests. Call the `addOrUpdateSurface` tool to show new content or update existing content. Use the `deleteSurface` tool to remove UI that is no longer relevant.

When updating a surface, if you are adding new UI to an existing surface, you should usually create a container widget (like a Column) to hold both the existing and new UI, and set that container as the new root.
''';
