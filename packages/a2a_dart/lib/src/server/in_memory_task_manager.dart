// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:uuid/uuid.dart';

import '../core/events.dart';
import '../core/list_tasks_params.dart';
import '../core/list_tasks_result.dart';
import '../core/message.dart';
import '../core/push_notification.dart';
import '../core/task.dart';
import 'task_manager.dart';

/// An in-memory implementation of the [TaskManager] interface.
///
/// This class stores all task data, events, and push configurations in memory.
/// It is suitable for testing, development, or simple server deployments where
/// persistence is not required.
class InMemoryTaskManager implements TaskManager {
  final _tasks = <String, Task>{};
  final _events = <String, List<Event>>{};
  final _uuid = const Uuid();
  final _pushConfigs = <String, Map<String, PushNotificationConfig>>{};

  @override
  Future<Task> createTask([Message? message]) async {
    final taskId = _uuid.v4();
    final contextId = message?.contextId ?? _uuid.v4();
    final task = Task(
      id: taskId,
      contextId: contextId,
      history: [if (message != null) message],
      status: const TaskStatus(state: TaskState.submitted),
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    _tasks[taskId] = task;
    return task;
  }

  @override
  Future<Task?> getTask(String id) async => _tasks[id];

  @override
  Future<void> updateTask(Task task) async {
    if (!_tasks.containsKey(task.id)) {
      throw StateError('Task not found: ${task.id}');
    }
    _tasks[task.id] = task.copyWith(
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<Task?> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      final canceledTask = task.copyWith(
        status: const TaskStatus(state: TaskState.canceled),
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
      _tasks[taskId] = canceledTask;
      return canceledTask;
    }
    return null;
  }

  @override
  Future<ListTasksResult> listTasks(ListTasksParams params) async {
    var tasks = _tasks.values.toList();

    if (params.contextId != null) {
      tasks = tasks.where((t) => t.contextId == params.contextId).toList();
    }
    if (params.status != null) {
      tasks = tasks.where((t) => t.status.state == params.status).toList();
    }
    if (params.lastUpdatedAfter != null) {
      tasks = tasks
          .where(
            (t) =>
                t.lastUpdated != null &&
                t.lastUpdated! >= params.lastUpdatedAfter!,
          )
          .toList();
    }

    tasks.sort((a, b) => b.lastUpdated!.compareTo(a.lastUpdated!));

    final totalSize = tasks.length;
    final pageToken = params.pageToken != null && params.pageToken!.isNotEmpty
        ? int.parse(params.pageToken!)
        : 0;
    final startIndex = pageToken * params.pageSize;

    if (startIndex >= totalSize) {
      return ListTasksResult(
        tasks: [],
        totalSize: totalSize,
        pageSize: params.pageSize,
        nextPageToken: '',
      );
    }

    final endIndex = (startIndex + params.pageSize > totalSize)
        ? totalSize
        : startIndex + params.pageSize;

    final paginatedTasks = tasks.sublist(startIndex, endIndex);

    final nextPageToken = endIndex < totalSize
        ? (pageToken + 1).toString()
        : '';

    return ListTasksResult(
      tasks: paginatedTasks,
      totalSize: totalSize,
      pageSize: params.pageSize,
      nextPageToken: nextPageToken,
    );
  }

  @override
  Stream<Event> resubscribeToTask(String taskId) {
    if (!_tasks.containsKey(taskId)) {
      return Stream.error(StateError('Task not found: $taskId'));
    }
    return Stream.fromIterable(_events[taskId] ?? []);
  }

  @override
  Future<void> addEvent(String taskId, Event event) async {
    if (!_tasks.containsKey(taskId)) {
      throw StateError('Task not found: $taskId');
    }
    _events.putIfAbsent(taskId, () => []).add(event);
  }

  @override
  Future<void> setPushNotificationConfig(
    String taskId,
    PushNotificationConfig config,
  ) async {
    if (!_tasks.containsKey(taskId)) {
      throw StateError('Task not found: $taskId');
    }
    final configId = config.id ?? _uuid.v4();
    final newConfig = config.id == null
        ? config.copyWith(id: configId)
        : config;
    _pushConfigs.putIfAbsent(taskId, () => {})[configId] = newConfig;
  }

  @override
  Future<PushNotificationConfig?> getPushNotificationConfig(
    String taskId,
    String configId,
  ) async {
    return _pushConfigs[taskId]?[configId];
  }

  @override
  Future<List<PushNotificationConfig>> listPushNotificationConfigs(
    String taskId,
  ) async {
    if (!_tasks.containsKey(taskId)) {
      return [];
    }
    return _pushConfigs[taskId]?.values.toList() ?? [];
  }

  @override
  Future<void> deletePushNotificationConfig(
    String taskId,
    String configId,
  ) async {
    if (!_tasks.containsKey(taskId)) {
      throw StateError('Task not found: $taskId');
    }
    if (_pushConfigs[taskId]?.remove(configId) == null) {
      throw StateError('Push config not found: $configId');
    }
  }
}
