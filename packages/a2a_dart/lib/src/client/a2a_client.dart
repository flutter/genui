// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../core/agent_card.dart';
import '../core/events.dart';
import '../core/list_tasks_params.dart';
import '../core/list_tasks_result.dart';
import '../core/message.dart';
import '../core/task.dart';
import 'a2a_exception.dart';
import 'http_transport.dart';
import 'transport.dart';

/// A client for interacting with an A2A server.
///
/// This class provides methods for all the RPC calls defined in the A2A
/// specification. It handles the JSON-RPC 2.0 protocol and uses a [Transport]
/// to communicate with the server.
class A2AClient {
  /// The URL of the A2A server.
  final String url;

  final Transport _transport;
  final Logger? _log;

  /// Creates an [A2AClient].
  ///
  /// The [url] is the base URL of the A2A server.
  ///
  /// The [transport] is the transport to use for communication. If not
  /// provided, an [HttpTransport] will be used.
  ///
  /// The [log] is the logger to use for logging.
  A2AClient({required this.url, Transport? transport, Logger? log})
    : _transport = transport ?? HttpTransport(url: url, log: log),
      _log = log;

  /// Fetches the agent card from the server.
  ///
  /// The agent card contains metadata about the agent. This is typically
  /// requested from the `/.well-known/agent-card.json` endpoint.
  Future<AgentCard> getAgentCard() async {
    _log?.info('Fetching agent card...');
    final response = await _transport.get('/.well-known/agent-card.json');
    _log?.fine('Received agent card: $response');
    return AgentCard.fromJson(response);
  }

  /// Fetches the authenticated extended agent card from the server.
  ///
  /// This method is used to get a more detailed agent card that may be
  /// available to authenticated users. It sends an `Authorization` header
  /// with the given [token].
  Future<AgentCard> getAuthenticatedExtendedCard(String token) async {
    _log?.info('Fetching authenticated agent card...');
    final response = await _transport.get(
      '/.well-known/agent-card.json',
      headers: {'Authorization': 'Bearer $token'},
    );
    _log?.fine('Received authenticated agent card: $response');
    return AgentCard.fromJson(response);
  }

  /// Sends a message to the agent for a single-shot interaction.
  ///
  /// This method is used for synchronous request/response interactions. The
  /// returned [Task] contains the initial state of the task. For long-running
  /// tasks, the client can poll the task status using [getTask].
  ///
  /// Throws an [A2AException] if the server returns an error.
  Future<Task> messageSend(Message message) async {
    _log?.info('Sending message: ${message.messageId}');
    final response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'message/send',
      'params': message.toJson(),
      'id': 0,
    });
    _log?.fine('Received response from message/send: $response');
    if (response.containsKey('error')) {
      final error = response['error'] as Map<String, Object?>;
      throw A2AException.jsonRpc(
        code: error['code'] as int,
        message: error['message'] as String,
      );
    }
    return Task.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Sends a message to the agent and subscribes to real-time updates.
  ///
  /// This method is used for streaming interactions with the agent. The
  /// returned stream will emit [Event] objects as they are received from the
  /// server via Server-Sent Events (SSE).
  ///
  /// Throws an [A2AException] if the server returns an error in the stream.
  Stream<Event> messageStream(Message message) {
    _log?.info('Sending message for stream: ${message.messageId}');
    final stream = _transport.sendStream({
      'jsonrpc': '2.0',
      'method': 'message/stream',
      'params': message.toJson(),
    });

    return stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          _log?.fine('Received event from stream: $data');
          if (data.containsKey('error')) {
            final error = data['error'] as Map<String, Object?>;
            sink.addError(
              A2AException.jsonRpc(
                code: error['code'] as int,
                message: error['message'] as String,
              ),
            );
          } else {
            sink.add(Event.fromJson(data));
          }
        },
      ),
    );
  }

  /// Retrieves the current state of a task from the server.
  ///
  /// This is typically used for polling the status of a task that was initiated
  /// with [messageSend].
  Future<Task> getTask(String taskId) async {
    _log?.info('Getting task: $taskId');
    final response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/get',
      'params': {'id': taskId},
      'id': 0,
    });
    _log?.fine('Received response from tasks/get: $response');
    return Task.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Retrieves a list of tasks from the server.
  ///
  /// The optional [params] can be used to filter and paginate the results.
  Future<ListTasksResult> listTasks([ListTasksParams? params]) async {
    _log?.info('Listing tasks...');
    final response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/list',
      'params': params?.toJson() ?? {},
      'id': 0,
    });
    _log?.fine('Received response from tasks/list: $response');
    return ListTasksResult.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Requests the cancellation of an ongoing task.
  ///
  /// The server will attempt to cancel the task, but success is not guaranteed.
  /// The returned [Task] will contain the state of the task after the
  /// cancellation request.
  Future<Task> cancelTask(String taskId) async {
    _log?.info('Canceling task: $taskId');
    final response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/cancel',
      'params': {'id': taskId},
      'id': 0,
    });
    _log?.fine('Received response from tasks/cancel: $response');
    return Task.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Resubscribes to an SSE stream for an ongoing task.
  ///
  /// This can be used to reconnect to a stream after a disconnection. The
  /// returned stream will emit subsequent [Event] objects for the task.
  Stream<Event> resubscribeToTask(String taskId) {
    _log?.info('Resubscribing to task: $taskId');
    return _transport
        .sendStream({
          'jsonrpc': '2.0',
          'method': 'tasks/resubscribe',
          'params': {'id': taskId},
        })
        .where((data) => data['kind'] != null)
        .map((data) {
          _log?.fine('Received event from stream: $data');
          return Event.fromJson(data);
        });
  }

  /// Closes the underlying transport.
  void close() {
    _transport.close();
  }
}
