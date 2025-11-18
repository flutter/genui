// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart' hide A2AServer;
import 'package:a2a_dart/src/core/push_notification.dart';
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
        taskManager,
        host: 'localhost',
        agentCard: agentCard,
      )..extendedAgentCard = agentCard.copyWith(name: 'Extended Test Agent');
      await server.start();
    });

    tearDown(() async {
      await server.stop();
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
        parts: const [TextPart(text: 'Hello')],
      );
      final stream = client.messageStream(message);
      final events = <Event>[];
      await for (final event in stream) {
        switch (event) {
          case TaskStatusUpdate():
            events.add(event);
          case TaskArtifactUpdate():
            events.add(event);
        }
      }
      expect(events, isNotEmpty);
      final taskId = (events.first as TaskStatusUpdate).taskId;
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
      expect(events[0].kind, equals('task_status_update'));
      expect(
        (events[0] as TaskStatusUpdate).status.state,
        equals(TaskState.working),
      );
      expect(events[1].kind, equals('task_artifact_update'));
      expect(
        (events[1] as TaskArtifactUpdate).artifact.artifactId,
        equals('artifact-1'),
      );
      expect(
        (events[1] as TaskArtifactUpdate).artifact.parts[0],
        const Part.text(text: 'Here is your artifact'),
      );
      expect(events[2].kind, equals('task_status_update'));
      expect(
        (events[2] as TaskStatusUpdate).status.state,
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

    group('Push Notification Config', () {
      final configId = 'test-push-config';
      final pushConfig = PushNotificationConfig(
        id: configId,
        url: 'https://example.com/push',
      );

      test(
        'client can set, get, list, and delete push notification configs',
        () async {
          final client = A2AClient(url: 'http://localhost:${server.port}');
          final message = Message(
            messageId: const Uuid().v4(),
            role: Role.user,
            parts: const [],
          );
          final task = await client.messageSend(message);
          final taskId = task.id;

          // Set
          final taskPushConfig = TaskPushNotificationConfig(
            taskId: taskId,
            pushNotificationConfig: pushConfig,
          );
          final setResult = await client.setPushNotificationConfig(
            taskPushConfig,
          );
          expect(setResult.taskId, taskId);
          expect(setResult.pushNotificationConfig, pushConfig);

          // Get
          final getResult = await client.getPushNotificationConfig(
            taskId,
            configId,
          );
          expect(getResult.taskId, taskId);
          expect(getResult.pushNotificationConfig, pushConfig);

          // List
          final listResult = await client.listPushNotificationConfigs(taskId);
          expect(listResult, hasLength(1));
          expect(listResult[0], pushConfig);

          // Delete
          await client.deletePushNotificationConfig(taskId, configId);

          // Verify Deletion by Getting
          expect(
            () => client.getPushNotificationConfig(taskId, configId),
            throwsA(isA<A2AException>()),
          );

          // Verify Deletion by Listing
          final listAfterDelete = await client.listPushNotificationConfigs(
            taskId,
          );
          expect(listAfterDelete, isEmpty);
        },
      );
    });
  });
}

class InMemoryTaskManager implements TaskManager {
  final Map<String, Task> _tasks = {};
  final Map<String, List<Event>> _events = {};
  final Map<String, Map<String, PushNotificationConfig>> _pushConfigs = {};

  @override
  Future<Task> createTask([Message? message]) async {
    final task = Task(
      id: const Uuid().v4(),
      contextId: const Uuid().v4(),
      status: const TaskStatus(state: TaskState.submitted),
    );
    _tasks[task.id] = task;
    _events[task.id] = [];
    return task;
  }

  @override
  Future<Task> getTask(String id) async {
    if (_tasks.containsKey(id)) {
      return _tasks[id]!;
    }
    throw A2AServerException('Task not found', -32602);
  }

  @override
  Future<ListTasksResult> listTasks(ListTasksParams params) async {
    return ListTasksResult(
      tasks: _tasks.values.toList(),
      totalSize: _tasks.length,
      pageSize: _tasks.length,
      nextPageToken: '',
    );
  }

  @override
  Future<Task> updateTask(Task task) async {
    if (_tasks.containsKey(task.id)) {
      _tasks[task.id] = task;
      return task;
    }
    throw A2AServerException('Task not found', -32602);
  }

  @override
  Future<void> addEvent(String taskId, Event event) async {
    if (_events.containsKey(taskId)) {
      _events[taskId]!.add(event);
    } else {
      throw A2AServerException('Task not found', -32602);
    }
  }

  @override
  Stream<Event> resubscribeToTask(String taskId) {
    if (_events.containsKey(taskId)) {
      return Stream.fromIterable(_events[taskId]!);
    }
    throw A2AServerException('Task not found', -32602);
  }

  @override
  Future<Task> cancelTask(String id) async {
    if (_tasks.containsKey(id)) {
      final task = _tasks[id]!;
      final canceledTask = task.copyWith(
        status: const TaskStatus(state: TaskState.canceled),
      );
      _tasks[id] = canceledTask;
      return canceledTask;
    }
    throw A2AServerException('Task not found', -32602);
  }

  @override
  Future<void> setPushNotificationConfig(
    String taskId,
    PushNotificationConfig config,
  ) async {
    if (!_tasks.containsKey(taskId)) {
      throw A2AServerException('Task not found', -32001);
    }
    _pushConfigs.putIfAbsent(taskId, () => {});
    _pushConfigs[taskId]![config.id!] = config;
  }

  @override
  Future<PushNotificationConfig?> getPushNotificationConfig(
    String taskId,
    String configId,
  ) async {
    if (!_tasks.containsKey(taskId)) {
      throw A2AServerException('Task not found', -32001);
    }
    return _pushConfigs[taskId]?[configId];
  }

  @override
  Future<List<PushNotificationConfig>> listPushNotificationConfigs(
    String taskId,
  ) async {
    if (!_tasks.containsKey(taskId)) {
      throw A2AServerException('Task not found', -32001);
    }
    return _pushConfigs[taskId]?.values.toList() ?? [];
  }

  @override
  Future<void> deletePushNotificationConfig(
    String taskId,
    String configId,
  ) async {
    if (!_tasks.containsKey(taskId)) {
      throw A2AServerException('Task not found', -32001);
    }
    _pushConfigs[taskId]?.remove(configId);
  }
}

class MessageStreamHandler implements RequestHandler {
  MessageStreamHandler(this.taskManager);

  final TaskManager taskManager;

  @override
  String get method => 'message/stream';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

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
    unawaited(Future<void>.delayed(Duration.zero, streamController.close));

    return StreamResult(streamController.stream);
  }
}

class MessageSendHandler implements RequestHandler {
  MessageSendHandler(this.taskManager);

  final TaskManager taskManager;

  @override
  String get method => 'message/send';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    final message = Message.fromJson(params);
    final task = await taskManager.createTask(message);
    return SingleResult(task.toJson());
  }
}
