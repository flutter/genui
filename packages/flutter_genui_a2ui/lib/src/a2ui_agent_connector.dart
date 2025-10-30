// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a/a2a.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_genui/flutter_genui.dart' as genui;
import 'package:uuid/uuid.dart';

final _log = genui.genUiLogger;

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
    final card = await client.getAgentCard();
    return AgentCard(
      name: card.name,
      description: card.description,
      version: card.version,
    );
  }

  /// Connects to the agent and sends a message.
  ///
  /// Returns the text response from the agent, if any.
  Future<String?> connectAndSend(genui.ChatMessage chatMessage) async {
    final message = A2AMessage()
      ..messageId = const Uuid().v4()
      ..role = 'user'
      ..parts = (chatMessage as genui.UserMessage).parts
          .whereType<genui.TextPart>()
          .map((part) {
            return A2ATextPart()..text = part.text;
          })
          .toList();

    if (taskId != null) {
      message.referenceTaskIds = [taskId!];
    }
    if (contextId != null) {
      message.contextId = contextId;
    }

    final payload = A2AMessageSendParams()..message = message;
    payload.extensions = ['https://a2ui.org/ext/a2a-ui/v0.1'];

    _log.info('--- OUTGOING REQUEST ---');
    _log.info('URL: ${url.toString()}');
    _log.info('Method: message/stream');
    _log.info('Payload: ${jsonEncode(payload.toJson())}');
    _log.info('----------------------');

    final events = client.sendMessageStream(payload);

    String? responseText;
    try {
      A2AMessage? finalResponse;
      await for (final event in events) {
        _log.info('Received raw A2A event: ${event.toJson()}');
        const encoder = JsonEncoder.withIndent('  ');
        final prettyJson = encoder.convert(event.toJson());
        _log.info('Received A2A event:\n$prettyJson');

        if (event.isError) {
          final errorResponse = event as A2AJSONRPCErrorResponseSSM;
          final code = errorResponse.error?.rpcErrorCode;
          final errorMessage = 'A2A Error: $code';
          _log.severe(errorMessage);
          if (!_errorController.isClosed) {
            _errorController.add(errorMessage);
          }
          continue;
        }

        final response = event as A2ASendStreamMessageSuccessResponse;
        final result = response.result;
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
          final prettyJson = encoder.convert(message.toJson());
          _log.info('Received A2A Message:\n$prettyJson');
          for (final part in message.parts ?? []) {
            if (part is A2ADataPart) {
              _processA2uiMessages(part.data);
            }
          }
        }
      }
      if (finalResponse != null) {
        for (final part in finalResponse.parts ?? []) {
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

    final clientEvent = {
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
    payload.extensions = ['https://a2ui.org/ext/a2a-ui/v0.1'];

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
    _log.finer('Processing a2ui messages from data part: $data');
    if (data.containsKey('surfaceUpdate') ||
        data.containsKey('dataModelUpdate') ||
        data.containsKey('beginRendering') ||
        data.containsKey('deleteSurface')) {
      if (!_controller.isClosed) {
        _log.finest(
          'Adding message to stream: '
          '${jsonEncode(data)}',
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
