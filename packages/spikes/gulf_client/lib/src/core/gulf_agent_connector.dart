// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a/a2a.dart';
import 'package:flutter/foundation.dart';

/// A class to hold the agent card details.
class AgentCard {
  AgentCard({
    required this.name,
    required this.description,
    required this.version,
  });

  final String name;
  final String description;
  final String version;
}

/// Connects to a GULF Agent endpoint and streams the GULF protocol lines.
class GulfAgentConnector {
  /// Creates a [GulfAgentConnector] that connects to the given [url].
  GulfAgentConnector({required this.url});

  /// The URL of the GULF Agent.
  final Uri url;

  final _controller = StreamController<String>.broadcast();
  A2AClient? _client;

  /// The stream of GULF protocol lines.
  Stream<String> get stream => _controller.stream;

  /// Fetches the agent card.
  Future<AgentCard> getAgentCard() async {
    _client = A2AClient(url.toString());
    // Allow time for the agent card to be fetched.
    //await Future.delayed(const Duration(seconds: 1));
    final card = await _client!.getAgentCard();
    return AgentCard(
      name: card.name,
      description: card.description,
      version: card.version,
    );
  }

  /// Connects to the agent and sends a message.
  Future<void> connectAndSend(String messageText) async {
    if (_client == null) {
      _controller.addError('Client not initialized. Call getAgentCard first.');
      _controller.close();
      return;
    }

    final message = A2AMessage()
      ..role = 'user'
      ..parts = [A2ATextPart()..text = messageText];

    final payload = A2AMessageSendParams()..message = message;

    final events = _client!.sendMessageStream(payload);

    await for (final event in events) {
      if (event.isError) {
        final errorResponse = event as A2AJSONRPCErrorResponseS;
        final code = errorResponse.error?.rpcErrorCode;
        final errorMessage = 'A2A Error: $code';
        debugPrint(errorMessage);
        if (!_controller.isClosed) {
          _controller.addError(errorMessage);
        }
        continue;
      }

      final response = event as A2ASendStreamMessageSuccessResponse;
      final result = response.result;

      if (result is A2AMessage) {
        for (final part in result.parts ?? []) {
          if (part is A2ADataPart) {
            _processGulfMessages(part.data);
          }
        }
      }
    }
  }

  void _processGulfMessages(Map<String, dynamic> data) {
    if (data.containsKey('gulfMessages')) {
      final messages = data['gulfMessages'] as List;
      for (final message in messages) {
        final jsonMessage = _transformMessage(message as Map<String, dynamic>);
        if (jsonMessage != null && !_controller.isClosed) {
          _controller.add(jsonEncode(jsonMessage));
        }
      }
    }
  }

  Map<String, dynamic>? _transformMessage(Map<String, dynamic> message) {
    if (message.containsKey('version')) {
      return {'streamHeader': message};
    }
    if (message.containsKey('components')) {
      return {'componentUpdate': message};
    }
    if (message.containsKey('contents')) {
      return {'dataModelUpdate': message};
    }
    if (message.containsKey('root')) {
      return {'beginRendering': message};
    }
    return null;
  }

  /// Closes the connection to the agent.
  void dispose() {
    _controller.close();
  }
}
