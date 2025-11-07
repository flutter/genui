// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart' hide A2AServer;
import 'package:a2a_dart/src/server/io_a2a_server.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'get_authenticated_extended_card_handler.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  group('A2AClient and A2AServer', () {
    late A2AServer server;
    late TaskManager taskManager;
    final agentCard = const AgentCard(
      name: 'Test Agent',
      protocolVersion: '0.1.0',
      url: '',
      version: '0.1.0',
      description: 'A test agent.',
      capabilities: AgentCapabilities(streaming: false),
      defaultInputModes: [],
      defaultOutputModes: [],
      skills: [],
    );

    setUp(() async {
      taskManager = InMemoryTaskManager();
      final handlers = [
        MessageSendHandler(taskManager),
        MessageStreamHandler(taskManager),
        GetTaskHandler(taskManager),
        ListTasksHandler(taskManager),
        CancelTaskHandler(taskManager),
        ResubscribeHandler(taskManager),
        GetAuthenticatedExtendedCardHandler(),
      ];
      server = A2AServer(
        handlers,
        host: 'localhost',
        agentCard: agentCard,
      )
        ..extendedAgentCard = agentCard.copyWith(name: 'Extended Test Agent');
      await server.start();
    });

    tearDown(() {
      server.stop();
    });

    test('client can list tasks on the server', () async {
      final client = A2AClient(url: 'http://localhost:${server.port}');
      await client.messageSend(
        Message(messageId: const Uuid().v4(), role: Role.user, parts: const []),
      );
      await client.messageSend(
        Message(messageId: const Uuid().v4(), role: Role.user, parts: const []),
      );
      final result = await client.listTasks();
      expect(result.tasks, hasLength(2));
      expect(result.totalSize, equals(2));
    });

    test('client can cancel a task on the server', () async {
      final client = A2AClient(url: 'http://localhost:${server.port}');
      final message = Message(
        messageId: const Uuid().v4(),
        role: Role.user,
        parts: const [],
      );
      final task = await client.messageSend(message);
      final canceledTask = await client.cancelTask(task.id);
      expect(canceledTask.status.state, equals(TaskState.canceled));
    });

    test('client can resubscribe to a task on the server', () async {
      final client = A2AClient(
        url: 'http://localhost:${server.port}',
        transport: SseTransport(url: 'http://localhost:${server.port}'),
      );
      final message = Message(
        messageId: const Uuid().v4(),
        role: Role.user,
        parts: const [],
      );
      final stream = client.messageStream(message);
      final events = await stream.toList();
      expect(events, isNotEmpty);
      final taskId = (events.first as TaskStatusUpdateEvent).taskId;

      final resubscribedStream = client.resubscribeToTask(taskId);
      final resubscribedEvents = await resubscribedStream.toList();
      expect(resubscribedEvents, equals(events));
    });

    test('client can get an authenticated extended agent card', () async {
      final client = A2AClient(url: 'http://localhost:${server.port}');
      final card = await client.getAuthenticatedExtendedCard('some-token');
      expect(card.name, equals('Extended Test Agent'));
    });

    test('client can get a task from the server', () async {
      final client = A2AClient(url: 'http://localhost:${server.port}');
      final message = Message(
        messageId: const Uuid().v4(),
        role: Role.user,
        parts: const [Part.text(text: 'start 10')],
      );
      final task = await client.messageSend(message);
      final retrievedTask = await client.getTask(task.id);
      expect(retrievedTask.id, equals(task.id));
    });

    test('client can create and execute a task on the server', () async {
      final client = A2AClient(
        url: 'http://localhost:${server.port}',
        transport: SseTransport(url: 'http://localhost:${server.port}'),
      );
      final message = const Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );

      final stream = client.messageStream(message);
      final events = await stream.toList();

      expect(events, hasLength(3));
      expect(events[0], isA<TaskStatusUpdateEvent>());
      expect(
        (events[0] as TaskStatusUpdateEvent).status.state,
        equals(TaskState.working),
      );
      expect(events[1], isA<TaskArtifactUpdateEvent>());
      expect(
        (events[1] as TaskArtifactUpdateEvent).artifact.artifactId,
        equals('artifact-1'),
      );
      expect(
        (events[1] as TaskArtifactUpdateEvent).artifact.parts[0],
        const Part.text(text: 'Here is your artifact'),
      );
      expect(events[2], isA<TaskStatusUpdateEvent>());
      expect(
        (events[2] as TaskStatusUpdateEvent).status.state,
        equals(TaskState.completed),
      );
    });

    test('client handles server errors gracefully', () async {
      final client = A2AClient(url: 'http://localhost:${server.port}');
      final message = const Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );

      // Stop the server to simulate a connection error
      await server.stop();

      expect(client.messageSend(message), throwsException);
    });
  });
}


class MessageStreamHandler implements RequestHandler {
  MessageStreamHandler(this.taskManager);

  final TaskManager taskManager;

  @override
  String get method => 'message/stream';

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final streamController = StreamController<Map<String, Object?>>();
    final message = Message.fromJson(params);
    final task = await taskManager.createTask(message);

    // Simulate work
    await taskManager.updateTask(
      task.copyWith(status: const TaskStatus(state: TaskState.working)),
    );
    final workingEvent = Event.taskStatusUpdate(
      taskId: task.id,
      contextId: task.contextId,
      status: const TaskStatus(state: TaskState.working),
      final_: false,
    );
    streamController.add(workingEvent.toJson());
    await taskManager.addEvent(task.id, workingEvent);

    final artifactEvent = Event.taskArtifactUpdate(
      taskId: task.id,
      contextId: task.contextId,
      artifact: const Artifact(
        artifactId: 'artifact-1',
        parts: [Part.text(text: 'Here is your artifact')],
      ),
      append: false,
      lastChunk: true,
    );
    streamController.add(artifactEvent.toJson());
    await taskManager.addEvent(task.id, artifactEvent);

    await taskManager.updateTask(
      task.copyWith(status: const TaskStatus(state: TaskState.completed)),
    );
    final completedEvent = Event.taskStatusUpdate(
      taskId: task.id,
      contextId: task.contextId,
      status: const TaskStatus(state: TaskState.completed),
      final_: true,
    );
    streamController.add(completedEvent.toJson());
    await taskManager.addEvent(task.id, completedEvent);
    await streamController.close();

    return StreamResult(streamController.stream);
  }
}

class MessageSendHandler implements RequestHandler {
  MessageSendHandler(this.taskManager);

  final TaskManager taskManager;

  @override
  String get method => 'message/send';

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final message = Message.fromJson(params);
    final task = await taskManager.createTask(message);
    return SingleResult(task.toJson());
  }
}
