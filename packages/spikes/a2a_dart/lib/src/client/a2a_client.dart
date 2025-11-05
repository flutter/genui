import 'dart:async';

import '../core/agent_card.dart';
import '../core/message.dart';
import '../core/task.dart';
import 'http_transport.dart';
import 'transport.dart';

/// A client for interacting with an A2A (Agent-to-Agent) server.
class A2AClient {
  /// Creates an [A2AClient].
  A2AClient({required this.url, Transport? transport})
    : transport = transport ?? HttpTransport(url: url);

  /// The URL of the A2A server.
  final String url;

  /// The transport to use for communication.
  final Transport transport;

  /// Fetches the agent's capabilities and metadata.
  Future<AgentCard> getAgentCard() async {
    final response = await transport.get('$url/.well-known/agent-card.json');
    return AgentCard.fromJson(response);
  }

  /// Creates a new task.
  Future<Task> createTask(Message message) async {
    final request = {
      'jsonrpc': '2.0',
      'method': 'message/send',
      'params': {'message': message.toJson()},
      'id': 1,
    };
    final response = await transport.send(request);
    return Task.fromJson(response['result'] as Map<String, dynamic>);
  }

  /// Executes a task and streams responses.
  Stream<Message> executeTask(Message message) {
    final request = {
      'jsonrpc': '2.0',
      'method': 'message/stream',
      'params': {'message': message.toJson()},
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
