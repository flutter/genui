// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:a2a_dart/src/client/sse_transport.dart';
library;

import 'dart:async';

import 'package:logging/logging.dart';

import '../core/agent_card.dart';
import '../core/events.dart';
import '../core/message.dart';
import '../core/task.dart';
import 'a2a_exception.dart';
import 'http_transport.dart';
import 'transport.dart';

/// A client for interacting with an A2A server.
///
/// This class provides a high-level API for communicating with an A2A server,
/// abstracting the underlying transport mechanism. It supports both standard
/// request-response interactions and streaming communication using Server-Sent
/// Events (SSE).
class A2AClient {
  final Logger? _log;
  int _nextId = 1;

  /// The base URL of the A2A server.
  final String url;

  /// The transport used for communication with the server.
  ///
  /// Defaults to [HttpTransport] if not specified. For streaming capabilities,
  /// an [SseTransport] instance should be provided.
  late final Transport transport;

  /// Creates a client for interacting with an A2A server.
  ///
  /// The [url] is the base URL of the server. An optional [transport] can be
  /// provided to customize the communication mechanism. If no transport is
  /// provided, an [HttpTransport] instance will be created by default.
  ///
  /// To listen to log messages from the client, you can listen to the
  /// [logger]'s `onRecord` stream:
  ///
  /// ```dart
  /// final client = A2AClient(url: 'http://localhost:8080');
  /// client.logger?.onRecord.listen((record) {
  ///   print('${record.level.name}: ${record.time}: ${record.message}');
  /// });
  /// ```
  A2AClient({
    required this.url,
    Transport? transport,
    Logger? logger,
  }) : _log = logger {
    this.transport = transport ?? HttpTransport(url: url, log: _log);
  }

  /// The logger used for logging messages.
  ///
  /// This can be listened to in order to receive log messages from the client.
  ///
  /// To listen to log messages from the client, you can listen to the
  /// [logger]'s `onRecord` stream:
  ///
  /// ```dart
  /// final client = A2AClient(url: 'http://localhost:8080');
  /// client.logger?.onRecord.listen((record) {
  ///   print('${record.level.name}: ${record.time}: ${record.message}');
  /// });
  /// ```
  Logger? get logger => _log;

  /// Fetches the agent's capabilities and metadata from the server.
  ///
  /// This method retrieves the [AgentCard], which contains information about
  /// the agent, such as its name, version, and supported extensions.
  Future<AgentCard> getAgentCard() async {
    _log?.info('Getting agent card');
    final response = await transport.get('.well-known/agent-card.json');
    _log?.info('Received agent card');
    return AgentCard.fromJson(response);
  }

  /// Creates a new task on the server by sending a message.
  ///
  /// This method sends a [Message] to the server and returns a [Task] object
  /// that represents the asynchronous operation.
  Future<Task> createTask(Message message) async {
    final request = {
      'jsonrpc': '2.0',
      'method': 'create_task',
      'params': {'message': message.toJson()},
      'id': _nextId++,
    };
    _log?.info('Creating task with message: ${message.toJson()}');
    final response = await transport.send(request);
    _log?.info('Received response from create_task: $response');
    if (response.containsKey('error')) {
      final error = response['error'] as Map<String, dynamic>;
      throw A2AException.jsonRpc(
        code: error['code'] as int,
        message: error['message'] as String,
        data: error['data'] as Map<String, dynamic>?,
      );
    }
    return Task.fromJson(response['result'] as Map<String, dynamic>);
  }

  /// Sends a message to the server and returns a stream of responses.
  ///
  /// This method is used for streaming communication with the server. It sends
  /// a [Message] and returns a [Stream] of [Map]s, where each map is a JSON
  /// object received from the server.
  Stream<Map<String, dynamic>> messageStream(Message message) {
    final request = {
      'jsonrpc': '2.0',
      'method': 'message/stream',
      'params': {'message': message.toJson()},
      'id': _nextId++,
    };
    _log?.info('Sending message stream: ${message.toJson()}');
    return transport.sendStream(request);
  }

  /// Executes a task on the server and returns a stream of [StreamingEvent]s.
  ///
  /// This method is used to execute a task that has been previously created. It
  /// takes a [taskId] and returns a [Stream] of [StreamingEvent]s from the
  /// server.
  Stream<StreamingEvent> executeTask(String taskId) {
    final request = {
      'jsonrpc': '2.0',
      'method': 'execute_task',
      'params': {'task_id': taskId},
      'id': _nextId++,
    };
    _log?.info('Executing task $taskId');
    return transport.sendStream(request).map(
          StreamingEvent.fromJson,
        );
  }
}
