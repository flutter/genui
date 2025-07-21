import 'dart:async';
import 'dart:isolate';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';

import 'ai_client/ai_client.dart';
import 'ui_models.dart';
import 'ui_schema.dart';

// A new top-level function to be able to pass the AiClient to the isolate
// for testing.
void serverIsolate(List<Object> args) {
  final sendPort = args[0] as SendPort;
  final channel = IsolateChannel<String>.connectSend(sendPort);
  final peer = rpc.Peer(channel);
  final AiClient aiClient;
  if (args.length > 1 && args[1] is AiClient) {
    aiClient = args[1] as AiClient;
  } else {
    final firebaseApp = args[1] as FirebaseApp;
    aiClient = AiClient(
      firebaseApp: firebaseApp,
      loggingCallback: (severity, message) {
        peer.sendNotification('logging.log', {
          'severity': severity.name,
          'message': message,
        });
      },
    );
  }
  _runServer(peer, aiClient);
}

Future<void> _runServer(rpc.Peer peer, AiClient aiClient) async {
  final conversation = <Content>[];

  peer.registerMethod('ping', (_) {
    return 'pong';
  });

  peer.registerMethod('prompt', (rpc.Parameters params) {
    final prompt = params['text'].asString;
    conversation.add(Content.text(prompt));
    unawaited(_generateAndSendUi(peer, aiClient, conversation));
  });

  peer.registerMethod('ui.event', (rpc.Parameters params) async {
    final event = UiEvent.fromMap(params.asMap.cast<String, Object?>());
    final functionResponse = FunctionResponse(event.widgetId, event.toMap());
    conversation.add(Content.functionResponse(
        functionResponse.name, functionResponse.response));
    await _generateAndSendUi(peer, aiClient, conversation);
  });

  await peer.listen();
}

Future<void> _generateAndSendUi(
  rpc.Peer peer,
  AiClient aiClient,
  List<Content> conversation,
) async {
  try {
    final response =
        await aiClient.generateContent(conversation, flutterUiDefinition);
    if (response != null) {
      peer.sendNotification('ui.set', response);
    }
  } catch (e) {
    peer.sendNotification('ui.error', {'message': e.toString()});
  }
}
