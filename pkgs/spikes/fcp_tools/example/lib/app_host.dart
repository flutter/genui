// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/ai_client.dart';

import 'package:fcp_tools/fcp_tools.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'catalog.dart';

class AppHost extends StatefulWidget {
  const AppHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppHost> createState() => _AppHostState();
}

class _AppHostState extends State<AppHost> {
  late final FcpSurfaceManager _surfaceManager;
  late final ConversationHistoryManager _conversationHistoryManager;
  late final AiClient _aiClient;

  @override
  void initState() {
    super.initState();
    _surfaceManager = FcpSurfaceManager();
    _conversationHistoryManager = ConversationHistoryManager(_surfaceManager);
    final widgetCatalog = exampleCatalog.buildCatalog();
    Logger('AppHost').info('Widget Catalog: ${widgetCatalog.toJson()}');
    _aiClient = GeminiAiClient(
      systemInstruction: '''
You are a helpful AI assistant that builds user interfaces. When a user asks for a UI, and you don't already know what the widget catalog contains, you MUST first call the `get_widget_catalog` tool to see the available widgets. You MUST ONLY use the widget types provided in the catalog.

To create a new UI surface, use the `ui.set` tool. To modify an existing UI surface, use the `ui.patchLayout` or `ui.patchState` tools, as appropriate.

When using the `ui` tool, you must only refer to surfaces that you know exist, either because you created them, or because you have discovered them with the `ui.list` tool.

Pay attention to the most recent UI state returned from the `ui.set` or `ui.patchLayout` or `ui.patchState` tools.

When using the `ui.patchLayout` tool, each operation in the `patches` list MUST have an `op` property.''',
      tools: [
        ...ManageUiTool(_surfaceManager).tools,
        GetWidgetCatalogTool(widgetCatalog).get,
      ],
      loggingCallback: (severity, message) {
        Logger('AiClient').log(switch (severity) {
          AiLoggingSeverity.trace => Level.FINEST,
          AiLoggingSeverity.debug => Level.FINER,
          AiLoggingSeverity.info => Level.INFO,
          AiLoggingSeverity.warning => Level.WARNING,
          AiLoggingSeverity.error => Level.SEVERE,
          AiLoggingSeverity.fatal => Level.SHOUT,
        }, message);
      },
    );
  }

  @override
  void dispose() {
    _surfaceManager.dispose();
    _conversationHistoryManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FcpToolsProvider(
      surfaceManager: _surfaceManager,
      conversationHistoryManager: _conversationHistoryManager,
      aiClient: _aiClient,
      child: widget.child,
    );
  }
}

class FcpToolsProvider extends InheritedWidget {
  const FcpToolsProvider({
    super.key,
    required this.surfaceManager,
    required this.aiClient,
    required this.conversationHistoryManager,
    required super.child,
  });

  final FcpSurfaceManager surfaceManager;
  final ConversationHistoryManager conversationHistoryManager;
  final AiClient aiClient;

  static FcpToolsProvider of(BuildContext context) {
    final FcpToolsProvider? result = context
        .dependOnInheritedWidgetOfExactType<FcpToolsProvider>();
    assert(result != null, 'No FcpToolsProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(FcpToolsProvider oldWidget) {
    return surfaceManager != oldWidget.surfaceManager ||
        aiClient != oldWidget.aiClient ||
        conversationHistoryManager != oldWidget.conversationHistoryManager;
  }
}
