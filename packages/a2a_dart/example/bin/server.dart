// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:a2a_dart/src/core/push_notification.dart';
import 'package:a2a_dart/src/server/delete_push_config_handler.dart';
import 'package:a2a_dart/src/server/get_push_config_handler.dart';
import 'package:a2a_dart/src/server/list_push_configs_handler.dart';
import 'package:a2a_dart/src/server/set_push_config_handler.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// This is an example of how to write a server for the A2A protocol.
/// It demonstrates the use of the A2AServer class to create a server
/// that can handle various A2A requests.
///
/// It performs a countdown from 10 to 0, pausing if it is
/// asked to pause, and resuming when it is asked to resume.
void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final taskManager = CountdownTaskManager();
  final server = A2AServer(
    [
      MessageSendHandler(taskManager),
      MessageStreamHandler(taskManager),
      GetTaskHandler(taskManager),
      ListTasksHandler(taskManager),
      CancelTaskHandler(taskManager),
      ResubscribeHandler(taskManager),
      SetPushConfigHandler(taskManager),
      GetPushConfigHandler(taskManager),
      ListPushConfigsHandler(taskManager),
      DeletePushConfigHandler(taskManager),
    ],
    taskManager,
    port: 8080,
    agentCard: agentCard,
  );

  await server.start();
  print('Server started on port ${server.port}');
}

// A simple in-memory task manager.
class CountdownTaskManager implements TaskManager {
  final _tasks = <String, Task>{};
  final _events = <String, List<Event>>{};
  final Map<String, StreamController<Map<String, Object?>>> _controllers =
      <String, StreamController<Map<String, Object?>>>{};
  final Set<String> _pausedTasks = {};
  final _pushConfigs = <String, Map<String, PushNotificationConfig>>{};

  Stream<Map<String, Object?>> startCountdown(Task task, int countdownStart) {
    final controller = StreamController<Map<String, Object?>>.broadcast();
    _controllers[task.id] = controller;

    unawaited(() async {
      var countdown = countdownStart;
      while (countdown > 0) {
        if (controller.isClosed) {
          return;
        }
        if (!isPaused(task.id)) {
          final event = StreamingEvent.taskArtifactUpdate(
            taskId: task.id,
            contextId: task.contextId,
            artifact: Artifact(
              artifactId: const Uuid().v4(),
              parts: [
                Part.text(text: 'Countdown at $countdown! (${DateTime.now()})'),
              ],
            ),
            append: true,
            lastChunk: false,
          );
          controller.add(event.toJson());
          countdown--;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      final event = StreamingEvent.taskArtifactUpdate(
        taskId: task.id,
        contextId: task.contextId,
        artifact: Artifact(
          artifactId: const Uuid().v4(),
          parts: [const Part.text(text: 'Liftoff!')],
        ),
        append: true,
        lastChunk: true,
      );
      controller.add(event.toJson());
      await controller.close();
    }());

    return controller.stream;
  }

  @override
  Future<Task> createTask([Message? message]) async {
    final taskId = const Uuid().v4();
    final task = Task(
      id: taskId,
      contextId: const Uuid().v4(),
      status: const TaskStatus(state: TaskState.submitted),
      history: [if (message != null) message],
    );
    _tasks[task.id] = task;
    return task;
  }

  @override
  Future<Task?> getTask(String id) async => _tasks[id];

  @override
  Future<void> updateTask(Task task) async {
    _tasks[task.id] = task;
  }

  @override
  Stream<Event> resubscribeToTask(String taskId) {
    return Stream.fromIterable(_events[taskId] ?? []);
  }

  @override
  Future<void> addEvent(String taskId, Event event) async {
    _events.putIfAbsent(taskId, () => []).add(event);
  }

  @override
  Future<Task?> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      final canceledTask = task.copyWith(
        status: const TaskStatus(state: TaskState.canceled),
      );
      _tasks[taskId] = canceledTask;
      return canceledTask;
    }
    return null;
  }

  @override
  Future<ListTasksResult> listTasks(ListTasksParams params) async {
    // This is a simple implementation for the example and does not support
    // filtering or pagination.
    return ListTasksResult(
      tasks: _tasks.values.toList(),
      totalSize: _tasks.length,
      pageSize: _tasks.length,
      nextPageToken: '',
    );
  }

  void pauseTask(String taskId) {
    _pausedTasks.add(taskId);
    Timer(const Duration(seconds: 3), () {
      _pausedTasks.remove(taskId);
    });
  }

  bool isPaused(String taskId) => _pausedTasks.contains(taskId);

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

class MessageSendHandler extends RequestHandler {
  final TaskManager _taskManager;

  MessageSendHandler(this._taskManager);

  @override
  String get method => 'message/send';

  @override
  Future<HandlerResult> handle(Map<String, Object?> parameters) async {
    final message = Message.fromJson(parameters);
    final task = _taskManager.createTask(message);
    return SingleResult((await task).toJson());
  }
}

class MessageStreamHandler extends RequestHandler {
  final CountdownTaskManager _taskManager;
  final _log = Logger('MessageStreamHandler');

  MessageStreamHandler(this._taskManager);

  @override
  String get method => 'message/stream';

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final message = Message.fromJson(params);

    final Task task;
    if (message.taskId == null) {
      task = await _taskManager.createTask(message);
    } else {
      final existingTask = await _taskManager.getTask(message.taskId!);
      if (existingTask == null) {
        throw A2AServerException('Task not found: ${message.taskId!}', -32602);
      }
      task = existingTask;
    }

    final part = message.parts.first;
    if (part is TextPart) {
      final messageText = part.text;
      if (messageText.startsWith('start')) {
        return _startCountdown(task, messageText);
      } else if (messageText == 'pause') {
        _taskManager.pauseTask(task.id);
        return SingleResult({});
      }
    }

    throw A2AServerException('Could not determine action for stream', -32602);
  }

  HandlerResult _startCountdown(Task task, String messageText) {
    final countdownStart = int.tryParse(messageText.split(' ').last) ?? 10;
    _log.info('Starting countdown from $countdownStart for task ${task.id}');
    final stream = _taskManager.startCountdown(task, countdownStart);
    return StreamResult(stream);
  }
}

final agentCard = const AgentCard(
  protocolVersion: '0.1.0',
  name: 'Countdown Agent',
  description: 'An agent that counts down.',
  url: 'http://localhost:8080',
  version: '0.1.0',
  capabilities: AgentCapabilities(streaming: true),
  defaultInputModes: ['text/plain'],
  defaultOutputModes: ['text/plain'],
  skills: [],
);
