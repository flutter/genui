// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging.dart';
import '../state/loading_state.dart';

part 'ai_provider.g.dart';

/// A provider for the A2A server URL.
@riverpod
Future<String> a2aServerUrl(Ref ref) async {
  if (!kIsWeb && Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (!androidInfo.isPhysicalDevice) {
      // Running on an emulator.
      return 'http://10.0.2.2:10002';
    }
  }
  return 'http://localhost:10002';
}

/// A provider for the A2UI agent connector.
@Riverpod(keepAlive: true)
Future<A2uiAgentConnector> a2uiAgentConnector(Ref ref) async {
  final String urlString = await ref.watch(a2aServerUrlProvider.future);
  final Uri url = Uri.parse(urlString);
  appLogger.info('A2UI server URL: ${url.toString()}');
  return A2uiAgentConnector(url: url);
}

/// The state of the AI client provider.
class AiClientState {
  /// Creates an [AiClientState].
  AiClientState({
    required this.a2uiMessageProcessor,
    required this.contentGenerator,
    required this.conversation,
    required this.surfaceUpdateController,
  });

  /// The A2UI message processor.
  final A2uiMessageProcessor a2uiMessageProcessor;

  /// The content generator.
  final A2uiContentGenerator contentGenerator;

  /// The conversation manager.
  final GenUiConversation conversation;

  /// A stream that emits the ID of the most recently updated surface.
  final StreamController<String> surfaceUpdateController;
}

/// The AI provider.
@Riverpod(keepAlive: true)
class Ai extends _$Ai {
  @override
  Future<AiClientState> build() async {
    final a2uiMessageProcessor = A2uiMessageProcessor(
      catalogs: [CoreCatalogItems.asCatalog()],
    );
    final A2uiAgentConnector connector = await ref.watch(
      a2uiAgentConnectorProvider.future,
    );
    final String serverUrl = await ref.watch(a2aServerUrlProvider.future);
    final contentGenerator = A2uiContentGenerator(
      serverUrl: Uri.parse(serverUrl),
      connector: connector,
    );
    final conversation = GenUiConversation(
      contentGenerator: contentGenerator,
      a2uiMessageProcessor: a2uiMessageProcessor,
    );
    final surfaceUpdateController = StreamController<String>.broadcast();

    contentGenerator.a2uiMessageStream.listen((message) {
      switch (message) {
        case BeginRendering():
          surfaceUpdateController.add(message.surfaceId);
        case SurfaceUpdate():
        case DataModelUpdate():
        case SurfaceDeletion():
        // We only navigate on BeginRendering.
      }
    });

    // Fetch the agent card to initialize the connection.
    await contentGenerator.connector.getAgentCard();

    void updateProcessingState() {
      LoadingState.instance.isProcessing.value =
          contentGenerator.isProcessing.value;
    }

    contentGenerator.isProcessing.addListener(updateProcessingState);

    ref.onDispose(() {
      contentGenerator.isProcessing.removeListener(updateProcessingState);
      // Reset the loading state when the provider is disposed.
      LoadingState.instance.isProcessing.value = false;
      conversation.dispose();
      // contentGenerator is disposed by conversation.dispose(), so we don't
      // need to dispose it again.
      surfaceUpdateController.close();
    });

    return AiClientState(
      a2uiMessageProcessor: a2uiMessageProcessor,
      contentGenerator: contentGenerator,
      conversation: conversation,
      surfaceUpdateController: surfaceUpdateController,
    );
  }
}
