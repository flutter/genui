// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a/a2a.dart' hide Logger;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final Logger _log = genui.genUiLogger;

/// A class to hold the agent card details.
class AgentCard {
  /// Creates a new [AgentCard] instance.
  AgentCard({
    required this.name,
    required this.description,
    required this.version,
  });

  /// The name of the agent.
  final String name;

  /// A description of the agent.
  final String description;

  /// The version of the agent.
  final String version;
}

/// Connects to an A2UI Agent endpoint and streams the A2UI protocol lines.
///
/// This class handles the communication with an A2UI agent, including fetching
/// the agent card, sending messages, and receiving the A2UI protocol stream.
class A2uiAgentConnector {
  /// Creates a [A2uiAgentConnector] that connects to the given [url].
  A2uiAgentConnector({required this.url, A2AClient? client, String? contextId})
    : _contextId = contextId {
    this.client = client ?? A2AClient(url.toString());
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
  Future<AgentCard> getAgentCard() async {
    final A2AAgentCard card = await client.getAgentCard();
    return AgentCard(
      name: card.name,
      description: card.description,
      version: card.version,
    );
  }

  /// Connects to the agent and sends a message.
  ///
  /// Returns the text response from the agent, if any.
  Future<String?> connectAndSend(
    genui.ChatMessage chatMessage, {
    genui.A2UiClientCapabilities? clientCapabilities,
  }) async {
    final List<Object> parts = (chatMessage is genui.UserMessage)
        ? chatMessage.parts
        : (chatMessage is genui.UserUiInteractionMessage)
        ? chatMessage.parts
        : <A2ATextPart>[];
    final message = A2AMessage()
      ..messageId = const Uuid().v4()
      ..role = 'user'
      ..parts = parts.map<A2APart>((part) {
        switch (part) {
          case genui.TextPart():
            return A2ATextPart()..text = part.text;
          case genui.DataPart():
            return A2ADataPart()..data = part.data as A2ASV? ?? {};
          case genui.ImagePart():
            if (part.url != null) {
              return A2AFilePart()
                ..file = (A2AFileWithUri()
                  ..uri = part.url.toString()
                  ..mimeType = part.mimeType ?? 'image/jpeg');
            } else {
              String base64Data;
              if (part.bytes != null) {
                base64Data = base64Encode(part.bytes!);
              } else if (part.base64 != null) {
                base64Data = part.base64!;
              } else {
                _log.warning('ImagePart has no data (url, bytes, or base64)');
                return A2ATextPart()..text = '[Empty Image]';
              }
              return A2AFilePart()
                ..file = (A2AFileWithBytes()
                  ..bytes = base64Data
                  ..mimeType = part.mimeType ?? 'image/jpeg');
            }
          default:
            _log.warning('Unknown message part type: ${part.runtimeType}');
            return A2ATextPart()..text = '[Unknown Part]';
        }
      }).toList();

    if (taskId != null) {
      message.referenceTaskIds = [taskId!];
    }
    if (contextId != null) {
      message.contextId = contextId;
    }
    if (clientCapabilities != null) {
      message.metadata = {
        'a2uiClientCapabilities': clientCapabilities.toJson(),
      };
    }
    final payload = A2AMessageSendParams()..message = message;
    payload.extensions = ['https://a2ui.org/a2a-extension/a2ui/v0.8'];

    _log.info('--- OUTGOING REQUEST ---');
    _log.info('URL: ${url.toString()}');
    _log.info('Method: message/stream');
    _log.info(
      'Payload: '
      '${const JsonEncoder.withIndent('  ').convert(payload.toJson())}',
    );
    _log.info('----------------------');

    final Stream<A2ASendStreamMessageResponse> events = client
        .sendMessageStream(payload);

    String? responseText;
    try {
      A2AMessage? finalResponse;
      await for (final event in events) {
        _log.info('Received raw A2A event: ${event.toJson()}');
        const encoder = JsonEncoder.withIndent('  ');
        final String prettyJson = encoder.convert(event.toJson());
        _log.info('Received A2A event:\n$prettyJson');

        if (event.isError) {
          final errorResponse = event as A2AJSONRPCErrorResponseSSM;
          final int? code = errorResponse.error?.rpcErrorCode;
          final errorMessage = 'A2A Error: $code';
          _log.severe(errorMessage);
          if (!_errorController.isClosed) {
            _errorController.add(errorMessage);
          }
          continue;
        }

        final response = event as A2ASendStreamMessageSuccessResponse;
        final A2AResult? result = response.result;
        if (result is A2ATask) {
          taskId = result.id;
          _contextId = result.contextId;
        }

        A2AMessage? message;
        if (result is A2ATask) {
          message = result.status?.message;
        } else if (result is A2AMessage) {
          message = result;
        } else if (result is A2ATaskStatusUpdateEvent) {
          message = result.status?.message;
        }

        if (message != null) {
          finalResponse = message;
          const encoder = JsonEncoder.withIndent('  ');
          final String prettyJson = encoder.convert(message.toJson());
          _log.info('Received A2A Message:\n$prettyJson');
          for (final A2APart part in message.parts ?? []) {
            if (part is A2ADataPart) {
              _processA2uiMessages(part.data);
            }
          }
        }
      }
      if (finalResponse != null) {
        for (final A2APart part in finalResponse.parts ?? []) {
          if (part is A2ATextPart) {
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

    final dataPart = A2ADataPart()..data = {'a2uiEvent': clientEvent};
    final message = A2AMessage()
      ..role = 'user'
      ..parts = [dataPart]
      ..contextId = contextId
      ..referenceTaskIds = [taskId!];

    final payload = A2AMessageSendParams()..message = message;
    payload.extensions = ['https://a2ui.org/a2a-extension/a2ui/v0.8'];

    try {
      await client.sendMessage(payload);
      _log.fine(
        'Successfully sent event for task $taskId (context $contextId)',
      );
    } catch (e) {
      _log.severe('Error sending event: $e');
    }
  }

  void _processA2uiMessages(Map<String, Object?> data) {
    _log.finer(
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
