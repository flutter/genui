import 'dart:async';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../ai_client/ai_client.dart';
import '../ui_models.dart';

// A new top-level function to be able to pass the AiClient to the isolate
// for testing.
@visibleForTesting
void serverIsolateTest(List<Object> args) {
  final sendPort = args[0] as SendPort;
  final aiClient = args[1] as AiClient;
  serverIsolate(sendPort, aiClient: aiClient);
}

Future<void> serverIsolate(
  SendPort sendPort, {
  AiClient? aiClient,
}) async {
  final channel = IsolateChannel<String>.connectSend(sendPort);
  final peer = rpc.Peer(channel);

  aiClient ??= AiClient();
  final conversation = <Content>[];

  peer.registerMethod('ping', (_) {
    return 'pong';
  });

  peer.registerMethod('prompt', (rpc.Parameters params) {
    final prompt = params['text'].asString;
    conversation.add(Content.text(prompt));
    unawaited(_generateAndSendUi(peer, aiClient!, conversation));
  });

  peer.registerMethod('ui.event', (rpc.Parameters params) async {
    final event = UiEvent.fromMap(params.asMap.cast<String, Object?>());
    final functionResponse = FunctionResponse(event.widgetId, event.toMap());
    conversation.add(Content.functionResponses([functionResponse]));
    await _generateAndSendUi(peer, aiClient!, conversation);
  });

  await peer.listen();
}

Future<void> _generateAndSendUi(
  rpc.Peer peer,
  AiClient aiClient,
  List<Content> conversation,
) async {
  final uiSchema = Schema(
    SchemaType.object,
    description: 'The definition of the UI to display.',
    properties: {
      'root': Schema(SchemaType.string, description: 'The root widget ID.'),
      'widgets': Schema(
        SchemaType.object,
        description: 'A map of widget definitions, keyed by widget ID.',
        properties: {
          'id': Schema(SchemaType.string, description: 'The widget ID.'),
          'type': Schema(SchemaType.string, description: 'The widget type.'),
          'props':
              Schema(SchemaType.object, description: 'The widget properties.'),
        },
      ),
    },
  );

  try {
    final response = await aiClient.generateContent(conversation, uiSchema);
    if (response != null) {
      peer.sendNotification('ui.set', response);
    }
  } catch (e) {
    peer.sendNotification('ui.error', {'message': e.toString()});
  }
}