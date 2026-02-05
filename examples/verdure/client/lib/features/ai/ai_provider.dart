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
  final SurfaceController a2uiMessageProcessor;

  /// The agent connector.
  final A2uiAgentConnector connector;

  /// The conversation manager.
  final Conversation conversation;

  /// A stream that emits the ID of the most recently updated surface.
  final StreamController<String> surfaceUpdateController;
}

/// The AI provider.
@Riverpod(keepAlive: true)
class Ai extends _$Ai {
  @override
  Future<AiClientState> build() async {
    final a2uiMessageProcessor = SurfaceController(
      catalogs: [CoreCatalogItems.asCatalog()],
    );
    final A2uiAgentConnector connector = await ref.watch(
      a2uiAgentConnectorProvider.future,
    );

    final controller = A2uiTransportAdapter(
      onSend: (message) async {
        // Send request via connector
        await connector.connectAndSend(message);
      },
    );

    // Wire up connector to controller
    connector.stream.listen(controller.addMessage);
    connector.textStream.listen(controller.addChunk);

    final conversation = Conversation(
      transport: controller,
      controller: a2uiMessageProcessor,
    );

    final surfaceUpdateController = StreamController<String>.broadcast();

    connector.stream.listen((message) {
      if (message is CreateSurface) {
        surfaceUpdateController.add(message.surfaceId);
      }
    });

    // Fetch the agent card to initialize the connection.
    await connector.getAgentCard();

    void updateProcessingState() {
      LoadingState.instance.isProcessing.value =
          conversation.state.value.isWaiting;
    }

    conversation.state.addListener(updateProcessingState);

    ref.onDispose(() {
      conversation.state.removeListener(updateProcessingState);
      // Reset the loading state when the provider is disposed.
      LoadingState.instance.isProcessing.value = false;
      conversation.dispose();
      controller.dispose();
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
