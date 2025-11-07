// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final taskManager = CountdownTaskManager();
  final server = A2AServer(
    [
      CreateCountdownTaskHandler(taskManager),
      ExecuteCountdownTaskHandler(taskManager),
      MessageHandler(taskManager),
    ],
    port: 8080,
    agentCard: agentCard,
  );

  await server.start();
  print('Server started on port ${server.port}');
}

// A simple in-memory task manager.
class CountdownTaskManager {
  final Map<String, Task> _tasks = {};
  final Map<String, StreamController<Map<String, Object?>>> _controllers = {};
  final Set<String> _pausedTasks = {};

  Task createTask(Message message) {
    final taskId = const Uuid().v4();
    final task = Task(
      id: taskId,
      contextId: const Uuid().v4(),
      status: const TaskStatus(state: TaskState.submitted),
      history: [message],
    );
    _tasks[task.id] = task;
    return task;
  }

  Task? getTask(String id) => _tasks[id];

  void pauseTask(String taskId) {
    _pausedTasks.add(taskId);
    Timer(const Duration(seconds: 3), () {
      _pausedTasks.remove(taskId);
    });
  }

  bool isPaused(String taskId) => _pausedTasks.contains(taskId);

  void registerController(
    String taskId,
    StreamController<Map<String, Object?>> controller,
  ) {
    _controllers[taskId] = controller;
  }
}

class CreateCountdownTaskHandler extends RequestHandler {
  final CountdownTaskManager _taskManager;

  CreateCountdownTaskHandler(this._taskManager);

  @override
  String get method => 'create_task';

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final message = Message.fromJson(params['message'] as Map<String, dynamic>);
    final task = _taskManager.createTask(message);
    return SingleResult(task.toJson());
  }
}

class MessageHandler extends RequestHandler {
  final CountdownTaskManager _taskManager;
  final _log = Logger('MessageHandler');

  MessageHandler(this._taskManager);

  @override
  String get method => 'message';

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final message = Message.fromJson(params['message'] as Map<String, dynamic>);
    final part = message.parts.first;
    if (part is TextPart && part.text.startsWith('pause')) {
      final taskId = part.text.split(' ').last;
      final task = _taskManager.getTask(taskId);
      if (task == null) {
        throw A2AServerException('Task not found: $taskId', -32602);
      }
      _log.info('Pausing task $taskId');
      _taskManager.pauseTask(taskId);
      final event = Event.taskStatusUpdate(
        taskId: taskId,
        contextId: task.contextId,
        status: TaskStatus(
          state: TaskState.working,
          message: Message(
            messageId: const Uuid().v4(),
            role: Role.agent,
            parts: const [Part.text(text: 'Task paused for 3 seconds')],
          ),
        ),
        final_: false,
      );
      return SingleResult(event.toJson());
    }
    throw A2AServerException('Could not determine action', -32602);
  }
}

class ExecuteCountdownTaskHandler extends RequestHandler {
  final CountdownTaskManager _taskManager;
  final _log = Logger('ExecuteCountdownTaskHandler');

  ExecuteCountdownTaskHandler(this._taskManager);

  @override
  String get method => 'execute_task';

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    final taskId = params['task_id'] as String;
    final messageParam = params['message'] as Map<String, Object?>?;
    if (messageParam != null) {
      final message = Message.fromJson(messageParam);
      final part = message.parts.first;
      if (part is TextPart && part.text.startsWith('pause')) {
        _log.info('Pausing task $taskId');
        _taskManager.pauseTask(taskId);
        return SingleResult({'status': 'paused'});
      }
    }

    final task = _taskManager.getTask(taskId);
    if (task == null) {
      throw A2AServerException('Task not found: $taskId', -32602);
    }

    final part = task.history?.first.parts.first;
    if (part is TextPart) {
      final messageText = part.text;
      if (messageText.startsWith('start')) {
        return _startCountdown(task, messageText);
      }
    }

    throw A2AServerException('Could not determine action', -32602);
  }

  HandlerResult _startCountdown(Task task, String messageText) {
    final controller = StreamController<Map<String, Object?>>();
    _taskManager.registerController(task.id, controller);

    final countdownStart = int.tryParse(messageText.split(' ').last) ?? 10;
    _log.info('Starting countdown from $countdownStart for task ${task.id}');

    unawaited(() async {
      var countdown = countdownStart;
      while (countdown > 0) {
        if (controller.isClosed) {
          return;
        }
        if (!_taskManager.isPaused(task.id)) {
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

    return StreamResult(controller.stream);
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
