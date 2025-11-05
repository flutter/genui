import 'dart:async';

import '../core/agent_card.dart';
import '../core/message.dart';
import '../core/task.dart';
import 'http_transport.dart';
import 'transport.dart';

/// A client for interacting with an A2A server.
class A2AClient {
  /// The URL of the A2A server.
  final String url;

  /// The transport to use for communication.
  final Transport transport;

  /// Creates an [A2AClient].
  A2AClient({required this.url, Transport? transport})
      : transport = transport ?? HttpTransport(url: url);

  /// Fetches the [AgentCard] from the server.
  Future<AgentCard> getAgentCard() async {
    final response = await transport.get('.well-known/agent-card.json');
    return AgentCard.fromJson(response);
  }

  /// Creates a new [Task] on the server.
  Future<Task> createTask(Message message) async {
    final request = {
      'jsonrpc': '2.0',
      'method': 'create_task',
      'params': {'message': message.toJson()},
      'id': 1,
    };
    final response = await transport.send(request);
    return Task.fromJson(response['result'] as Map<String, dynamic>);
  }

  /// Sends a message to the server and returns a stream of responses.
  Stream<Map<String, dynamic>> messageStream(Message message) {
    final request = {
      'jsonrpc': '2.0',
      'method': 'message/stream',
      'params': {'message': message.toJson()},
      'id': 1,
    };
    return transport.sendStream(request);
  }

  /// Executes a [Task] on the server and returns a stream of [Message]s.
  Stream<Message> executeTask(String taskId) {
    final request = {
      'jsonrpc': '2.0',
      'method': 'execute_task',
      'params': {'task_id': taskId},
      'id': 1,
    };
    return transport
        .sendStream(request)
        .map(
          (response) =>
              Message.fromJson(response['result'] as Map<String, dynamic>),
        );
  }
}
