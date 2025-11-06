// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/src/client/a2a_client.dart';
import 'package:a2a_dart/src/client/sse_transport.dart';
import 'package:a2a_dart/src/core/events.dart';
import 'package:a2a_dart/src/core/message.dart';
import 'package:a2a_dart/src/core/part.dart';
import 'package:a2a_dart/src/core/task.dart';
import 'package:a2a_dart/src/server/a2a_server.dart';
import 'package:a2a_dart/src/server/create_task_handler.dart';
import 'package:a2a_dart/src/server/handler_result.dart';
import 'package:a2a_dart/src/server/request_handler.dart';
import 'package:a2a_dart/src/server/task_manager.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

class MockExecuteTaskHandler implements RequestHandler {
  MockExecuteTaskHandler(this.taskManager);

  final TaskManager taskManager;

  @override
  String get method => 'execute_task';

  @override
  FutureOr<HandlerResult> handle(Map<String, dynamic> params) {
    final streamController = StreamController<Map<String, dynamic>>();
    final taskId = params['task_id'] as String;
    final task = taskManager.getTask(taskId)!;

    // Simulate work
    taskManager.updateTask(
      task.copyWith(
        status: const TaskStatus(state: TaskState.working),
      ),
    );
    streamController.add(
      TaskStatusUpdateEvent(
        taskId: taskId,
        contextId: task.contextId,
        status: const TaskStatus(state: TaskState.working),
        final_: false,
      ).toJson(),
    );

    streamController.add(
      TaskArtifactUpdateEvent(
        taskId: taskId,
        contextId: task.contextId,
        artifact: Artifact(
          artifactId: 'artifact-1',
          parts: [Part.text(text: 'Here is your artifact')],
        ),
        append: false,
        lastChunk: true,
      ).toJson(),
    );

    taskManager.updateTask(
      task.copyWith(
        status: const TaskStatus(state: TaskState.completed),
      ),
    );
    streamController.add(
      TaskStatusUpdateEvent(
        taskId: taskId,
        contextId: task.contextId,
        status: const TaskStatus(state: TaskState.completed),
        final_: true,
      ).toJson(),
    );
    streamController.close();

    return StreamResult(streamController.stream);
  }
}

void main() {
  hierarchicalLoggingEnabled = true;
  group('A2AClient and A2AServer', () {
    late A2AServer server;
    late TaskManager taskManager;

    setUp(() async {
      taskManager = TaskManager();
      server = A2AServer(
        [
          CreateTaskHandler(taskManager),
          MockExecuteTaskHandler(taskManager),
        ],
        host: 'localhost',
      );
      await server.start();
    });

    tearDown(() {
      server.stop();
    });

    test('client can create and execute a task on the server', () async {
      final client = A2AClient(
        url: 'http://localhost:${server.port}',
        transport: SseTransport(
          url: 'http://localhost:${server.port}',
          log: Logger('A2AClient'),
        ),
      );
      final message = Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );

      final task = await client.createTask(message);
      expect(task, isNotNull);
      expect(task.id, isNotEmpty);

      final stream = client.executeTask(task.id);
      final events = await stream.toList();

      expect(events, hasLength(3));
      expect(events[0], isA<TaskStatusUpdateEvent>());
      expect((events[0] as TaskStatusUpdateEvent).status.state,
          equals(TaskState.working));
      expect(events[1], isA<TaskArtifactUpdateEvent>());
      expect((events[1] as TaskArtifactUpdateEvent).artifact.artifactId,
          equals('artifact-1'));
      expect(events[2], isA<TaskStatusUpdateEvent>());
      expect((events[2] as TaskStatusUpdateEvent).status.state,
          equals(TaskState.completed));
    });

    test('client handles server errors gracefully', () async {
      final client = A2AClient(url: 'http://localhost:${server.port}');
      final message = Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );

      // Stop the server to simulate a connection error
      server.stop();

      expect(client.createTask(message), throwsException);
    });
  });
}
