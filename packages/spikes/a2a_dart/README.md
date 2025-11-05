# A2A Dart

This package provides a Dart implementation of the A2A (Agent-to-Agent) protocol.

## Usage

### Client

```dart
import 'package:a2a_dart/a2a_dart.dart';

void main() async {
  final client = A2AClient(url: 'http://localhost:8080/rpc');

  // Get the agent card.
  final agentCard = await client.getAgentCard();
  print('Agent: ${agentCard.name}');

  // Create a new task.
  final message = Message(
    messageId: '1',
    role: Role.user,
    parts: [TextPart(text: 'Hello')],
  );
  final task = await client.createTask(message);
  print('Created task: ${task.id}');

  // Execute the task and stream the results.
  final stream = client.executeTask(task.id);
  await for (final message in stream) {
    print('Received message: ${message.messageId}');
  }
}
```

### Server

```dart
import 'package:a2a_dart/a2a_dart_server.dart';

void main() async {
  final taskManager = TaskManager();
  final server = A2AServer([
    CreateTaskHandler(taskManager),
  ]);

  await server.start();
}
```
