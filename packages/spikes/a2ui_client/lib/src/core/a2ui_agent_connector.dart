// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a/a2a.dart' hide Logger;
import 'package:logging/logging.dart';

final _log = Logger('A2uiAgentConnector');

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
  A2uiAgentConnector({required this.url}) {
    _client = A2AClient(url.toString());
  }

  /// The URL of the A2UI Agent.
  final Uri url;

  final _controller = StreamController<String>.broadcast();
  late A2AClient _client;
  String? _taskId;
  String? _contextId;

  /// The stream of A2UI protocol lines.
  ///
  /// This stream emits the JSONL messages from the A2UI protocol.
  Stream<String> get stream => _controller.stream;

  /// Fetches the agent card.
  ///
  /// The agent card contains metadata about the agent, such as its name,
  /// description, and version.
  Future<AgentCard> getAgentCard() async {
    // Allow time for the agent card to be fetched.
    //await Future.delayed(const Duration(seconds: 1));
    final card = await _client.getAgentCard();
    return AgentCard(
      name: card.name,
      description: card.description,
      version: card.version,
    );
  }

  /// Connects to the agent and sends a message.
  ///
  /// The [onResponse] callback is invoked when the agent sends a text response.
  Future<void> connectAndSend(
    String messageText, {
    void Function(String)? onResponse,
  }) async {
    final message = A2AMessage()
      ..role = 'user'
      ..parts = [A2ATextPart()..text = messageText];

    if (_taskId != null) {
      message.referenceTaskIds = [_taskId!];
    }
    if (_contextId != null) {
      message.contextId = _contextId;
    }

    final payload = A2AMessageSendParams()..message = message;
    payload.extensions = [
      'https://github.com/a2aproject/a2a-samples/extensions/a2ui/v7',
    ];

    final events = _client.sendMessageStream(payload);

    try {
      await for (final event in events) {
        const encoder = JsonEncoder.withIndent('  ');
        final prettyJson = encoder.convert(event.toJson());
        _log.fine('Received A2A event:\n$prettyJson');

        if (event.isError) {
          final errorResponse = event as A2AJSONRPCErrorResponseS;
          final code = errorResponse.error?.rpcErrorCode;
          final errorMessage = 'A2A Error: $code';
          _log.severe(errorMessage);
          if (!_controller.isClosed) {
            _controller.addError(errorMessage);
          }
          continue;
        }

        final response = event as A2ASendStreamMessageSuccessResponse;
        final result = response.result;
        if (result is A2ATask) {
          _taskId = result.id;
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
          const encoder = JsonEncoder.withIndent('  ');
          final prettyJson = encoder.convert(message.toJson());
          _log.fine('Received A2A Message:\n$prettyJson');
          for (final part in message.parts ?? []) {
            if (part is A2ADataPart) {
              _processA2uiMessages(part.data);
            }
            if (part is A2ATextPart) {
              onResponse?.call(part.text);
            }
          }
        }
      }
    } finally {
      if (!_controller.isClosed) {
        unawaited(_controller.close());
      }
    }
  }

  /// Sends an event to the agent.
  ///
  /// This is used to send user interaction events to the agent, such as
  /// button clicks or form submissions.
  Future<void> sendEvent(Map<String, dynamic> event) async {
    if (_taskId == null) {
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
      ..contextId = _contextId
      ..referenceTaskIds = [_taskId!];

    final payload = A2AMessageSendParams()..message = message;
    payload.extensions = [
      'https://github.com/a2aproject/a2a-samples/extensions/a2uiui/v7',
    ];

    try {
      await _client.sendMessage(payload);
      _log.fine(
        'Successfully sent event for task $_taskId (context $_contextId)',
      );
    } catch (e) {
      _log.severe('Error sending event: $e');
    }
  }

  void _processA2uiMessages(Map<String, dynamic> data) {
    _log.finer('Processing a2ui messages from data part: $data');
    if (data.containsKey('a2uiMessages')) {
      final messages = data['a2uiMessages'] as List;
      _log.finer('Found ${messages.length} A2UI messages.');
      for (final message in messages) {
        final jsonMessage = _transformMessage(message as Map<String, dynamic>);
        if (jsonMessage != null && !_controller.isClosed) {
          _log.finest(
            'Transformed and adding message to stream: '
            '${jsonEncode(jsonMessage)}',
          );
          _controller.add(jsonEncode(jsonMessage));
        } else {
          _log.warning('Transformed message is null or controller is closed.');
        }
      }
    } else {
      _log.warning('A2A data part did not contain "a2uiMessages" key.');
    }
  }

  Map<String, dynamic>? _transformMessage(Map<String, dynamic> message) {
    _log.finest('Transforming message: $message');
    if (message.containsKey('version')) {
      _log.finest('Identified as streamHeader');
      return {'streamHeader': message};
    }
    if (message.containsKey('components')) {
      _log.finest('Identified as componentUpdate');
      return {'componentUpdate': message};
    }
    if (message.containsKey('contents')) {
      _log.finest('Identified as dataModelUpdate');
      return {'dataModelUpdate': message};
    }
    if (message.containsKey('root')) {
      _log.finest('Identified as beginRendering');
      return {'beginRendering': message};
    }
    _log.warning('Unknown message type for transform: $message');
    return null;
  }

  /// Closes the connection to the agent.
  ///
  /// This should be called when the connector is no longer needed to release
  /// resources.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
