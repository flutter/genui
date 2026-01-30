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
    required this.connector,
    required this.conversation,
    required this.surfaceUpdateController,
  });

  /// The A2UI message processor.
  final A2uiMessageProcessor a2uiMessageProcessor;

  /// The agent connector.
  final A2uiAgentConnector connector;

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

    // We don't need serverUrl here anymore as connector handles it,
    // unless we need it for something else? A2uiContentGenerator used it.
    // But A2uiAgentConnector seems self-contained.

    final controller = GenUiController(messageProcessor: a2uiMessageProcessor);

    // Wire up connector to controller
    connector.stream.listen(controller.addMessage);
    connector.textStream.listen(controller.addChunk);

    final conversation = GenUiConversation(
      controller: controller,
      onSend: (message, history) async {
        // Send request via connector
        await connector.connectAndSend(message);
      },
    );

    final surfaceUpdateController = StreamController<String>.broadcast();

    connector.stream.listen((message) {
      if (message is CreateSurface) {
        surfaceUpdateController.add(message.surfaceId);
      }
    });

    // Fetch the agent card to initialize the connection.
    await connector.getAgentCard();

    // No isProcessing on connector directly exposed?
    // GenUiConversation manages isProcessing now.

    void updateProcessingState() {
      LoadingState.instance.isProcessing.value =
          conversation.isProcessing.value;
    }

    conversation.isProcessing.addListener(updateProcessingState);

    ref.onDispose(() {
      conversation.isProcessing.removeListener(updateProcessingState);
      // Reset the loading state when the provider is disposed.
      LoadingState.instance.isProcessing.value = false;
      conversation.dispose();
      controller.dispose();
      // connector is a provider, so we should probably not dispose it here if
      // it's shared? But it was created in a separate provider?
      // a2uiAgentConnector is a provider. If we dispose
      // conversation/controller, we are good.
      surfaceUpdateController.close();
    });

    return AiClientState(
      a2uiMessageProcessor: a2uiMessageProcessor,
      connector: connector,
      conversation: conversation,
      surfaceUpdateController: surfaceUpdateController,
    );
  }
}
