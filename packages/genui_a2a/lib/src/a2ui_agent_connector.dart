// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'a2a/a2a.dart';
import 'logging_utils.dart';

export 'a2a/a2a.dart' show AgentCard;

final Uri a2uiExtensionUri = Uri.parse(
  'https://a2ui.org/a2a-extension/a2ui/v0.9',
);

final Logger _log = genui.genUiLogger;

/// Connects to an A2UI Agent endpoint and streams the A2UI protocol lines.
///
/// This class handles the communication with an A2UI agent, including fetching
/// the agent card, sending messages, and receiving the A2UI protocol stream.
class A2uiAgentConnector {
  /// Creates a [A2uiAgentConnector] that connects to the given [url].
  A2uiAgentConnector({required this.url, A2AClient? client, String? contextId})
    : _contextId = contextId {
    this.client =
        client ??
        A2AClient(
          url: url.toString(),
          log: _log,
          transport: SseTransport(
            url: url.toString(),
            log: _log,
            authHeaders: {'X-A2A-Extensions': a2uiExtensionUri.toString()},
          ),
        );
  }

  /// The URL of the A2UI Agent.
  final Uri url;

  final _controller = StreamController<genui.A2uiMessage>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  @visibleForTesting
  late A2AClient client;

  /// The current task ID from the A2A server.
  @visibleForTesting
  String? taskId;

  String? _contextId;

  /// The current context ID from the A2A server.
  String? get contextId => _contextId;

  /// The stream of A2UI messages.
  Stream<genui.A2uiMessage> get stream => _controller.stream;

  /// The stream of text responses.
  Stream<String> get textStream => _textController.stream;

  /// A stream of errors from the A2A connection.
  Stream<Object> get errorStream => _errorController.stream;

  /// Fetches the agent card.
  ///
  /// The agent card contains metadata about the agent, such as its name,
  /// description, and version.
  Future<AgentCard> getAgentCard() async => await client.getAgentCard();

  /// Connects to the agent and sends a message.
  ///
  /// The [clientCapabilities] describe the UI capabilities of the client,
  /// specifically determining which component catalogs are supported.
  ///
  /// The [clientDataModel] allows passing the current state of client-side
  /// data to the agent, enabling context-aware responses.
  ///
  /// Returns the text response from the agent, if any.
  Future<String?> connectAndSend(
    genui.ChatMessage chatMessage, {
    genui.A2UiClientCapabilities? clientCapabilities,
    Map<String, Object?>? clientDataModel,
    genui.CancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.addListener(() {
      if (taskId != null) {
        client.cancelTask(taskId!);
      }
    });

    final message = Message(
      messageId: const Uuid().v4(),
      role: Role.user,
      parts: chatMessage.parts.map<Part>((part) {
        if (part is genui.TextPart) {
          return Part.text(text: part.text);
        } else if (part.isUiInteractionPart) {
          final genui.UiInteractionPart uiPart = part.asUiInteractionPart!;
          try {
            final Object? json = jsonDecode(uiPart.interaction);
            if (json is Map<String, Object?>) {
              return Part.data(data: json);
            }
            return Part.text(text: uiPart.interaction);
          } catch (e) {
            return Part.text(text: uiPart.interaction);
          }
        } else if (part.isUiPart) {
          final genui.UiPart uiPart = part.asUiPart!;
          return Part.data(data: uiPart.definition.toJson());
        } else if (part is genui.DataPart) {
          return Part.file(
            file: FileType.bytes(
              bytes: base64Encode(part.bytes),
              mimeType: part.mimeType,
            ),
          );
        } else if (part is genui.LinkPart) {
          return Part.file(
            file: FileType.uri(
              uri: part.url.toString(),
              mimeType: part.mimeType ?? 'application/octet-stream',
            ),
          );
        }
        return const Part.text(text: '');
      }).toList(),
    );

    var messageToSend = message;
    if (taskId != null) {
      messageToSend = messageToSend.copyWith(referenceTaskIds: [taskId!]);
    }
    if (contextId != null) {
      messageToSend = messageToSend.copyWith(contextId: contextId);
    }

    final metadata = <String, Object?>{};
    if (clientCapabilities != null) {
      metadata['a2uiClientCapabilities'] = clientCapabilities.toJson();
    }
    if (clientDataModel != null) {
      metadata['a2uiClientDataModel'] = clientDataModel;
    }
    if (metadata.isNotEmpty) {
      messageToSend = messageToSend.copyWith(metadata: metadata);
    }

    _log.info('--- OUTGOING REQUEST ---');
    _log.info('URL: $url');
    _log.info('Method: message/stream');
    try {
      final String payload = const JsonEncoder.withIndent(
        '  ',
      ).convert(sanitizeLogData(messageToSend.toJson()));
      _log.info('Payload: $payload');
    } catch (e) {
      _log.warning('Error logging payload: $e');
    }
    _log.info('----------------------');

    final Stream<Event> events = client.messageStream(messageToSend);

    String? responseText;
    try {
      Message? finalResponse;
      await for (final event in events) {
        _log.info('Received raw A2A event: ${event.toJson()}');
        const encoder = JsonEncoder.withIndent('  ');
        final String prettyJson = encoder.convert(event.toJson());
        _log.info('Received A2A event:\n$prettyJson');

        if (event is TaskStatusUpdate) {
          taskId = event.taskId;
          _contextId = event.contextId;
          final Message? message = event.status.message;

          switch (event.status.state) {
            case TaskState.failed:
            case TaskState.canceled:
            case TaskState.rejected:
              final errorMessage =
                  'A2A Error: ${event.status.state}: ${event.status.message}';
              _log.severe(errorMessage);
              if (!_errorController.isClosed) {
                _errorController.add(errorMessage);
              }
              continue;
            default:
          }

          if (message != null) {
            finalResponse = message;
            _log.info(
              'Received A2A Message:\n${encoder.convert(message.toJson())}',
            );
            for (final Part part in message.parts) {
              if (part is DataPart) {
                _processA2uiMessages(part.data);
              } else if (part is TextPart) {
                if (!_textController.isClosed) {
                  _textController.add(part.text);
                }
              }
            }
          }
        }
        if (event is StatusUpdate) {
          taskId = event.taskId;
          _contextId = event.contextId;
          final Message? message = event.status.message;

          switch (event.status.state) {
            case TaskState.failed:
            case TaskState.canceled:
            case TaskState.rejected:
              final errorMessage =
                  'A2A Error: ${event.status.state}: ${event.status.message}';
              _log.severe(errorMessage);
              if (!_errorController.isClosed) {
                _errorController.add(errorMessage);
              }
              continue;
            default:
          }

          if (message != null) {
            finalResponse = message;
            _log.info(
              'Received A2A Message:\n${encoder.convert(message.toJson())}',
            );
            for (final Part part in message.parts) {
              if (part is DataPart) {
                _processA2uiMessages(part.data);
              } else if (part is TextPart) {
                if (!_textController.isClosed) {
                  _textController.add(part.text);
                }
              }
            }
          }
        }
      }
      if (finalResponse != null) {
        for (final Part part in finalResponse.parts) {
          if (part is TextPart) {
            responseText = part.text;
          }
        }
      }
    } on FormatException catch (exception, stackTrace) {
      _log.severe(
        'Error parsing A2A response: $exception',
        exception,
        stackTrace,
      );
    }
    return responseText;
  }

  /// Sends an event to the agent.
  ///
  /// This is used to send user interaction events to the agent, such as
  /// button clicks or form submissions.
  Future<void> sendEvent(Map<String, Object?> event) async {
    if (taskId == null) {
      _log.severe('Cannot send event, no active task ID.');
      return;
    }

    final Map<String, Object?> clientEvent = {
      'version': 'v0.9',
      'action': {
        'name': event['action'],
        'sourceComponentId': event['sourceComponentId'],
        'timestamp': DateTime.now().toIso8601String(),
        'context': event['context'],
        if (event.containsKey('surfaceId')) 'surfaceId': event['surfaceId'],
      },
    };

    _log.finest('Sending client event: $clientEvent');

    final dataPart = Part.data(data: clientEvent);
    final message = Message(
      role: Role.user,
      parts: [dataPart],
      contextId: contextId,
      referenceTaskIds: [taskId!],
      messageId: const Uuid().v4(),
      extensions: [a2uiExtensionUri.toString()],
    );

    try {
      final Task response = await client.messageSend(message);
      _log.fine(
        'Response: '
        '${const JsonEncoder.withIndent('  ').convert(response.toJson())}',
      );
      _log.fine(
        'Successfully sent event for task $taskId (context $contextId)',
      );
    } catch (e) {
      _log.severe('Error sending event: $e');
    }
  }

  void _processA2uiMessages(Map<String, Object?> data) {
    var prettyJson = '(Error sanitizing log data)';
    try {
      prettyJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(sanitizeLogData(data));
      _log.finest('Processing a2ui messages from data part:\n$prettyJson');
    } catch (e) {
      _log.warning('Error logging a2ui messages: $e');
    }
    if (data.containsKey('updateComponents') ||
        data.containsKey('updateDataModel') ||
        data.containsKey('createSurface') ||
        data.containsKey('deleteSurface')) {
      if (!_controller.isClosed) {
        _log.finest('Adding message to stream: $prettyJson');
        _controller.add(genui.A2uiMessage.fromJson(data));
      }
    } else {
      _log.warning('A2A data part did not contain any known A2UI messages.');
    }
  }

  /// Closes the connection to the agent.
  ///
  /// This should be called when the connector is no longer needed to release
  /// resources.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
    if (!_textController.isClosed) {
      _textController.close();
    }
    if (!_errorController.isClosed) {
      _errorController.close();
    }
  }
}
