import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'ai_client/ai_client.dart';
import 'event_debouncer.dart';
import 'ui_models.dart';
import 'ui_schema.dart';

/// A callback to set the initial UI definition.
@visibleForTesting
typedef SetUiCallback = void Function(Map<String, Object?> definition);

/// A callback to update the UI with a list of changes.
@visibleForTesting
typedef UpdateUiCallback = void Function(List<Map<String, Object?>> updates);

/// A callback to delete a UI surface.
@visibleForTesting
typedef DeleteUiCallback = void Function(String surfaceId);

/// A callback to report an error.
@visibleForTesting
typedef ErrorCallback = void Function(String message);

/// A callback to report a status update.
@visibleForTesting
typedef StatusUpdateCallback = void Function(String status);

/// A callback to report a text response from the AI.
@visibleForTesting
typedef TextResponseCallback = void Function(String text);

/// Defines the contract for a connection to the UI generation server.
///
/// This abstract class outlines the necessary methods for a client to
/// interact with the backend, including starting the connection, sending user
/// prompts and UI events, and disposing of the connection.
abstract class ServerConnection {
  /// Initializes and starts the connection to the server.
  Future<void> start();

  /// Sends a natural language prompt from the user to the server for UI
  /// generation.
  void sendPrompt(String text);

  /// Sends a user interaction event (e.g., a button tap or text field change)
  /// from the dynamic UI back to the server.
  void sendUiEvent(Map<String, Object?> event);

  /// Closes the connection and releases any associated resources.
  void dispose();
}

/// An implementation of [ServerConnection] that uses Dart [Stream]s for
/// two-way communication between the client and the UI generation logic.
///
/// This class orchestrates the flow of data:
/// - It listens to a `requests` stream for incoming prompts and UI events.
/// - It pushes responses from the AI (new UI definitions, updates, errors)
///   to a `responses` stream.
/// - It manages the lifecycle of the underlying streams and subscriptions.
@visibleForTesting
class StreamServerConnection implements ServerConnection {
  /// Creates a [StreamServerConnection] with the required callbacks to handle
  /// server-sent events.
  StreamServerConnection({
    required this.onSetUi,
    required this.onUpdateUi,
    required this.onDeleteUi,
    required this.onError,
    required this.onStatusUpdate,
    required this.onTextResponse,
    AiClient? aiClient,
  }) : _aiClient = aiClient ??
            AiClient(
              loggingCallback: (severity, message) {
                // This is not great, but it's the best we can do for now.
                // The AiClient is not aware of the response stream.
                debugPrint('[$severity] $message');
              },
            ) {
    _eventDebouncer = EventDebouncer(callback: _sendUiEvents);
  }

  /// A callback invoked when the server sends a complete new UI definition.
  final SetUiCallback onSetUi;

  /// A callback invoked when the server sends partial updates to the current
  /// UI.
  final UpdateUiCallback onUpdateUi;

  /// A callback invoked when the server sends a command to delete a UI.
  final DeleteUiCallback onDeleteUi;

  /// A callback invoked when the server reports an error.
  final ErrorCallback onError;

  /// A callback invoked with status messages from the server (e.g.,
  /// 'Generating UI...').
  final StatusUpdateCallback onStatusUpdate;

  /// A callback invoked when the server sends a text response.
  final TextResponseCallback onTextResponse;

  final AiClient _aiClient;
  late final EventDebouncer _eventDebouncer;

  final _requestsController = StreamController<Map<String, Object?>>();
  final _responsesController = StreamController<Map<String, Object?>>();
  StreamSubscription<Map<String, Object?>>? _responsesSubscription;

  @override
  Future<void> start() {
    onStatusUpdate('Starting server...');
    _responsesSubscription = _responsesController.stream.listen((response) {
      final method = response['method'] as String;
      final params = (response['params'] as Map).cast<String, Object?>();
      switch (method) {
        case 'ui.set':
          onSetUi(params);
          onStatusUpdate('Server started.');
          break;
        case 'ui.update':
          onUpdateUi([params]);
          onStatusUpdate('Server started.');
          break;
        case 'ui.delete':
          onDeleteUi(params['surfaceId'] as String);
          onStatusUpdate('Server started.');
          break;
        case 'ui.error':
          onError(params['message'] as String);
          break;
        case 'text.response':
          onTextResponse(params['text'] as String);
          break;
        case 'logging.log':
          final severity = params['severity'] as String;
          final message = params['message'] as String;
          debugPrint('[$severity] $message');
          break;
        case 'pong':
          onStatusUpdate('Server started.');
          break;
      }
    });

    unawaited(runUiServer(
      aiClient: _aiClient,
      requests: _requestsController.stream,
      responses: _responsesController,
    ));

    _requestsController.add({'method': 'ping', 'params': {}});
    return Future.value();
  }

  @override
  void sendPrompt(String text) {
    if (text.isNotEmpty) {
      _requestsController.add({
        'method': 'prompt',
        'params': {'text': text}
      });
      onStatusUpdate('Generating UI...');
    }
  }

  @override
  void sendUiEvent(Map<String, Object?> event) {
    _eventDebouncer.add(UiEvent.fromMap(event));
  }

  void _sendUiEvents(List<UiEvent> events) {
    final eventsBySurface = <String, List<UiEvent>>{};
    for (final event in events) {
      (eventsBySurface[event.surfaceId] ??= []).add(event);
    }

    for (final entry in eventsBySurface.entries) {
      _requestsController.add({
        'method': 'ui.events',
        'params': {
          'surfaceId': entry.key,
          'events': entry.value.map((e) => e.toMap()).toList(),
        }
      });
    }
    onStatusUpdate('Generating UI...');
  }

  @override
  void dispose() {
    _responsesSubscription?.cancel();
    _requestsController.close();
    _responsesController.close();
    _eventDebouncer.dispose();
  }
}

/// A factory function that creates and returns a [StreamServerConnection].
///
/// This function abstracts the instantiation of the default server connection,
/// making it easy to replace with other implementations for testing or
/// different transport layers.
ServerConnection createStreamServerConnection({
  required SetUiCallback onSetUi,
  required UpdateUiCallback onUpdateUi,
  required DeleteUiCallback onDeleteUi,
  required ErrorCallback onError,
  required StatusUpdateCallback onStatusUpdate,
  required TextResponseCallback onTextResponse,
  AiClient? aiClient,
}) {
  return StreamServerConnection(
    onSetUi: onSetUi,
    onUpdateUi: onUpdateUi,
    onDeleteUi: onDeleteUi,
    onError: onError,
    onStatusUpdate: onStatusUpdate,
    onTextResponse: onTextResponse,
    aiClient: aiClient,
  );
}

/// The core logic for the UI generation server.
///
/// This function establishes a long-running process that listens for incoming
/// messages on the [requests] stream. It maintains a conversation history with
/// the AI and uses the [aiClient] to generate UI definitions in response to
/// prompts and events. The resulting UI data is then sent out on the
/// [responses] stream.
Future<void> runUiServer({
  required AiClient aiClient,
  required Stream<Map<String, Object?>> requests,
  required StreamController<Map<String, Object?>> responses,
}) async {
  final masterConversation = <Content>[];
  final conversationsBySurfaceId = <String, List<Content>>{};

  Future<void> generateAndSendResponse({
    required List<Content> conversation,
  }) async {
    try {
      final response = await aiClient.generateContent(
        conversation,
        flutterUiDefinition,
      );
      if (response == null) {
        return;
      }
      final responseMap = response as Map<String, Object?>;
      if (responseMap['responseText'] case final String responseText) {
        responses.add({
          'method': 'text.response',
          'params': {'text': responseText},
        });
      }
      if (responseMap['actions'] case final List<Object?> actions) {
        for (final actionMap in actions.cast<Map<String, Object?>>()) {
          final action = actionMap['action'] as String;
          final surfaceId = actionMap['surfaceId'] as String;
          switch (action) {
            case 'add':
              final definition =
                  actionMap['definition'] as Map<String, Object?>;
              final newConversation = List<Content>.from(conversation);
              conversationsBySurfaceId[surfaceId] = newConversation;
              responses.add({
                'method': 'ui.set',
                'params': {
                  'surfaceId': surfaceId,
                  ...definition,
                },
              });
            case 'update':
              final definition =
                  actionMap['definition'] as Map<String, Object?>;
              responses.add({
                'method': 'ui.update',
                'params': {
                  'surfaceId': surfaceId,
                  ...definition,
                },
              });
            case 'delete':
              conversationsBySurfaceId.remove(surfaceId);
              responses.add({
                'method': 'ui.delete',
                'params': {'surfaceId': surfaceId},
              });
          }
        }
      }
    } catch (e) {
      responses.add({
        'method': 'ui.error',
        'params': {'message': e.toString()}
      });
    }
  }

  await for (final request in requests) {
    final method = request['method'] as String;
    final params = (request['params'] as Map).cast<String, Object?>();
    switch (method) {
      case 'ping':
        responses.add({
          'method': 'pong',
          'params': {},
        });
        break;
      case 'prompt':
        final prompt = params['text'] as String;
        masterConversation.add(Content.text(prompt));
        await generateAndSendResponse(
          conversation: masterConversation,
        );
        break;
      case 'ui.events':
        final surfaceId = params['surfaceId'] as String;
        final events = (params['events'] as List)
            .cast<Map<String, Object?>>()
            .map(UiEvent.fromMap);
        final surfaceConversation = conversationsBySurfaceId[surfaceId];
        if (surfaceConversation == null) {
          responses.add({
            'method': 'ui.error',
            'params': {'message': 'Unknown surfaceId: $surfaceId'}
          });
          continue;
        }
        for (final event in events) {
          final functionResponse =
              FunctionResponse(event.widgetId, event.toMap());
          surfaceConversation.add(Content.functionResponse(
              functionResponse.name, functionResponse.response));
        }
        surfaceConversation.add(Content.text(
            'The user has interacted with the UI surface named "$surfaceId". '
            'Consolidate the UI events and update the UI accordingly. Respond '
            'with an updated UI definition. You may update any of the '
            'surfaces, or delete them if they are no longer needed.'));
        await generateAndSendResponse(
          conversation: surfaceConversation,
        );
        break;
    }
  }
}

/// A factory for creating a [ServerConnection].
///
/// This allows for dependency injection of the server connection, making it
/// possible to use mock or alternative implementations for testing.
typedef ServerConnectionFactory = ServerConnection Function({
  required SetUiCallback onSetUi,
  required UpdateUiCallback onUpdateUi,
  required DeleteUiCallback onDeleteUi,
  required ErrorCallback onError,
  required StatusUpdateCallback onStatusUpdate,
  required TextResponseCallback onTextResponse,
  AiClient? aiClient,
});
