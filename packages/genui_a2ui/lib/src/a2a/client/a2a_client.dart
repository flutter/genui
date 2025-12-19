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
import '../core/push_notification.dart';
import '../core/task.dart';
import 'a2a_exception.dart';
import 'http_transport.dart';
import 'sse_transport.dart';
import 'transport.dart';

/// A client for interacting with an A2A (Agent-to-Agent) server.
///
/// This class provides methods for all the RPC calls defined in the A2A
/// specification. It handles the JSON-RPC 2.0 protocol and uses a [Transport]
/// instance to communicate with the server, which defaults to [HttpTransport].
A2AException _exceptionFrom(Map<String, Object?> error) {
  final code = error['code'] as int;
  final message = error['message'] as String;
  final data = error['data'] as Map<String, Object?>?;

  return switch (code) {
    -32001 => A2AException.taskNotFound(message: message, data: data),
    -32002 => A2AException.taskNotCancelable(message: message, data: data),
    -32006 => A2AException.pushNotificationNotSupported(
      message: message,
      data: data,
    ),
    -32007 => A2AException.pushNotificationConfigNotFound(
      message: message,
      data: data,
    ),
    _ => A2AException.jsonRpc(code: code, message: message, data: data),
  };
}

class A2AClient {
  /// The base URL of the A2A server.
  final String url;

  final Transport _transport;
  final Logger? _log;

  int _requestId = 0;

  /// Creates an [A2AClient] instance.
  ///
  /// The [url] parameter is required and specifies the base URL of the A2A
  /// server (e.g., `http://localhost:8000`).
  ///
  /// An optional [transport] can be provided to customize the communication
  /// layer. If omitted, an [SseTransport] is created using the provided [url].
  ///
  /// An optional [log] instance can be provided for logging client activities.
  A2AClient({required this.url, Transport? transport, Logger? log})
    : _transport = transport ?? SseTransport(url: url, log: log),
      _log = log;

  /// Creates an [A2AClient] by fetching an [AgentCard] and selecting the best
  /// transport.
  ///
  /// Fetches the agent card from [agentCardUrl], determines the best transport
  /// based on the card's capabilities (preferring streaming if available),
  /// and returns a new [A2AClient] instance.
  static Future<A2AClient> fromAgentCardUrl(
    String agentCardUrl, {
    Logger? log,
  }) async {
    final tempTransport = HttpTransport(url: agentCardUrl, log: log);
    final Map<String, Object?> response = await tempTransport.get('');
    final agentCard = AgentCard.fromJson(response);

    final HttpTransport transport = (agentCard.capabilities.streaming ?? false)
        ? SseTransport(url: agentCard.url, log: log)
        : HttpTransport(url: agentCard.url, log: log);

    return A2AClient(url: agentCard.url, transport: transport, log: log);
  }

  static String get agentCardPath => '/.well-known/agent-card.json';

  /// Fetches the public agent card from the server.
  ///
  /// The agent card contains metadata about the agent, such as its capabilities
  /// and security schemes. This method typically requests the card from the
  /// [agentCardPath] endpoint on the server.
  ///
  /// Returns an [AgentCard] object.
  /// Throws an [A2AException] if the request fails or the response is invalid.
  Future<AgentCard> getAgentCard() async {
    _log?.info('Fetching agent card...');
    final Map<String, Object?> response = await _transport.get(agentCardPath);
    _log?.fine('Received agent card: $response');
    return AgentCard.fromJson(response);
  }

  /// Fetches the authenticated extended agent card from the server.
  ///
  /// This method retrieves a potentially more detailed [AgentCard] that is only
  /// available to authenticated users. It includes an `Authorization` header
  /// with the provided Bearer [token] in the request to [agentCardPath].
  ///
  /// Returns an [AgentCard] object.
  /// Throws an [A2AException] if the request fails or the response is invalid.
  Future<AgentCard> getAuthenticatedExtendedCard(String token) async {
    _log?.info('Fetching authenticated agent card...');
    final Map<String, Object?> response = await _transport.get(
      agentCardPath,
      headers: {'Authorization': 'Bearer $token'},
    );
    _log?.fine('Received authenticated agent card: $response');
    return AgentCard.fromJson(response);
  }

  /// Sends a message to the agent for a single-shot interaction via
  /// `message/send`.
  ///
  /// This method is used for synchronous request/response interactions. The
  /// server is expected to process the [message] and return a result relatively
  /// quickly. The returned [Task] contains the initial state of the task as
  /// reported by the server.
  ///
  /// For operations that are expected to take longer, consider using
  /// [messageStream] or polling the task status using [getTask].
  ///
  /// Returns the initial [Task] state. Throws an [A2AException] if the server
  /// returns a JSON-RPC error.
  Future<Task> messageSend(Message message) async {
    _log?.info('Sending message: ${message.messageId}');
    final Map<String, Object?> params = {'message': message.toJson()};
    if (message.extensions != null) {
      params['extensions'] = message.extensions;
    }
    final Map<String, Object> messageMap = {
      'jsonrpc': '2.0',
      'method': 'message/send',
      'params': params,
      'id': _requestId++,
    };
    final Map<String, String> headers = {};
    if (message.extensions != null) {
      headers['X-A2A-Extensions'] = message.extensions!.join(',');
    }
    final Map<String, Object?> response = await _transport.send(
      messageMap,
      headers: headers,
    );
    _log?.fine('Received response from message/send: $response');
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
    return Task.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Sends a message to the agent and subscribes to real-time updates via
  /// `message/stream`.
  ///
  /// This method is used for streaming interactions. The agent can send
  /// multiple updates over time. The returned stream emits [Event] objects as
  /// they are received from the server, typically using Server-Sent Events
  /// (SSE).
  ///
  /// Returns a [Stream] of [Event] objects. The stream will emit an
  /// [A2AException] if the server sends a JSON-RPC error within the event
  /// stream.
  Stream<Event> messageStream(Message message) {
    _log?.info('Sending message for stream: ${message.messageId}');
    final Map<String, Object?> params = {
      'configuration': null,
      'metadata': null,
      'message': message.toJson(),
    };
    if (message.extensions != null) {
      params['extensions'] = message.extensions;
    }
    final Map<String, Object> messageMap = {
      'jsonrpc': '2.0',
      'method': 'message/stream',
      'params': params,
      'id': _requestId++,
    };
    final Map<String, String> headers = {};
    if (message.extensions != null) {
      headers['X-A2A-Extensions'] = message.extensions!.join(',');
    }
    final Stream<Map<String, Object?>> stream = _transport.sendStream(
      messageMap,
      headers: headers,
    );

    return stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          _log?.fine('Received event from stream: $data');
          if (data.containsKey('error')) {
            sink.addError(
              _exceptionFrom(data['error'] as Map<String, Object?>),
            );
          } else {
            if (data['kind'] != null) {
              if (data['kind'] == 'task') {
                final task = Task.fromJson(data);
                sink.add(
                  Event.statusUpdate(
                    taskId: task.id,
                    contextId: task.contextId,
                    status: task.status,
                    final_: false,
                  ),
                );
              } else {
                sink.add(Event.fromJson(data));
              }
            }
          }
        },
      ),
    );
  }

  /// Retrieves the current state of a task from the server using `tasks/get`.
  ///
  /// This method is used to poll the status of a task, identified by [taskId],
  /// that was previously initiated (e.g., via [messageSend]).
  ///
  /// Returns the current [Task] state. Throws an [A2AException] if the server
  /// returns a JSON-RPC error (e.g., task not found).
  Future<Task> getTask(String taskId) async {
    _log?.info('Getting task: $taskId');
    final Map<String, Object?> response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/get',
      'params': {'id': taskId},
      'id': _requestId++,
    });
    _log?.fine('Received response from tasks/get: $response');
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
    return Task.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Retrieves a list of tasks from the server using `tasks/list`.
  ///
  /// The optional [params] of type [ListTasksParams] can be provided to filter,
  /// sort, and paginate the task list.
  ///
  /// Returns a [ListTasksResult] containing the list of tasks and pagination
  /// info. Throws an [A2AException] if the server returns a JSON-RPC error.
  Future<ListTasksResult> listTasks([ListTasksParams? params]) async {
    _log?.info('Listing tasks...');
    final Map<String, Object?> response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/list',
      'params': params?.toJson() ?? {},
      'id': _requestId++,
    });
    _log?.fine('Received response from tasks/list: $response');
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
    return ListTasksResult.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Requests the cancellation of an ongoing task using `tasks/cancel`.
  ///
  /// The server will attempt to cancel the task identified by [taskId].
  /// Success is not guaranteed, as the task might have already completed or may
  /// not support cancellation.
  ///
  /// Returns the updated [Task] state after the cancellation request.
  /// Throws an [A2AException] if the server returns a JSON-RPC error.
  Future<Task> cancelTask(String taskId) async {
    _log?.info('Canceling task: $taskId');
    final Map<String, Object?> response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/cancel',
      'params': {'id': taskId},
      'id': _requestId++,
    });
    _log?.fine('Received response from tasks/cancel: $response');
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
    return Task.fromJson(response['result'] as Map<String, Object?>);
  }

  /// Resubscribes to an SSE stream for an ongoing task using
  /// `tasks/resubscribe`.
  ///
  /// This method allows a client to reconnect to the event stream of a task
  /// identified by [taskId], for instance, after a network interruption. The
  /// returned stream will emit subsequent [Event] objects for the task.
  ///
  /// Returns a [Stream] of [Event] objects. The stream will emit an
  /// [A2AException] if the server returns a JSON-RPC error.
  Stream<Event> resubscribeToTask(String taskId) {
    _log?.info('Resubscribing to task: $taskId');
    return _transport
        .sendStream({
          'jsonrpc': '2.0',
          'method': 'tasks/resubscribe',
          'params': {'id': taskId},
          'id': _requestId++,
        })
        .map((data) {
          _log?.fine('Received event from stream: $data');
          if (data.containsKey('error')) {
            throw _exceptionFrom(data['error'] as Map<String, Object?>);
          }
          return Event.fromJson(data);
        });
  }

  /// Closes the underlying transport connection.
  ///
  /// This should be called when the client is no longer needed to release
  /// resources.
  void close() {
    _transport.close();
  }

  /// Sets or updates the push notification configuration for a task.
  ///
  /// Uses the `tasks/pushNotificationConfig/set` method.
  ///
  /// Returns the updated [TaskPushNotificationConfig].
  /// Throws an [A2AException] if the server returns a JSON-RPC error.
  Future<TaskPushNotificationConfig> setPushNotificationConfig(
    TaskPushNotificationConfig params,
  ) async {
    _log?.info('Setting push notification config for task: ${params.taskId}');
    final Map<String, Object?> response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/pushNotificationConfig/set',
      'params': params.toJson(),
      'id': _requestId++,
    });
    _log?.fine(
      'Received response from tasks/pushNotificationConfig/set: $response',
    );
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
    return TaskPushNotificationConfig.fromJson(
      response['result'] as Map<String, Object?>,
    );
  }

  /// Retrieves a specific push notification configuration for a task.
  ///
  /// Uses the `tasks/pushNotificationConfig/get` method, identified by [taskId]
  /// and [configId].
  ///
  /// Returns the requested [TaskPushNotificationConfig].
  /// Throws an [A2AException] if the server returns a JSON-RPC error.
  Future<TaskPushNotificationConfig> getPushNotificationConfig(
    String taskId,
    String configId,
  ) async {
    _log?.info('Getting push notification config $configId for task: $taskId');
    final Map<String, Object?> response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/pushNotificationConfig/get',
      'params': {'id': taskId, 'pushNotificationConfigId': configId},
      'id': _requestId++,
    });
    _log?.fine(
      'Received response from tasks/pushNotificationConfig/get: $response',
    );
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
    return TaskPushNotificationConfig.fromJson(
      response['result'] as Map<String, Object?>,
    );
  }

  /// Lists all push notification configurations for a given task.
  ///
  /// Uses the `tasks/pushNotificationConfig/list` method, identified by [taskId].
  ///
  /// Returns a List of [PushNotificationConfig] objects.
  /// Throws an [A2AException] if the server returns a JSON-RPC error.
  Future<List<PushNotificationConfig>> listPushNotificationConfigs(
    String taskId,
  ) async {
    _log?.info('Listing push notification configs for task: $taskId');
    final Map<String, Object?> response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/pushNotificationConfig/list',
      'params': {'id': taskId},
      'id': _requestId++,
    });
    _log?.fine(
      'Received response from tasks/pushNotificationConfig/list: $response',
    );
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
    final result = response['result'] as Map<String, Object?>;
    final configs = result['configs'] as List<Object?>;
    return configs
        .map(
          (item) =>
              PushNotificationConfig.fromJson(item as Map<String, Object?>),
        )
        .toList();
  }

  /// Deletes a specific push notification configuration for a task.
  ///
  /// Uses the `tasks/pushNotificationConfig/delete` method, identified by [taskId]
  /// and [configId].
  ///
  /// Throws an [A2AException] if the server returns a JSON-RPC error.
  Future<void> deletePushNotificationConfig(
    String taskId,
    String configId,
  ) async {
    _log?.info('Deleting push notification config $configId for task: $taskId');
    final Map<String, Object?> response = await _transport.send({
      'jsonrpc': '2.0',
      'method': 'tasks/pushNotificationConfig/delete',
      'params': {'id': taskId, 'pushNotificationConfigId': configId},
      'id': _requestId++,
    });
    _log?.fine(
      'Received response from tasks/pushNotificationConfig/delete: $response',
    );
    if (response.containsKey('error')) {
      throw _exceptionFrom(response['error'] as Map<String, Object?>);
    }
  }
}
