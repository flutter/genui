# A2A Dart

This package provides a Dart implementation of the A2A (Agent-to-Agent) protocol. It includes a client for interacting with A2A servers and a server framework for building A2A agents.

## Features

-   **A2A Client**: A high-level client for communicating with A2A servers.
-   **HTTP and SSE Transports**: Support for both standard request-response and streaming communication.
-   **A2A Server**: A simple and extensible server framework.
-   **Type-Safe Data Models**: Dart classes for all A2A data structures.
-   **Web Compatible**: The client can be used in web applications.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  a2a_dart: ^0.1.0 # or the latest version
```

## Usage

### Client

```dart
import 'package:a2a_dart/a2a_dart.dart';
import 'package:logging/logging.dart';

void main() async {
  final log = Logger('A2AClient');
  // For streaming, use SseTransport.
  final transport = SseTransport(url: 'http://localhost:8080', log: log);
  final client = A2AClient(url: 'http://localhost:8080', transport: transport);

  // Get the agent card.
  final agentCard = await client.getAgentCard();
  print('Agent: ${agentCard.name}');

  // Create a new task.
  final message = Message(
    messageId: '1',
    role: Role.user,
    parts: [Part.text(text: 'Hello')],
  );
  final task = await client.createTask(message);
  print('Created task: ${task.id}');

  // Execute the task and stream the results.
  try {
    final stream = client.executeTask(task.id);
    await for (final event in stream) {
      print('Received event: ${event.type}');
    }
  } on A2AException catch (e) {
    print('Error executing task: ${e.message}');
  }
}
```

### Server

```dart
import 'package:a2a_dart/a2a_dart.dart';

void main() async {
  final taskManager = TaskManager();
  final server = A2AServer([
    CreateTaskHandler(taskManager),
  ]);

  await server.start();
  print('Server started on port ${server.port}');
}
```
