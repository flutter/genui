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

export 'a2a/a2a.dart' show AgentCard;

final Uri a2uiExtensionUri = Uri.parse(
  'https://a2ui.org/a2a-extension/a2ui/v0.8',
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
  final _errorController = StreamController<Object>.broadcast();
  @visibleForTesting
  late A2AClient client;
  @visibleForTesting
  String? taskId;

  String? _contextId;
  String? get contextId => _contextId;

  /// The stream of A2UI protocol lines.
  ///
  /// This stream emits the JSONL messages from the A2UI protocol.
  Stream<genui.A2uiMessage> get stream => _controller.stream;

  /// A stream of errors from the A2A connection.
  Stream<Object> get errorStream => _errorController.stream;

  /// Fetches the agent card.
  ///
  /// The agent card contains metadata about the agent, such as its name,
  /// description, and version.
  Future<AgentCard> getAgentCard() async => await client.getAgentCard();

  /// Connects to the agent and sends a message.
  ///
  /// Returns the text response from the agent, if any.
  Future<String?> connectAndSend(
    genui.ChatMessage chatMessage, {
    genui.A2UiClientCapabilities? clientCapabilities,
  }) async {
    final List<genui.MessagePart> parts = switch (chatMessage) {
      genui.UserMessage(parts: final p) => p,
      genui.UserUiInteractionMessage(parts: final p) => p,
      _ => <genui.MessagePart>[],
    };

    final message = Message(
      messageId: const Uuid().v4(),
      role: Role.user,
      parts: parts.map<Part>((part) {
        switch (part) {
          case genui.TextPart():
            return Part.text(text: part.text);
          case genui.DataPart():
            return Part.data(data: part.data as Map<String, Object?>? ?? {});
          case genui.ImagePart():
            if (part.url != null) {
              return Part.file(
                file: FileType.uri(
                  uri: part.url.toString(),
                  mimeType: part.mimeType,
                ),
              );
            } else {
              String base64Data;
              if (part.bytes != null) {
                base64Data = base64Encode(part.bytes!);
              } else if (part.base64 != null) {
                base64Data = part.base64!;
              } else {
                _log.warning('ImagePart has no data (url, bytes, or base64)');
                return const Part.text(text: '[Empty Image]');
              }
              return Part.file(
                file: FileType.bytes(
                  bytes: base64Data,
                  mimeType: part.mimeType,
                ),
              );
            }
          default:
            _log.warning('Unknown message part type: ${part.runtimeType}');
            return const Part.text(text: '[Unknown Part]');
        }
      }).toList(),
    );

    var messageToSend = message;
    if (taskId != null) {
      messageToSend = messageToSend.copyWith(referenceTaskIds: [taskId!]);
    }
    if (contextId != null) {
      messageToSend = messageToSend.copyWith(contextId: contextId);
    }
    if (clientCapabilities != null) {
      messageToSend = messageToSend.copyWith(
        metadata: {'a2uiClientCapabilities': clientCapabilities.toJson()},
      );
    }

    _log.info('--- OUTGOING REQUEST ---');
    _log.info('URL: ${url.toString()}');
    _log.info('Method: message/stream');
    _log.info(
      'Payload: '
      '${const JsonEncoder.withIndent('  ').convert(messageToSend.toJson())}',
    );
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
    } on FormatException catch (e, s) {
      _log.severe('Error parsing A2A response: $e', e, s);
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
      'actionName': event['action'],
      'sourceComponentId': event['sourceComponentId'],
      'timestamp': DateTime.now().toIso8601String(),
      'resolvedContext': event['context'],
    };

    _log.finest('Sending client event: $clientEvent');

    final dataPart = Part.data(data: {'a2uiEvent': clientEvent});
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
    _log.finest(
      'Processing a2ui messages from data part:\n'
      '${const JsonEncoder.withIndent('  ').convert(data)}',
    );
    if (data.containsKey('surfaceUpdate') ||
        data.containsKey('dataModelUpdate') ||
        data.containsKey('beginRendering') ||
        data.containsKey('deleteSurface')) {
      if (!_controller.isClosed) {
        _log.finest(
          'Adding message to stream: '
          '${const JsonEncoder.withIndent('  ').convert(data)}',
        );
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
    if (!_errorController.isClosed) {
      _errorController.close();
    }
  }
}
